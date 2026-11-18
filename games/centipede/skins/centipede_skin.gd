class_name CentipedeSkin
extends SkinBase
## Base of the Centipede visual styles: (original) pixel drawings, sounds and explosions.

const S := CentipedeGame.SCALE
const C := CentipedeGame.CELL

const MUSHROOM := [
	"..CCCC..",
	".CCWCCC.",
	"CCCCCWCC",
	"CWCCCCCC",
	"..SSSS..",
	"..SSSS..",
	"..SSSS..",
	".SSSSSS.",
]
const BODY := [
	["........", ".BBBBBB.", "BBBBBBBB", "BBDBBDBB", "BBBBBBBB", ".BBBBBB.", "L.L..L.L", "........"],
	["........", ".BBBBBB.", "BBBBBBBB", "BBDBBDBB", "BBBBBBBB", ".BBBBBB.", ".L.LL.L.", "........"],
]
const HEAD := [
	[".A....A.", ".BBBBBB.", "BBBBBBBB", "BEBBBBEB", "BBBBBBBB", ".BBBBBB.", "L.L..L.L", "........"],
	["A......A", ".BBBBBB.", "BBBBBBBB", "BEBBBBEB", "BBBBBBBB", ".BBBBBB.", ".L.LL.L.", "........"],
]
const SHOOTER := ["...W...", "...W...", "..WWW..", ".WRRRW.", "WRRRRRW", "WRRRRRW", ".W.W.W.", "W.....W"]
const SPIDER := [
	[".L...........L.", "L.L..BBBBB..L.L", "...LBBEBEBBL...", "..LLBBBBBBBLL..", ".L..BBBBBBB..L.", "L....BBBBB....L", "...L.......L...", "..L.........L.."],
	["L.............L", ".L...BBBBB...L.", "..L.BBEBEBB.L..", ".LLLBBBBBBBLLL.", "L...BBBBBBB...L", ".....BBBBB.....", "..L.........L..", ".L...........L."],
]
const FLEA := ["..BBBB..", ".BBBBBB.", "BBEBBEBB", ".BBBBBB.", "..BBBB..", ".L.LL.L.", "L..LL..L", "........"]
const SCORPION := [
	"............TT..",
	"...........T..T.",
	"..........T.....",
	".PP.BBBBBBT.....",
	"PP.BBBBBBBB.....",
	".PPBEBBBBBB.....",
	"...L.L.L.L......",
	"..L.L.L.L.......",
]

var game: CentipedeGame
var booms: Array[Dictionary] = []      # {pos (units), life, color}
var popups: Array[Dictionary] = []     # {pos (units), text, life}
var _spider_loop: AudioStreamPlayer
var _beat_t := 0.0
var _beat_note := 0
var time := 0.0


func attach(g: CentipedeGame) -> void:
	game = g
	add_voices(10)
	_spider_loop = AudioStreamPlayer.new()
	add_child(_spider_loop)
	g.match_started.connect(_on_match_started)
	g.turn_started.connect(_on_turn_started)
	g.fired.connect(_on_fired)
	g.segment_killed.connect(_on_segment_killed)
	g.mushroom_hit.connect(_on_mushroom_hit)
	g.creature_spawned.connect(_on_creature_spawned)
	g.creature_killed.connect(_on_creature_killed)
	g.creature_gone.connect(_on_creature_gone)
	g.player_hit.connect(_on_player_hit)
	g.mushroom_repaired.connect(_on_mushroom_repaired)
	g.extra_life.connect(_on_extra_life)
	g.wave_cleared.connect(_on_wave_cleared)
	g.game_over.connect(_on_game_over)
	load_sfx()
	_setup()


## The menu demo is silent.
func _is_silent() -> bool:
	return game == null or game.mode == CentipedeGame.Mode.DEMO


func _process(delta: float) -> void:
	if game == null:
		return
	var silent := game.paused or game.mode == CentipedeGame.Mode.DEMO
	var want_spider := game.spider != null and not silent and sfx.has("spider")
	if want_spider and not _spider_loop.playing:
		var s: AudioStreamWAV = sfx.spider
		if s.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			s.loop_end = s.data.size() / 2
		_spider_loop.stream = s
		_spider_loop.volume_db = -6.0
		_spider_loop.play()
	elif not want_spider and _spider_loop.playing:
		_spider_loop.stop()
	if not game.paused:
		time += delta
		# centipede footsteps: a rhythm that speeds up with its speed
		if game.state == CentipedeGame.State.PLAY and not game.segments.is_empty():
			_beat_t -= delta
			if _beat_t <= 0.0:
				_beat_t = 8.0 / game._seg_speed * 2.0
				_beat_note = (_beat_note + 1) % 4
				play("step%d" % _beat_note, 1.0, -6.0)
		for b in booms:
			b.life -= delta
		booms = booms.filter(func(b: Dictionary) -> bool: return b.life > 0.0)
		for p in popups:
			p.life -= delta
			p.pos.y -= 10.0 * delta
		popups = popups.filter(func(p: Dictionary) -> bool: return p.life > 0.0)
		_tick(delta)
	queue_redraw()


# ---------------------------------------------------------------- helpers

func px(u: Vector2) -> Vector2:
	return game.to_px(u)


func field_rect() -> Rect2:
	return Rect2(CentipedeGame.ORIGIN, Vector2(CentipedeGame.W, CentipedeGame.H) * S)


func panel_left_x() -> float:
	return CentipedeGame.ORIGIN.x / 2


func panel_right_x() -> float:
	var r := CentipedeGame.ORIGIN.x + CentipedeGame.W * S
	return r + (1280.0 - r) / 2


## Visible rows of a mushroom by its health (it shrinks from the bottom up).
static func mushroom_rows(hp: int) -> Array:
	return MUSHROOM.slice(0, [0, 3, 5, 6, 8][hp])


func frame() -> int:
	return int(time * 8.0) % 2


func player_dying() -> bool:
	return game.state == CentipedeGame.State.DYING


# ---------------------------------------------------------------- for the styles to override

func _setup() -> void:
	pass


func _tick(_delta: float) -> void:
	pass


func _on_match_started() -> void:
	booms.clear()
	popups.clear()


func _on_turn_started(_player: int) -> void:
	pass


func _on_fired(_pos: Vector2) -> void:
	play("fire", 1.0, -4.0)


func _on_segment_killed(pos: Vector2, head: bool, _points: int) -> void:
	booms.append({"pos": pos, "life": 0.25, "head": head})
	play("kill_head" if head else "kill", randf_range(0.95, 1.05))


func _on_mushroom_hit(_cell: Vector2i, destroyed: bool) -> void:
	if destroyed:
		play("mushroom", 1.0, -4.0)


func _on_creature_spawned(_kind: String) -> void:
	pass


func _on_creature_killed(kind: String, pos: Vector2, points: int) -> void:
	booms.append({"pos": pos, "life": 0.4, "head": true})
	popups.append({"pos": pos, "text": str(points), "life": 1.2})
	play("creature")


func _on_creature_gone(_kind: String) -> void:
	pass


func _on_player_hit(_pos: Vector2) -> void:
	play("death")


func _on_mushroom_repaired(_cell: Vector2i) -> void:
	play("repair", 1.0, -6.0)


func _on_extra_life() -> void:
	play("extra")


func _on_wave_cleared() -> void:
	play("wave")


func _on_game_over() -> void:
	pass

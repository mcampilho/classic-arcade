class_name FireflySkin
extends SkinBase
## Base of the Firefly visual styles: maze drawing, characters and sounds
## (with 2 continuous sounds: night ambience and "dazzle").

const T := FireflyGame.TILE

var game: FireflyGame
var popups: Array[Dictionary] = []          # {pos (px), text, life}
var wall_edges: Array[PackedVector2Array] = []   # wall outlines (px), computed once
var _ambient: AudioStreamPlayer
var _ambient_id := ""
var _eat_note := 0
var time := 0.0


func attach(g: FireflyGame) -> void:
	game = g
	add_voices(8)
	_ambient = AudioStreamPlayer.new()
	add_child(_ambient)
	g.match_started.connect(_on_match_started)
	g.turn_started.connect(_on_turn_started)
	g.pellet_eaten.connect(_on_pellet_eaten)
	g.bat_eaten.connect(_on_bat_eaten)
	g.power_started.connect(_on_power_started)
	g.bonus_spawned.connect(_on_bonus_spawned)
	g.bonus_eaten.connect(_on_bonus_eaten)
	g.player_hit.connect(_on_player_hit)
	g.extra_life.connect(_on_extra_life)
	g.level_cleared.connect(_on_level_cleared)
	g.game_over.connect(_on_game_over)
	load_sfx()
	_compute_edges()
	_setup()


## The menu demo is silent.
func _is_silent() -> bool:
	return game == null or game.mode == FireflyGame.Mode.DEMO


func _update_ambient() -> void:
	var id := ""
	if not game.paused and game.mode != FireflyGame.Mode.DEMO and game.state == FireflyGame.State.PLAY:
		id = "power_loop" if game.fright_time > 0.0 else "ambient"
	if id == _ambient_id:
		return
	_ambient_id = id
	if id == "" or not sfx.has(id):
		_ambient.stop()
		return
	var s: AudioStreamWAV = sfx[id]
	if s.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_end = s.data.size() / 2
	_ambient.stream = s
	_ambient.volume_db = -4.0
	_ambient.play()


func _process(delta: float) -> void:
	if game == null:
		return
	_update_ambient()
	if not game.paused:
		time += delta
		for p in popups:
			p.life -= delta
			p.pos.y -= 18.0 * delta
		popups = popups.filter(func(p: Dictionary) -> bool: return p.life > 0.0)
		_tick(delta)
	queue_redraw()


# ---------------------------------------------------------------- helpers

func px(tile_pos: Vector2) -> Vector2:
	return game.to_px(tile_pos)


func tile_rect(t: Vector2i) -> Rect2:
	return Rect2(FireflyGame.ORIGIN + Vector2(t) * T, Vector2(T, T))


func maze_rect() -> Rect2:
	return Rect2(FireflyGame.ORIGIN, Vector2(FireflyGame.W, FireflyGame.H) * T)


## Outline segments: wall edges facing a corridor (or the cave).
func _compute_edges() -> void:
	wall_edges.clear()
	for y in FireflyGame.H:
		for x in FireflyGame.W:
			var t := Vector2i(x, y)
			if not FireflyGame.is_wall(t):
				continue
			var r := tile_rect(t)
			var sides := [
				[Vector2i.UP, r.position, Vector2(r.end.x, r.position.y)],
				[Vector2i.DOWN, Vector2(r.position.x, r.end.y), r.end],
				[Vector2i.LEFT, r.position, Vector2(r.position.x, r.end.y)],
				[Vector2i.RIGHT, Vector2(r.end.x, r.position.y), r.end],
			]
			for s in sides:
				var n: Vector2i = t + s[0]
				if n.x < 0 or n.x >= FireflyGame.W or n.y < 0 or n.y >= FireflyGame.H:
					continue
				if not FireflyGame.is_wall(n):
					wall_edges.append(PackedVector2Array([s[1], s[2]]))


func pellet_at(x: int, y: int) -> int:
	return game.pellets[y * FireflyGame.W + x]


## Angle and mirroring to draw the firefly facing the way it moves.
func face_transform() -> Array:
	var f := game.player_face
	if f == Vector2i.LEFT:
		return [0.0, Vector2(-1, 1)]
	if f == Vector2i.UP:
		return [-PI / 2, Vector2.ONE]
	if f == Vector2i.DOWN:
		return [PI / 2, Vector2.ONE]
	return [0.0, Vector2.ONE]


func bat_visible(b: Dictionary) -> bool:
	return game.state != FireflyGame.State.DYING or game.timer > 1.4


func fright_flash() -> bool:
	return game.fright_time > 0.0 and game.fright_time < 2.0 and fmod(game.fright_time, 0.4) < 0.2


func player_visible() -> bool:
	return game.state != FireflyGame.State.OVER


# ---------------------------------------------------------------- for the styles to override

func _setup() -> void:
	pass


func _tick(_delta: float) -> void:
	pass


func _on_match_started() -> void:
	popups.clear()


func _on_turn_started(_player: int) -> void:
	pass


func _on_pellet_eaten(_tile: Vector2i, power: bool) -> void:
	if power:
		play("power")
	else:
		_eat_note = (_eat_note + 1) % 5
		play("eat%d" % _eat_note, 1.0, -3.0)


func _on_bat_eaten(pos: Vector2, points: int) -> void:
	play("bat_eaten")
	popups.append({"pos": pos, "text": str(points), "life": 1.0})


func _on_power_started() -> void:
	pass


func _on_bonus_spawned() -> void:
	pass


func _on_bonus_eaten(pos: Vector2, points: int) -> void:
	play("bonus")
	popups.append({"pos": pos, "text": str(points), "life": 1.4})


func _on_player_hit(_pos: Vector2) -> void:
	_ambient.stop()
	_ambient_id = ""
	play("death")


func _on_extra_life() -> void:
	play("extra")


func _on_level_cleared() -> void:
	play("clear")


func _on_game_over() -> void:
	pass

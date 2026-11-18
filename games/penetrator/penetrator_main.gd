extends GameShell
## Penetrator: menu (with the demo behind it), zone messages, pause, game over and style switching.

const SKINS := [
	{"name": "Classic 1982", "script": preload("res://games/penetrator/skins/classic_skin.gd")},
	{"name": "Neon", "script": preload("res://games/penetrator/skins/neon_skin.gd")},
	{"name": "Topographic Map", "script": preload("res://games/penetrator/skins/topo_skin.gd")},
]
const LIVES := [5, 3]


func _init() -> void:
	id = "penetrator"
	skins = SKINS
	title = "INCURSION"
	tagline = "ship in the caverns, 1982 style"
	hint = "Move: arrows / WASD / gamepad   ·   Fire: Space, Z or A   ·   Bomb: X, B or Ctrl\nTouch: drag on the left half to move the ship · right side top fires, bottom drops bombs"
	prompt_offset = -40.0
	pause_pos = Vector2(1200, 80)


func _create_game() -> Node:
	var g := PenetratorGame.new()
	g.game_over.connect(_on_game_over)
	g.zone_started.connect(func(z: int) -> void: say(I18n.t("ZONE %d  ·  %s") % [z + 1, I18n.t(PenetratorGame.ZONE_NAMES[z]).to_upper()], 2.0))
	g.mission_complete.connect(func(m: int) -> void: say(I18n.t("DEPOT DESTROYED!  MISSION %d COMPLETE") % m, 3.5))
	return g


func _build_options(box: VBoxContainer) -> void:
	add_option(box, "Lives", LIVES, "lives")


func _start_demo() -> void:
	game.start(PenetratorGame.Mode.DEMO, 3)


func _start_play() -> void:
	game.start(PenetratorGame.Mode.PLAY, LIVES[option("lives")])


func _status_text() -> String:
	if game.zone == PenetratorGame.ZONES - 1 and game.zone_progress() > 0.8 and game.state == PenetratorGame.State.PLAY:
		return I18n.t("BOMB THE DEPOT!")
	return ""


func _on_game_over() -> void:
	show_result(I18n.t("GAME OVER"), I18n.t("%d points  ·  mission %d, zone %d") % [game.score, game.mission, game.zone + 1], game.score)

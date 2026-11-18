extends GameShell
## Jetpac: menu (with the demo behind it), level messages, pause, game over and style switching.

const SKINS := [
	{"name": "Classic 1983", "script": preload("res://games/jetpac/skins/classic_skin.gd")},
	{"name": "Neon", "script": preload("res://games/jetpac/skins/neon_skin.gd")},
	{"name": "Comic Book", "script": preload("res://games/jetpac/skins/comic_skin.gd")},
]
const LIVES := [4, 6]


func _init() -> void:
	id = "jetpac"
	skins = SKINS
	title = "JET ASTRONAUT"
	title_size = 64
	tagline = "build and fuel the rocket, 1983 style"
	hint = "Move/fly: arrows / WASD / gamepad (up = thrust)   ·   Laser: Space, Z or A\nTouch: joystick on left half (push up to fly) · tap right half to fire"
	prompt_offset = -40.0
	pause_pos = Vector2(1200, 640)


func _create_game() -> Node:
	var g := JetpacGame.new()
	g.game_over.connect(_on_game_over)
	g.level_started.connect(func(l: int) -> void: say(I18n.t("PLANET %d") % l, 1.8))
	g.takeoff.connect(func() -> void: say(I18n.t("LIFT-OFF!"), 2.2))
	return g


func _build_options(box: VBoxContainer) -> void:
	add_option(box, "Lives", LIVES, "lives")


func _start_demo() -> void:
	game.start(JetpacGame.Mode.DEMO, 3)


func _start_play() -> void:
	game.start(JetpacGame.Mode.PLAY, LIVES[option("lives")])


func _status_text() -> String:
	if game.rocket_ready() and game.state == JetpacGame.State.PLAY:
		return I18n.t("ROCKET READY: GET IN!")
	return ""


func _on_game_over() -> void:
	show_result(I18n.t("GAME OVER"), I18n.t("%d points  ·  planet %d") % [game.score, game.level], game.score)

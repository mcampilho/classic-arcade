extends GameShell
## Tower of Relics: menu (with the demo behind it), messages, pause, game over and style switching.

const SKINS := [
	{"name": "Classic 1984", "script": preload("res://games/relics/skins/classic_skin.gd")},
	{"name": "Neon", "script": preload("res://games/relics/skins/neon_skin.gd")},
	{"name": "Geometric Pastel", "script": preload("res://games/relics/skins/pastel_skin.gd")},
]
const LIVES := [5, 3]


func _init() -> void:
	id = "relics"
	skins = SKINS
	title = "TOWER OF RELICS"
	title_size = 64
	tagline = "isometric adventure, 1984 style"
	hint = "Walk: arrows / WASD / gamepad   ·   Jump: Space or A   ·   Pick up/drop crate: E, X or B\nTip: drop the crate mid-jump to land on top of it   ·   Touch: joystick on the left, right side top jumps, bottom picks up/drops"
	prompt_offset = 230.0
	pause_pos = Vector2(1200, 20)


func _create_game() -> Node:
	var g := RelicsGame.new()
	g.game_over.connect(_on_game_over)
	g.won.connect(func() -> void: get_tree().create_timer(4.0).timeout.connect(_on_game_over))
	g.relic_taken.connect(func(_p: Vector3) -> void: say(I18n.t("RELIC! TAKE IT TO THE ALTAR"), 2.0))
	g.relics_deposited.connect(func(c: int, t: int) -> void: say(I18n.t("%d OF %d RELICS ON THE ALTAR") % [c, t], 2.5))
	g.day_changed.connect(func(d: int) -> void: say(I18n.t("DAY %d") % d, 1.5))
	g.won.connect(func() -> void: say(I18n.t("THE TOWER IS SAVED!"), 6.0))
	return g


func _build_options(box: VBoxContainer) -> void:
	add_option(box, "Lives", LIVES, "lives")


func _start_demo() -> void:
	game.start(RelicsGame.Mode.DEMO, 3)


func _start_play() -> void:
	game.start(RelicsGame.Mode.PLAY, LIVES[option("lives")])


func _status_text() -> String:
	if game.state == RelicsGame.State.READY and game.room == RelicsGame.START_ROOM and game.deposited == 0 and game.carried_relics == 0:
		return I18n.t("COLLECT THE 8 RELICS AND TAKE THEM TO THE ALTAR")
	return ""


func _on_game_over() -> void:
	var t := I18n.t("THE TOWER IS SAVED!") if game.deposited >= RelicsGame.RELICS else I18n.t("GAME OVER")
	show_result(t, I18n.t("%d points  ·  %d of %d relics  ·  day %d") % [game.score, game.deposited, RelicsGame.RELICS, game.day()], game.score)

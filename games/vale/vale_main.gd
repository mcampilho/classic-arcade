extends GameShell
## Sword of the Valley: menu (with the demo behind it), messages, pause, game over and style switching.

const SKINS := [
	{"name": "Classic 1986", "script": preload("res://games/vale/skins/classic_skin.gd")},
	{"name": "Handheld Console", "script": preload("res://games/vale/skins/gameboy_skin.gd")},
	{"name": "Watercolour", "script": preload("res://games/vale/skins/watercolor_skin.gd")},
]
const LIVES := [5, 3]


func _init() -> void:
	id = "vale"
	skins = SKINS
	title = "SWORD OF THE VALLEY"
	title_size = 70
	tagline = "sword adventure, 1986 style"
	hint = "Walk: arrows / WASD / gamepad   ·   Sword: Space, Z, X or A\nTouch: joystick on the left half · tap the right half to strike"
	prompt_offset = 250.0
	pause_pos = Vector2(1200, 20)


func _create_game() -> Node:
	var g := ValeGame.new()
	g.game_over.connect(_on_game_over)
	g.won.connect(func() -> void: get_tree().create_timer(4.0).timeout.connect(_on_game_over))
	g.picked.connect(func(k: String, _p: Vector2) -> void:
		if k == "container":
			say(I18n.t("EXTRA HEART!"), 2.0)
		elif k == "key":
			say(I18n.t("A KEY!"), 1.5))
	g.key_appeared.connect(func(_p: Vector2) -> void: say(I18n.t("SOMETHING APPEARED..."), 1.5))
	g.room_changed.connect(func(d: bool, r: Vector2i, dir: Vector2i) -> void:
		if dir == Vector2i.ZERO and game.state != ValeGame.State.OVER:
			say(I18n.t("THE GUARDIAN'S DUNGEON") if d else (I18n.t("THE VALLEY") if r == ValeGame.START_ROOM else ""), 1.8))
	g.won.connect(func() -> void: say(I18n.t("THE VALLEY CRYSTAL IS YOURS!"), 6.0))
	return g


func _build_options(box: VBoxContainer) -> void:
	add_option(box, "Lives", LIVES, "lives")


func _start_demo() -> void:
	game.start(ValeGame.Mode.DEMO, 3)


func _start_play() -> void:
	game.start(ValeGame.Mode.PLAY, LIVES[option("lives")])


func _status_text() -> String:
	if game.state == ValeGame.State.READY and game.room == ValeGame.START_ROOM and not game.in_dungeon and game.score == 0:
		return I18n.t("FIND THE GUARDIAN'S CAVE AND RECOVER THE CRYSTAL")
	return ""


func _on_game_over() -> void:
	var t := I18n.t("THE VALLEY IS SAVED!") if game.crystal else I18n.t("GAME OVER")
	show_result(t, I18n.t("%d points  ·  %d coins") % [game.score, game.coins], game.score)

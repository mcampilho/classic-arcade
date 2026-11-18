extends GameShell
## Palace Escape: menu (with the demo behind it), messages, pause, game over and style switching.

const SKINS := [
	{"name": "Classic 1989", "script": preload("res://games/palace/skins/classic_skin.gd")},
	{"name": "Silhouette", "script": preload("res://games/palace/skins/silhouette_skin.gd")},
	{"name": "Persian Miniature", "script": preload("res://games/palace/skins/miniature_skin.gd")},
]
const LIVES := [5, 3]


func _init() -> void:
	id = "palace"
	skins = SKINS
	title = "PALACE ESCAPE"
	title_size = 70
	tagline = "cinematic platformer, 1989 style"
	hint = "Run: ← →   ·   Careful step: Shift + ← →   ·   Jump: Space (running = long jump)   ·   ↑ grab/climb · ↓ drop/crouch\nSword: X or J (↑ blocks)   ·   Touch: joystick on left; on right: top jumps, middle careful step, bottom sword"
	prompt_offset = -240.0
	pause_pos = Vector2(1200, 652)


func _create_game() -> Node:
	var g := PalaceGame.new()
	g.game_over.connect(_on_game_over)
	g.won.connect(func() -> void: get_tree().create_timer(4.0).timeout.connect(_on_game_over))
	g.picked.connect(func(k: String) -> void:
		if k == "sword":
			say(I18n.t("A SWORD!"), 2.0)
		elif k == "life":
			say(I18n.t("MORE LIFE!"), 2.0))
	g.gate_opened.connect(func() -> void: say(I18n.t("A GATE HAS OPENED..."), 1.6))
	g.exit_opened.connect(func() -> void: say(I18n.t("THE EXIT DOOR IS OPEN!"), 2.2))
	g.level_started.connect(func(l: int) -> void: say(I18n.t("LEVEL %d") % (l + 1), 1.8))
	g.won.connect(func() -> void: say(I18n.t("FREE!"), 6.0))
	return g


func _build_options(box: VBoxContainer) -> void:
	add_option(box, "Lives", LIVES, "lives")


func _start_demo() -> void:
	game.start(PalaceGame.Mode.DEMO, 3)


func _start_play() -> void:
	game.start(PalaceGame.Mode.PLAY, LIVES[option("lives")])


func _status_text() -> String:
	if game.state == PalaceGame.State.READY and game.level == 0 and game.clock < 1.0:
		return I18n.t("ESCAPE THE PALACE IN 20 MINUTES")
	return ""


func _on_game_over() -> void:
	var t := I18n.t("FREE!") if game.state == PalaceGame.State.WON else I18n.t("GAME OVER")
	show_result(t, I18n.t("%d points  ·  level %d  ·  %d minutes left") % [game.score, game.level + 1, maxi(game.minutes_left(), 0)], game.score)

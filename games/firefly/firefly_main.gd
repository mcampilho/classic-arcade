extends GameShell
## Firefly (Pac-Man): menu (with the demo behind it), game messages, pause, game over and style switching.

const SKINS := [
	{"name": "Arcade 1980", "script": preload("res://games/firefly/skins/arcade_skin.gd")},
	{"name": "Neon", "script": preload("res://games/firefly/skins/neon_skin.gd")},
	{"name": "Shadow Theatre", "script": preload("res://games/firefly/skins/shadow_skin.gd")},
]
const MODES := ["1 Player", "2 Players (alternating)"]
const LIVES := [3, 5]


func _init() -> void:
	id = "firefly"
	skins = SKINS
	title = "FIREFLY"
	tagline = "maze chase  ·  1980 style"
	hint = "Arrows / WASD / gamepad   ·   Mouse: click a direction   ·   Touch screen: swipe"
	prompt_offset = 118.0
	pause_pos = Vector2(1126, 400)   # on the right side panel, away from the field


func _create_game() -> Node:
	var g := FireflyGame.new()
	g.game_over.connect(show_players_result)
	g.level_cleared.connect(func() -> void: say(I18n.t("GARDEN LIT UP!"), 2.4))
	return g


func _build_options(box: VBoxContainer) -> void:
	add_option(box, "Mode", MODES, "mode")
	add_option(box, "Lives", LIVES, "lives")


func _start_demo() -> void:
	game.start(FireflyGame.Mode.DEMO, 3)


func _start_play() -> void:
	game.start(FireflyGame.Mode.ONE if option("mode") == 0 else FireflyGame.Mode.TWO, LIVES[option("lives")])


func _status_text() -> String:
	var two: bool = game.mode == FireflyGame.Mode.TWO
	if game.state == FireflyGame.State.DYING and game.player().lives == 0 and two:
		return I18n.t("PLAYER %d OUT OF LIVES") % (game.current + 1)
	if game.state == FireflyGame.State.READY:
		var who := I18n.t("PLAYER %d\n") % (game.current + 1) if two else ""
		return who + I18n.t("READY!")
	return ""

extends GameShell
## Breakout: menu (with the demo behind it), game messages, pause, game over and style switching.

const SKINS := [
	{"name": "Classic 1976", "script": preload("res://games/breakout/skins/classic_skin.gd")},
	{"name": "Neon", "script": preload("res://games/breakout/skins/neon_skin.gd")},
	{"name": "Stained Glass", "script": preload("res://games/breakout/skins/glass_skin.gd")},
]
const MODES := ["1 Player", "2 Players (alternating)"]
const BALLS := [3, 5]


func _init() -> void:
	id = "breakout"
	skins = SKINS
	title = "BRICK BREAKER"
	title_size = 70
	tagline = "brick wall, 1976 style"
	hint = "Mouse / arrows / A D   ·   Touch screen: drag   ·   Space or tap: launch"
	prompt_offset = 150.0
	pause_pos = Vector2(1128, 600)   # on the right side panel, away from the field
	hide_mouse = true                # the mouse steers the paddle


func _create_game() -> Node:
	var g := BreakoutGame.new()
	g.game_over.connect(show_players_result)
	g.wall_cleared.connect(func(_p: int) -> void: say(I18n.t("WALL CLEARED!"), 1.8))
	return g


func _build_options(box: VBoxContainer) -> void:
	add_option(box, "Mode", MODES, "mode")
	add_option(box, "Balls", BALLS, "balls")


func _start_demo() -> void:
	game.start(BreakoutGame.Mode.DEMO, 3)


func _start_play() -> void:
	game.start(BreakoutGame.Mode.ONE if option("mode") == 0 else BreakoutGame.Mode.TWO, BALLS[option("balls")])


func _status_text() -> String:
	var two: bool = game.mode == BreakoutGame.Mode.TWO
	if game.state == BreakoutGame.State.LOST and game.player().balls == 0 and two:
		return I18n.t("PLAYER %d OUT OF BALLS") % (game.current + 1)
	if game.waiting_serve():
		var who := I18n.t("PLAYER %d\n") % (game.current + 1) if two else ""
		var how := I18n.t("tap to launch") if DisplayServer.is_touchscreen_available() else I18n.t("Space or click to launch")
		return who + how
	return ""

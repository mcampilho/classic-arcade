extends GameShell
## Frogger: menu (with the demo behind it), game messages, pause, game over and style switching.

const SKINS := [
	{"name": "Classic 1981", "script": preload("res://games/frogger/skins/classic_skin.gd")},
	{"name": "Neon", "script": preload("res://games/frogger/skins/neon_skin.gd")},
	{"name": "Felt", "script": preload("res://games/frogger/skins/felt_skin.gd")},
]
const MODES := ["1 Player", "2 Players (alternating)"]
const LIVES := [3, 5]


func _init() -> void:
	id = "frogger"
	skins = SKINS
	title = "THE CROSSING"
	tagline = "cross the road and the river, 1981 style"
	hint = "Hop: arrows / WASD / gamepad   ·   Mouse: click a direction   ·   Touch: swipe (tap = forward)"
	prompt_offset = -60.0
	pause_pos = Vector2(1104, 400)   # on the right side panel, away from the field


func _create_game() -> Node:
	var g := FroggerGame.new()
	g.game_over.connect(show_players_result)
	g.level_cleared.connect(func() -> void: say(I18n.t("ALL HOME!"), 2.5))
	return g


func _build_options(box: VBoxContainer) -> void:
	add_option(box, "Mode", MODES, "mode")
	add_option(box, "Lives", LIVES, "lives")


func _start_demo() -> void:
	game.start(FroggerGame.Mode.DEMO, 3)


func _start_play() -> void:
	game.start(FroggerGame.Mode.ONE if option("mode") == 0 else FroggerGame.Mode.TWO, LIVES[option("lives")])


func _status_text() -> String:
	var two: bool = game.mode == FroggerGame.Mode.TWO
	if game.state == FroggerGame.State.DYING and game.player().lives == 0 and two:
		return I18n.t("PLAYER %d OUT OF LIVES") % (game.current + 1)
	if game.state == FroggerGame.State.READY and two:
		return I18n.t("PLAYER %d") % (game.current + 1)
	return ""

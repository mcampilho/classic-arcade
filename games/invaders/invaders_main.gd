extends GameShell
## Space Invaders: menu (with the demo behind it), game messages, pause, game over and style switching.

const SKINS := [
	{"name": "Classic 1978", "script": preload("res://games/invaders/skins/classic_skin.gd")},
	{"name": "Neon", "script": preload("res://games/invaders/skins/neon_skin.gd")},
	{"name": "Azulejo Tiles", "script": preload("res://games/invaders/skins/azulejo_skin.gd")},
]
const MODES := ["1 Player", "2 Players (alternating)"]
const LIVES := [3, 5]


func _init() -> void:
	id = "invaders"
	skins = SKINS
	title = "ALIEN ATTACK"
	title_size = 64
	tagline = "invasion from space, 1978 style"
	hint = "Arrows / A D / mouse   ·   Fire: Space or click   ·   Touch screen: drag (auto-fire)"
	prompt_offset = 150.0
	pause_pos = Vector2(1104, 400)   # on the right side panel, away from the field
	hide_mouse = true                # the mouse steers the cannon


func _create_game() -> Node:
	var g := InvadersGame.new()
	g.game_over.connect(show_players_result)
	g.wave_cleared.connect(func() -> void: say(I18n.t("INVASION STOPPED!"), 2.0))
	return g


func _build_options(box: VBoxContainer) -> void:
	add_option(box, "Mode", MODES, "mode")
	add_option(box, "Lives", LIVES, "lives")


func _start_demo() -> void:
	game.start(InvadersGame.Mode.DEMO, 3)


func _start_play() -> void:
	game.start(InvadersGame.Mode.ONE if option("mode") == 0 else InvadersGame.Mode.TWO, LIVES[option("lives")])


func _status_text() -> String:
	var two: bool = game.mode == InvadersGame.Mode.TWO
	if game.state == InvadersGame.State.DYING and game.player().lives == 0 and two:
		return I18n.t("PLAYER %d OUT OF LIVES") % (game.current + 1)
	if game.state == InvadersGame.State.READY:
		var who := I18n.t("PLAYER %d\n") % (game.current + 1) if two else ""
		return who + I18n.t("WAVE %d") % game.player().wave
	return ""

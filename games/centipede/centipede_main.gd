extends GameShell
## Centipede: menu (with the demo behind it), game messages, pause, game over and style switching.

const SKINS := [
	{"name": "Classic 1981", "script": preload("res://games/centipede/skins/classic_skin.gd")},
	{"name": "Neon", "script": preload("res://games/centipede/skins/neon_skin.gd")},
	{"name": "Naturalist Engraving", "script": preload("res://games/centipede/skins/engraving_skin.gd")},
]
const MODES := ["1 Player", "2 Players (alternating)"]
const LIVES := [3, 5]


func _init() -> void:
	id = "centipede"
	skins = SKINS
	title = "MUSHROOMS"
	tagline = "centipede in a mushroom field, 1981 style"
	hint = "Move: arrows / WASD / mouse / gamepad   ·   Fire: Space or click (hold)   ·   Touch: drag (auto-fire)"
	prompt_offset = -40.0
	pause_pos = Vector2(1104, 400)   # on the right side panel, away from the field
	hide_mouse = true                # the mouse steers the shooter


func _create_game() -> Node:
	var g := CentipedeGame.new()
	g.game_over.connect(show_players_result)
	g.wave_cleared.connect(func() -> void: say(I18n.t("WAVE %d") % game.wave(), 1.5))
	return g


func _build_options(box: VBoxContainer) -> void:
	add_option(box, "Mode", MODES, "mode")
	add_option(box, "Lives", LIVES, "lives")


func _start_demo() -> void:
	game.start(CentipedeGame.Mode.DEMO, 3)


func _start_play() -> void:
	game.start(CentipedeGame.Mode.ONE if option("mode") == 0 else CentipedeGame.Mode.TWO, LIVES[option("lives")])


func _status_text() -> String:
	if game.state == CentipedeGame.State.REPAIR:
		return I18n.t("REPAIRING MUSHROOMS")
	if game.state == CentipedeGame.State.READY and game.mode == CentipedeGame.Mode.TWO:
		return I18n.t("PLAYER %d") % (game.current + 1)
	return ""

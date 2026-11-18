extends GameShell
## Chuckie Egg: menu (with the demo behind it), level messages, pause, game over and style switching.

const SKINS := [
	{"name": "Classic 1983", "script": preload("res://games/chuckie/skins/classic_skin.gd")},
	{"name": "Neon", "script": preload("res://games/chuckie/skins/neon_skin.gd")},
	{"name": "Cross-Stitch", "script": preload("res://games/chuckie/skins/stitch_skin.gd")},
]
const MODES := ["1 Player", "2 Players (alternating)"]
const LIVES := [5, 3]


func _init() -> void:
	id = "chuckie"
	skins = SKINS
	title = "HEN HOUSE"
	tagline = "platforms and ladders, 1983 style"
	hint = "Walk and climb: arrows / WASD / gamepad   ·   Jump: Space, Z or A\nTouch: drag on left half (walk/ladders), tap right half to jump"
	pause_pos = Vector2(1148, 640)   # on the right side panel, away from the field


func _create_game() -> Node:
	var g := ChuckieGame.new()
	g.game_over.connect(show_players_result)
	g.level_started.connect(func(_l: int) -> void: say(I18n.t("LEVEL %d  ·  %s") % [game.level(), game.level_name().to_upper()], 2.0))
	g.level_cleared.connect(func(bonus: int) -> void: say(I18n.t("LEVEL CLEAR!  BONUS %d") % bonus, 2.0))
	g.turn_started.connect(func(p: int) -> void:
		if game.mode == ChuckieGame.Mode.TWO:
			say(I18n.t("PLAYER %d  ·  LEVEL %d") % [p + 1, game.level()], 2.0))
	return g


func _build_options(box: VBoxContainer) -> void:
	add_option(box, "Mode", MODES, "mode")
	add_option(box, "Lives", LIVES, "lives")


func _start_demo() -> void:
	game.start_demo()


func _start_play() -> void:
	game.start(ChuckieGame.Mode.ONE if option("mode") == 0 else ChuckieGame.Mode.TWO, LIVES[option("lives")])


func _status_text() -> String:
	if game.state == ChuckieGame.State.PLAY and game.time_left < 100.0:
		return I18n.t("HURRY UP!") if fmod(Time.get_ticks_msec() / 1000.0, 0.8) < 0.5 else ""
	return ""

extends GameShell
## OutRun: menu (with the demo behind it), start countdown, stage messages, pause,
## end of the run, radio and style switching.

const SKINS := [
	{"name": "Classic 1986", "script": preload("res://games/outrun/skins/classic_skin.gd")},
	{"name": "Synthwave", "script": preload("res://games/outrun/skins/synthwave_skin.gd")},
	{"name": "Travel Poster", "script": preload("res://games/outrun/skins/poster_skin.gd")},
]
const GEARS := ["Automatic", "Manual (Space)"]


func _init() -> void:
	id = "outrun"
	skins = SKINS
	default_style = 0
	title = "SUN ROAD"
	title_size = 70
	tagline = "road racing, 1986 style"
	hint = "Steer: arrows / A D / mouse / gamepad   ·   Accelerate: ↑ W or click   ·   Brake: ↓ S or right button\nTouch: drag sideways to steer · 1 finger accelerates · 2 fingers brake   ·   At the fork, pick a side"
	play_text = "Drive"
	again_text = "Drive again"
	over_text = "END OF THE ROAD"
	over_width = 520.0
	over_score_size = 26
	prompt_size = 34
	prompt_outline = 12
	prompt_offset = -120.0
	pause_pos = Vector2(1180, 620)


func _ready() -> void:
	super._ready()
	# The radio songs are also generated in the background.
	add_task(OutRunMusic.prewarm())


func _create_game() -> Node:
	var g := OutRunGame.new()
	g.game_over.connect(_on_game_over)
	g.countdown.connect(_on_countdown)
	g.checkpoint.connect(func(_s: int, _bonus: float) -> void: say(I18n.t("STAGE %d  ·  %s") % [game.stage + 1, OutRunGame.THEME_NAMES[game.theme].to_upper()], 2.5))
	g.goal.connect(func(bonus: int) -> void: say(I18n.t("GOAL!  TIME BONUS %d") % bonus, 5.0))
	g.time_up.connect(func() -> void: say(I18n.t("TIME UP"), 3.0))
	return g


func _build_options(box: VBoxContainer) -> void:
	add_option(box, "Gearbox", GEARS, "gears")
	var radios: Array = OutRunMusic.NAMES.duplicate()
	radios.append(I18n.t("None"))
	var radio := add_option(box, "Radio", radios, "radio")
	radio.value_changed.connect(func(_i: int) -> void: game.skin.set_radio(_radio()))


## Chosen radio station (-1 = off).
func _radio() -> int:
	var i := option("radio")
	return i if i < OutRunMusic.NAMES.size() else -1


func _style_applied(pal: Dictionary) -> void:
	game.skin.set_radio(_radio())
	prompt.add_theme_color_override("font_color", pal.accent)
	prompt.add_theme_color_override("font_outline_color", Color(pal.panel, 0.95))


func _on_countdown(n: int) -> void:
	if game.mode == OutRunGame.Mode.DEMO:
		return
	say(str(n) if n > 0 else I18n.t("GO!"), 0.9 if n > 0 else 1.2)


func _start_demo() -> void:
	game.manual_gears = false
	game.start(OutRunGame.Mode.DEMO)


func _start_play() -> void:
	game.manual_gears = option("gears") == 1
	game.start(OutRunGame.Mode.PLAY)


func _status_text() -> String:
	if game.state == OutRunGame.State.PLAY and game.stage < OutRunGame.STAGES - 1:
		var i: int = game.player_segment().index
		if i > game.fork_start - 70 and i < game.fork_start + 40:
			return I18n.t("<  CHOOSE YOUR ROUTE  >")
	return ""


func _on_game_over() -> void:
	var reached: bool = game.state == OutRunGame.State.OVER and game.stage >= OutRunGame.STAGES - 1 and game.time_left > 0.0
	var path := []
	for s in game.route.size():
		path.append(I18n.t(OutRunGame.THEME_NAMES[OutRunGame.theme_for(s, game.route[s])]))
	show_result(I18n.t("YOU MADE IT!") if reached else I18n.t("END OF THE ROAD"),
			I18n.t("%d points\n%s") % [game.score, " → ".join(path)], game.score)

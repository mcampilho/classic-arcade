extends GameShell
## Flock: menu (with the demo behind it), messages, pause, game over and style switching.

const SKINS := [
	{"name": "Classic 1991", "script": preload("res://games/flock/skins/classic_skin.gd")},
	{"name": "Plasticine", "script": preload("res://games/flock/skins/clay_skin.gd")},
	{"name": "Notepad", "script": preload("res://games/flock/skins/notebook_skin.gd")},
]
const SPEEDS := ["Normal", "Fast"]


func _init() -> void:
	id = "flock"
	skins = SKINS
	default_style = 0
	title = "FLOCK"
	title_size = 70
	tagline = "1991-style puzzle: lead the sheep to the barn"
	hint = "Pick a skill on the panel (keys 1-7 or Q/E) and click/tap a sheep to assign it\nCursor also with arrows/WASD and Space   ·   F: speed   ·   R: restart level   ·   Esc: pause"
	prompt_offset = -240.0
	pause_pos = Vector2(1204, 34)
	pause_size = Vector2(68, 48)


func _create_game() -> Node:
	var g := FlockGame.new()
	g.game_over.connect(_on_game_over)
	g.won.connect(func() -> void: get_tree().create_timer(4.0).timeout.connect(_on_game_over))
	g.level_started.connect(func(l: int) -> void:
		say(I18n.t("LEVEL %d: %s\nSAVE %d OF %d SHEEP") % [l + 1, I18n.t(String(game.data().name)).to_upper(), int(game.data().need), int(game.data().count)], 3.0))
	g.level_ended.connect(_on_level_ended)
	g.won.connect(func() -> void: say(I18n.t("THE WHOLE FLOCK IS HOME!"), 6.0))
	return g


func _on_level_ended(ok: bool) -> void:
	if not playing or game.state == FlockGame.State.WON:
		return
	if ok:
		say(I18n.t("WELL DONE! %d SHEEP SAVED") % game.saved_n, 2.6)
	else:
		say(I18n.t("ONLY %d OF %d... TRY AGAIN") % [game.saved_n, int(game.data().need)], 2.6)
	get_tree().create_timer(2.8).timeout.connect(func() -> void:
		if playing and game.state == FlockGame.State.END:
			game.continue_after_end())


func _build_options(box: VBoxContainer) -> void:
	add_option(box, "Starting speed", SPEEDS, "speed")


func _start_demo() -> void:
	game.start(FlockGame.Mode.DEMO)


func _start_play() -> void:
	game.start(FlockGame.Mode.PLAY)
	game.fast = option("speed") == 1


func _on_game_over() -> void:
	show_result(I18n.t("FLOCK SAVED!"), I18n.t("%d points  ·  %d levels") % [game.score, FlockGame.LEVELS.size()], game.score)

extends GameShell
## Pong: menu (with the demo behind it), pause, game over and live style switching.

const SKINS := [
	{"name": "Classic 1972", "script": preload("res://games/pong/skins/classic_skin.gd")},
	{"name": "Neon", "script": preload("res://games/pong/skins/neon_skin.gd")},
	{"name": "Paper & Ink", "script": preload("res://games/pong/skins/paper_skin.gd")},
]
const MODES := ["1 Player vs CPU", "2 Players"]
const DIFFS := ["Easy", "Normal", "Hard"]

var _diff_button: CycleButton


func _init() -> void:
	id = "pong"
	skins = SKINS
	title = "PADDLES"
	title_size = 80
	tagline = "electronic tennis, 1972 style"
	hint = "P1: W / S    P2: arrows    Touch: drag    Pause: Esc"
	hint_size = 16
	over_text = ""
	over_width = 460.0
	over_score_size = 30
	pause_pos = Vector2.INF
	tracks_best = false


func _create_game() -> Node:
	var g := PongGame.new()
	g.game_over.connect(_on_game_over)
	return g


func _build_options(box: VBoxContainer) -> void:
	var mode_btn := add_option(box, "Mode", MODES, "mode")
	_diff_button = add_option(box, "CPU", DIFFS, "difficulty", 1)
	_diff_button.visible = option("mode") == 0
	mode_btn.value_changed.connect(func(i: int) -> void: _diff_button.visible = i == 0)


func _start_demo() -> void:
	game.start(PongGame.Mode.DEMO)


func _start_play() -> void:
	game.difficulty = option("difficulty")
	game.start(PongGame.Mode.VS_CPU if option("mode") == 0 else PongGame.Mode.VS_HUMAN)


func _clear_input() -> void:
	game.clear_touches()


func _on_game_over(winner: int) -> void:
	var t: String
	if game.mode == PongGame.Mode.VS_CPU:
		t = I18n.t("VICTORY!") if winner == 0 else I18n.t("CPU WINS")
	else:
		t = I18n.t("PLAYER %d WINS!") % (winner + 1)
	show_result(t, "%d  –  %d" % [game.scores[0], game.scores[1]])

class_name GameShell
extends Node
## Shared frame around every game: main menu (with the demo running behind it), options,
## style switching, pause, game over with high score, on-screen messages, the touch pause
## button, the Android "back" button and pausing when the window loses focus.
##
## A game's *_main.gd extends this class, sets the fields below in _init() and overrides
## the hooks it needs (_create_game, _build_options, _start_demo, _start_play, ...).
## The game node must have `paused`, `skin` and `set_skin(skin)`; `best` is optional.

signal exit_requested

# ---- set by each game in _init() ----
var id := ""                         ## settings section (also the launcher "arg")
var skins: Array = []                ## [{"name": String, "script": Script}]
var default_style := 1
var title := ""
var title_size := 76
var tagline := ""
var hint := ""
var hint_size := 15
var play_text := "Play"
var again_text := "Play again"
var over_text := "GAME OVER"
var over_width := 480.0
var over_score_size := 28
var prompt_size := 30
var prompt_outline := 10
var prompt_offset := -150.0          ## vertical offset of the message from the screen centre
var pause_pos := Vector2(1148, 640)  ## touch pause button; Vector2.INF = centred at the top
var pause_size := Vector2(72, 60)
var hide_mouse := false              ## hide the cursor while playing (the mouse steers)
var tracks_best := true              ## keeps a high score

# ---- state ----
var style_idx := 1
var playing := false
var best := 0
var game: Node
var ui: CanvasLayer
var ui_root: Control
var hud: Control
var prompt: Label
var menu := {}
var pause_menu := {}
var over_menu := {}
var title_label: Label
var best_label: Label
var over_title: Label
var over_score: Label
var over_record: Label
var play_button: Button
var resume_button: Button
var again_button: Button

var _options := {}                   # settings key -> chosen index
var _tasks: Array[int] = []          # background tasks to wait for on exit
var _msg := ""
var _msg_t := 0.0


func _ready() -> void:
	style_idx = Settings.get_index(id, "style", default_style, skins.size())
	best = Settings.get_int(id, "best", 0)
	game = _create_game()
	if "best" in game:
		game.best = best
	add_child(game)
	_build_ui()
	_apply_style()
	_show_menu()
	# Builds the sounds of the other styles in the background, so switching is instant.
	add_task(Synth.prewarm(skins.map(func(s: Dictionary) -> Script: return s.script)))

	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--style="):
			style_idx = clampi(int(a.get_slice("=", 1)), 0, skins.size() - 1)
			_apply_style()
	if "--play" in args:
		_start_match()


# ---------------------------------------------------------------- hooks for the games

## Creates the game node (not yet in the tree) and connects its signals.
func _create_game() -> Node:
	push_error("GameShell._create_game() not implemented")
	return Node.new()


## Adds the game's own options to the main menu (see add_option()).
func _build_options(_box: VBoxContainer) -> void:
	pass


func _start_demo() -> void:
	pass


func _start_play() -> void:
	pass


## Text shown in the middle of the screen when there is no timed message.
func _status_text() -> String:
	return ""


## Called after a style is applied, with its UI palette.
func _style_applied(_pal: Dictionary) -> void:
	pass


## Whether the match can still be paused (not over or won).
func _can_pause() -> bool:
	var states: Dictionary = game.get_script().get_script_constant_map().get("State", {})
	for s in ["OVER", "WON"]:
		if states.has(s) and game.state == states[s]:
			return false
	return true


func _clear_input() -> void:
	if game.has_method("clear_input"):
		game.clear_input()


## Called when the screen changes; `in_play` is true while the match is being played.
func _screen_changed(in_play: bool) -> void:
	if hide_mouse:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if in_play else Input.MOUSE_MODE_VISIBLE


# ---------------------------------------------------------------- helpers for the games

## Adds a cyclic option saved in the settings; returns the button.
## `values` are shown as text (numbers are converted); option(key) gives the chosen index.
func add_option(box: VBoxContainer, label: String, values: Array, key: String, default := 0) -> CycleButton:
	_options[key] = Settings.get_index(id, key, default, values.size())
	var b := CycleButton.new().setup(I18n.t(label), values.map(func(v: Variant) -> String: return str(v)), _options[key])
	b.value_changed.connect(func(i: int) -> void:
		_options[key] = i
		Settings.set_value(id, key, i))
	box.add_child(b)
	return b


func option(key: String) -> int:
	return _options.get(key, 0)


## Shows a message in the middle of the screen for `secs` seconds.
func say(text: String, secs: float) -> void:
	_msg = text
	_msg_t = secs


func add_task(task_id: int) -> void:
	if task_id >= 0:
		_tasks.append(task_id)


## Opens the game-over screen. `score` updates the high score (-1 = not a scored game).
func show_result(title_text: String, score_text: String, score := -1) -> void:
	if not playing:
		return
	over_title.text = title_text
	over_score.text = score_text
	over_record.text = ""
	if tracks_best and score >= 0:
		if score > best:
			best = score
			if "best" in game:
				game.best = best
			Settings.set_value(id, "best", best)
			over_record.text = I18n.t("New high score!")
		else:
			over_record.text = I18n.t("High score: %d") % best
	_show_screen(over_menu, again_button)


## Game over for games with `players` (1 or 2 taking turns), each with a `score`.
func show_players_result() -> void:
	if game.players.size() == 1:
		var s: int = game.players[0].score
		show_result(I18n.t("GAME OVER"), I18n.t("%d points") % s, s)
		return
	var a: int = game.players[0].score
	var b: int = game.players[1].score
	var t := I18n.t("DRAW!") if a == b else I18n.t("PLAYER %d WINS!") % (1 if a > b else 2)
	show_result(t, I18n.t("Player 1: %d   ·   Player 2: %d") % [a, b], maxi(a, b))


# ---------------------------------------------------------------- interface

func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	ui_root = Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(ui_root)

	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(hud)
	prompt = UI.label("", prompt_size)
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	prompt.position.y += prompt_offset
	prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
	prompt.add_theme_constant_override("outline_size", prompt_outline)
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(prompt)
	# Pause button only on touch screens (on a PC: Esc / P / Start).
	if DisplayServer.is_touchscreen_available():
		var pause_btn := UI.button("II", _set_paused.bind(true))
		pause_btn.focus_mode = Control.FOCUS_NONE
		pause_btn.add_theme_font_size_override("font_size", 20)
		pause_btn.modulate.a = 0.6
		hud.add_child(pause_btn)
		if pause_pos == Vector2.INF:
			pause_btn.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 14)
		else:
			pause_btn.custom_minimum_size = pause_size
			pause_btn.position = pause_pos

	menu = UI.overlay(ui_root)
	var box: VBoxContainer = menu.box
	title_label = UI.label(I18n.t(title), title_size)
	box.add_child(title_label)
	box.add_child(UI.label(I18n.t(tagline), 20))
	_build_options(box)
	var style_btn := CycleButton.new().setup(I18n.t("Style"), skins.map(func(s: Dictionary) -> String: return s.name), style_idx)
	style_btn.value_changed.connect(func(i: int) -> void:
		style_idx = i
		_apply_style())
	box.add_child(style_btn)
	play_button = UI.button(I18n.t(play_text), _start_match)
	box.add_child(play_button)
	box.add_child(UI.button(I18n.t("Back to arcade"), func() -> void: exit_requested.emit()))
	best_label = UI.label("", 18)
	box.add_child(best_label)
	var hint_label := UI.label(I18n.t(hint), hint_size)
	hint_label.modulate.a = 0.6
	box.add_child(hint_label)

	pause_menu = UI.overlay(ui_root, 420)
	pause_menu.box.add_child(UI.label(I18n.t("PAUSED"), 52))
	resume_button = UI.button(I18n.t("Resume"), _set_paused.bind(false))
	pause_menu.box.add_child(resume_button)
	pause_menu.box.add_child(UI.button(I18n.t("Restart"), _start_match))
	pause_menu.box.add_child(UI.button(I18n.t("Menu"), _show_menu))

	over_menu = UI.overlay(ui_root, over_width)
	over_title = UI.label(I18n.t(over_text), 48)
	over_menu.box.add_child(over_title)
	over_score = UI.label("", over_score_size)
	over_menu.box.add_child(over_score)
	over_record = UI.label("", 24)
	over_menu.box.add_child(over_record)
	again_button = UI.button(I18n.t(again_text), _start_match)
	over_menu.box.add_child(again_button)
	over_menu.box.add_child(UI.button(I18n.t("Menu"), _show_menu))


func _apply_style() -> void:
	game.set_skin(skins[style_idx].script.new())
	var pal: Dictionary = game.skin.ui_palette()
	ui_root.theme = UI.make_theme(pal)
	title_label.add_theme_color_override("font_color", pal.accent)
	over_record.add_theme_color_override("font_color", pal.accent)
	prompt.add_theme_color_override("font_outline_color", Color(pal.panel, 0.9))
	for o: Dictionary in [menu, pause_menu, over_menu]:
		o.dim.color = pal.dim
	_style_applied(pal)
	Settings.set_value(id, "style", style_idx)


func _process(delta: float) -> void:
	_msg_t = maxf(_msg_t - delta, 0.0)
	if not playing or game.paused:
		prompt.text = ""
		return
	prompt.text = _msg if _msg_t > 0.0 else _status_text()


# ---------------------------------------------------------------- flow

func _show_screen(which: Dictionary, focus: Button) -> void:
	for o: Dictionary in [menu, pause_menu, over_menu]:
		o.root.visible = o == which
	hud.visible = which.is_empty()
	_screen_changed(which.is_empty())
	if focus:
		focus.grab_focus()


func _show_menu() -> void:
	playing = false
	best_label.text = I18n.t("High score: %d") % best if tracks_best and best > 0 else ""
	_start_demo()
	_show_screen(menu, play_button)


func _start_match() -> void:
	playing = true
	_msg_t = 0.0
	_clear_input()
	_start_play()
	_show_screen({}, null)
	get_viewport().gui_release_focus()


func _set_paused(on: bool) -> void:
	if not playing or not _can_pause():
		return
	game.paused = on
	_clear_input()
	if on:
		_show_screen(pause_menu, resume_button)
	else:
		_show_screen({}, null)
		get_viewport().gui_release_focus()


## Esc / P / Start on a gamepad.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if menu.root.visible:
			exit_requested.emit()
		elif over_menu.root.visible:
			_show_menu()
		else:
			_set_paused(not pause_menu.root.visible)


func _notification(what: int) -> void:
	# Pauses when the window loses focus in the middle of a match.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and playing and not game.paused:
		_set_paused(true)


## Android "back" button.
func go_back() -> void:
	if menu.root.visible:
		exit_requested.emit()
	elif pause_menu.root.visible or over_menu.root.visible:
		_show_menu()
	else:
		_set_paused(true)


func _exit_tree() -> void:
	for t in _tasks:
		WorkerThreadPool.wait_for_task_completion(t)
	_screen_changed(false)

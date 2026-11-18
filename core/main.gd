extends Node
## Classic Arcade start screen: the list of games.
## Each game is a Node with the `exit_requested` signal and the `go_back()` method (see GameShell).

const GAMES := [
	{"title": "Paddles", "year": "1972", "arg": "pong", "script": "res://games/pong/pong_main.gd"},
	{"title": "Brick Breaker", "year": "1976", "arg": "breakout", "script": "res://games/breakout/breakout_main.gd"},
	{"title": "Alien Attack", "year": "1978", "arg": "invaders", "script": "res://games/invaders/invaders_main.gd"},
	{"title": "Meteors", "year": "1979", "arg": "asteroids", "script": "res://games/asteroids/asteroids_main.gd"},
	{"title": "Swarm", "year": "1979", "arg": "galaxian", "script": "res://games/galaxian/galaxian_main.gd"},
	{"title": "Firefly", "year": "1980", "arg": "firefly", "script": "res://games/firefly/firefly_main.gd"},
	{"title": "The Crossing", "year": "1981", "arg": "frogger", "script": "res://games/frogger/frogger_main.gd"},
	{"title": "Mushrooms", "year": "1981", "arg": "centipede", "script": "res://games/centipede/centipede_main.gd"},
	{"title": "Incursion", "year": "1982", "arg": "penetrator", "script": "res://games/penetrator/penetrator_main.gd"},
	{"title": "Hen House", "year": "1983", "arg": "chuckie", "script": "res://games/chuckie/chuckie_main.gd"},
	{"title": "Jet Astronaut", "year": "1983", "arg": "jetpac", "script": "res://games/jetpac/jetpac_main.gd"},
	{"title": "Tower of Relics", "year": "1984", "arg": "relics", "script": "res://games/relics/relics_main.gd"},
	{"title": "Stack", "year": "1984", "arg": "blocks", "script": "res://games/blocks/blocks_main.gd"},
	{"title": "School Trouble", "year": "1985", "arg": "school", "script": "res://games/school/school_main.gd"},
	{"title": "Sun Road", "year": "1986", "arg": "outrun", "script": "res://games/outrun/outrun_main.gd"},
	{"title": "Sword of the Valley", "year": "1986", "arg": "vale", "script": "res://games/vale/vale_main.gd"},
	{"title": "Palace Escape", "year": "1989", "arg": "palace", "script": "res://games/palace/palace_main.gd"},
	{"title": "Flock", "year": "1991", "arg": "flock", "script": "res://games/flock/flock_main.gd"},
]

var ui: CanvasLayer
var root: Control
var first_button: Button
var current: Node
# "inspired by" footer
var info_title: Label
var info_story: Label
var info_wiki: Button
var _info_game := {}
var _buttons := {}                     # arg -> the game's button
var _last_button: Button
var _touch := false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--settings="):   # e.g. smoke tests that must not touch the player's file
			Settings.use_file(a.get_slice("=", 1))
	var lang := str(Settings.get_value("general", "lang", ""))
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--lang="):
			lang = a.get_slice("=", 1)
	I18n.setup(lang if lang != "" else I18n.system_lang())
	_build_ui()
	var args := OS.get_cmdline_user_args()
	# development shortcuts: open a game directly
	for g: Dictionary in GAMES:
		if "--" + String(g.arg) in args:
			_open(g)
			break


func _build_ui() -> void:
	_touch = DisplayServer.is_touchscreen_available() and not "--mouse" in OS.get_cmdline_user_args()
	ui = CanvasLayer.new()
	add_child(ui)
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UI.make_theme(UI.LAUNCHER_PALETTE)
	ui.add_child(root)

	var bg := ColorRect.new()
	bg.color = Color(0.035, 0.04, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.custom_minimum_size.x = 1212
	center.add_child(box)

	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 22)
	head.add_child(UI.label(I18n.t("CLASSIC ARCADE"), 46, UI.LAUNCHER_PALETTE.accent))
	var sub := UI.label(I18n.t("the classics, modernised"), 20, Color(1, 1, 1, 0.55))
	sub.size_flags_vertical = Control.SIZE_SHRINK_END
	head.add_child(sub)
	box.add_child(head)

	# the games in a 3-column grid
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	box.add_child(grid)
	for g: Dictionary in GAMES:
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", 4)
		var b := UI.button("%s  ·  %s" % [I18n.t(g.title), g.year], _open.bind(g))
		b.custom_minimum_size = Vector2(344 if _touch else 396, 46)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 19)
		cell.add_child(b)
		# on a touch screen, tapping a game opens it at once: the "i" shows the information
		if _touch:
			var i := UI.button("i", func() -> void: _show_info(g))
			i.custom_minimum_size = Vector2(48, 46)
			i.focus_mode = Control.FOCUS_NONE
			i.add_theme_font_size_override("font_size", 19)
			cell.add_child(i)
		grid.add_child(cell)
		_buttons[g.arg] = b
		b.focus_entered.connect(_show_info.bind(g))
		# the mouse gives focus to the button: only one button is highlighted at a time
		b.mouse_entered.connect(func() -> void:
			if b.has_focus():
				_show_info(g)
			else:
				b.grab_focus())
		if first_button == null:
			first_button = b

	box.add_child(_build_info())

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 16)
	box.add_child(bottom)
	var hint := UI.label(I18n.t("F11: full screen"), 16, Color(1, 1, 1, 0.35))
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if OS.get_name() != "Web":
		var quit := UI.button(I18n.t("Quit"), get_tree().quit)
		quit.custom_minimum_size = Vector2(220, 44)
		quit.mouse_entered.connect(func() -> void: quit.grab_focus())
		bottom.add_child(quit)
	bottom.add_child(hint)
	var lang_btn := CycleButton.new().setup("Idioma / Language", I18n.LANG_NAMES, I18n.LANGS.find(I18n.lang))
	lang_btn.custom_minimum_size = Vector2(400, 44)
	lang_btn.mouse_entered.connect(func() -> void: lang_btn.grab_focus())
	lang_btn.value_changed.connect(_set_lang)
	bottom.add_child(lang_btn)
	first_button.call_deferred("grab_focus")


# ---------------------------------------------------------------- "inspired by" footer

func _build_info() -> PanelContainer:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.11)
	sb.border_color = Color(UI.LAUNCHER_PALETTE.accent, 0.5)
	sb.border_width_top = 2
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size.y = 150
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	panel.add_child(v)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	info_title = UI.label("", 20, UI.LAUNCHER_PALETTE.accent)
	info_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info_title)
	info_wiki = UI.button("", func() -> void:
		if not _info_game.is_empty():
			OS.shell_open(_wiki_url(Inspirations.INFO[_info_game.arg])))
	info_wiki.add_theme_font_size_override("font_size", 15)
	info_wiki.custom_minimum_size.y = 34
	info_wiki.visible = false
	info_wiki.mouse_entered.connect(func() -> void: info_wiki.grab_focus())
	row.add_child(info_wiki)
	info_story = UI.label("", 16, Color(1, 1, 1, 0.82))
	info_story.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info_story.autowrap_mode = TextServer.AUTOWRAP_WORD
	info_story.custom_minimum_size.x = 1170
	v.add_child(info_story)
	info_title.text = I18n.t("The classics that inspired these games")
	info_story.text = (I18n.t("Tap the i button next to a game") if _touch else I18n.t("Hover or focus a game")) + I18n.t(" to see the classic it was inspired by, a short history and the Wikipedia link.")
	return panel


func _show_info(g: Dictionary) -> void:
	var info: Dictionary = Inspirations.INFO.get(g.arg, {})
	if info.is_empty() or g == _info_game:
		return
	_info_game = g
	info_title.text = I18n.t("%s  —  inspired by %s (%s)") % [I18n.t(g.title), info.name, info.by]
	info_story.text = I18n.t(info.story)
	var other := not _wiki_url(info).contains(I18n.lang + ".wikipedia")
	info_wiki.text = I18n.t("Wikipedia (English) ↗") if other else I18n.t("Wikipedia ↗")
	info_wiki.visible = true


## Wikipedia page in the chosen language ("wiki_pt", "wiki_es"), or the English one ("wiki").
func _wiki_url(info: Dictionary) -> String:
	return info.get("wiki_" + I18n.lang, info.wiki)


func _set_lang(i: int) -> void:
	I18n.setup(I18n.LANGS[i])
	Settings.set_value("general", "lang", I18n.lang)
	# rebuilds the start screen in the new language, keeping focus on the selector
	ui.queue_free()
	_buttons.clear()
	first_button = null
	_info_game = {}
	_build_ui()
	await get_tree().process_frame
	for c in root.find_children("*", "CycleButton", true, false):
		(c as Control).grab_focus()


func _open(g: Dictionary) -> void:
	_last_button = _buttons.get(g.arg)
	root.hide()
	current = load(g.script).new()
	add_child(current)
	current.exit_requested.connect(_close_game)


func _close_game() -> void:
	if current:
		current.queue_free()
		current = null
	root.show()
	(_last_button if _last_button else first_button).grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fullscreen"):
		var w := get_window()
		w.mode = Window.MODE_WINDOWED if w.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN


func _notification(what: int) -> void:
	# Android "back" button
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if current:
			current.go_back()
		else:
			get_tree().quit()

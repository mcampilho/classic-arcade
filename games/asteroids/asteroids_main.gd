extends GameShell
## Asteroids: menu (with the demo behind it), game messages, pause, game over and style switching.

const SKINS := [
	{"name": "Classic 1979", "script": preload("res://games/asteroids/skins/classic_skin.gd")},
	{"name": "Neon", "script": preload("res://games/asteroids/skins/neon_skin.gd")},
	{"name": "Origami", "script": preload("res://games/asteroids/skins/origami_skin.gd")},
]
const MODES := ["1 Player", "2 Players (alternating)"]
const LIVES := [3, 5]

var touch_overlay: Control


func _init() -> void:
	id = "asteroids"
	skins = SKINS
	title = "METEORS"
	tagline = "inertial space shooter, 1979 style"
	hint = "Rotate ← →  ·  Thrust ↑  ·  Fire Space  ·  Hyperspace ↓ / Shift\nMouse: aim, click fires, right button thrusts  ·  Touch: joystick on the left, fire on the right"
	prompt_offset = 150.0
	pause_pos = Vector2(604, 120)


func _create_game() -> Node:
	var g := AsteroidsGame.new()
	g.game_over.connect(show_players_result)
	g.wave_cleared.connect(func() -> void: say(I18n.t("WAVE %d") % (game.player().wave + 1), 1.8))
	return g


func _build_ui() -> void:
	super._build_ui()
	if DisplayServer.is_touchscreen_available():
		# virtual joystick and touch buttons
		touch_overlay = Control.new()
		touch_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		touch_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		touch_overlay.draw.connect(_draw_touch_overlay)
		hud.add_child(touch_overlay)


func _build_options(box: VBoxContainer) -> void:
	add_option(box, "Mode", MODES, "mode")
	add_option(box, "Lives", LIVES, "lives")


func _start_demo() -> void:
	game.start(AsteroidsGame.Mode.DEMO, 3)


func _start_play() -> void:
	game.start(AsteroidsGame.Mode.ONE if option("mode") == 0 else AsteroidsGame.Mode.TWO, LIVES[option("lives")])


func _status_text() -> String:
	if game.ship_waiting() and game.mode == AsteroidsGame.Mode.TWO:
		return I18n.t("PLAYER %d") % (game.current + 1)
	return ""


func _process(delta: float) -> void:
	super._process(delta)
	if touch_overlay:
		touch_overlay.queue_redraw()


## While playing, the cursor becomes a crosshair (the mouse can aim the ship).
func _screen_changed(in_play: bool) -> void:
	Input.set_default_cursor_shape(Input.CURSOR_CROSS if in_play else Input.CURSOR_ARROW)


## Virtual joystick (left half) and hyperspace button, on touch screens only.
func _draw_touch_overlay() -> void:
	if not playing or game.paused:
		return
	var c := Color(1, 1, 1, 0.5)
	if game.touch_stick_origin != null:
		var o: Vector2 = game.touch_stick_origin
		touch_overlay.draw_circle(o, 90.0, Color(1, 1, 1, 0.08), true, -1.0, true)
		touch_overlay.draw_arc(o, 90.0, 0, TAU, 48, Color(1, 1, 1, 0.3), 2.0, true)
		touch_overlay.draw_circle(o + game.touch_stick_vec, 32.0, Color(1, 1, 1, 0.3), true, -1.0, true)
	else:
		touch_overlay.draw_arc(Vector2(170, 560), 90.0, 0, TAU, 48, Color(1, 1, 1, 0.12), 2.0, true)
	var h := AsteroidsGame.HYPER_BUTTON
	touch_overlay.draw_circle(h, AsteroidsGame.HYPER_BUTTON_R, Color(1, 1, 1, 0.08), true, -1.0, true)
	touch_overlay.draw_arc(h, AsteroidsGame.HYPER_BUTTON_R, 0, TAU, 48, Color(1, 1, 1, 0.3), 2.0, true)
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(I18n.t("HYPER"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	touch_overlay.draw_string(font, h + Vector2(-w / 2, 6), I18n.t("HYPER"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, c)
	if game.touch_firing:
		touch_overlay.draw_circle(Vector2(980, 560), 70.0, Color(1, 1, 1, 0.1), true, -1.0, true)

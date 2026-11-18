extends SceneTree
## Headless test suite, with no add-ons:
##     godot --headless --path . -s res://tests/run_tests.gd
## The exit code is the number of failed checks (0 = all passed). The tests use their own
## settings file, so the player's preferences are never touched.

const LAUNCHER := preload("res://core/main.gd")

var _checks := 0
var _failed := 0
var _section := ""


func _initialize() -> void:
	Settings.use_file("user://test_settings.cfg")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_settings.cfg"))
	_run.call_deferred()


func _run() -> void:
	_test_settings()
	_test_i18n()
	_test_registry()
	_test_synth()
	_test_cycle_button()
	_test_pong_rules()
	await _test_games()
	print("\n%d checks, %d failed" % [_checks, _failed])
	quit(_failed)


# ---------------------------------------------------------------- helpers

func _begin(name: String) -> void:
	_section = name
	print("- ", name)


func check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failed += 1
		printerr("  FAIL [%s] %s" % [_section, what])


func check_eq(got: Variant, expected: Variant, what: String) -> void:
	check(got == expected, "%s: got %s, expected %s" % [what, got, expected])


func _frames(n: int) -> void:
	for i in n:
		await process_frame


# ---------------------------------------------------------------- tests

func _test_settings() -> void:
	_begin("settings")
	Settings.set_value("t", "int", 3)
	Settings.set_value("t", "float", 2.0)
	Settings.set_value("t", "text", "abc")
	Settings.set_value("t", "big", 99)
	check_eq(Settings.get_int("t", "int", 0), 3, "int")
	check_eq(Settings.get_int("t", "float", 0), 2, "whole float")
	check_eq(Settings.get_int("t", "text", 7), 7, "text falls back to default")
	check_eq(Settings.get_int("t", "missing", 5), 5, "missing key")
	check_eq(Settings.get_index("t", "big", 1, 3), 1, "out of range index")
	check_eq(Settings.get_index("t", "int", 0, 3), 0, "index == count")
	check_eq(Settings.get_index("t", "float", 0, 3), 2, "valid index")
	check_eq(Settings.get_index("t", "big", 9, 3), 2, "bad default is clamped")
	# survives a reload from disk
	Settings.use_file(Settings.path)
	check_eq(Settings.get_int("t", "int", 0), 3, "saved to disk")


func _test_i18n() -> void:
	_begin("i18n")
	var table: Dictionary = I18n.STRINGS.T
	check(table.size() > 100, "translation table loaded")
	for k: String in table:
		var v: Array = table[k]
		check(v.size() == I18n.LANGS.size() - 1, "entry has one text per other language: %s" % k)
		for s in v:
			check(String(s) != "", "empty translation for: %s" % k)
	var key: String = table.keys()[0]
	for i in range(1, I18n.LANGS.size()):
		I18n.setup(I18n.LANGS[i])
		check_eq(I18n.t(key), String(table[key][i - 1]), "translation to " + I18n.LANGS[i])
	I18n.setup(I18n.LANGS[0])
	check_eq(I18n.t(key), key, "source language returns the key")
	I18n.setup("xx")
	check(I18n.lang in I18n.LANGS, "unknown language falls back")


func _test_registry() -> void:
	_begin("launcher registry")
	var args := {}
	for g: Dictionary in LAUNCHER.GAMES:
		check(not args.has(g.arg), "unique arg " + g.arg)
		args[g.arg] = true
		check(ResourceLoader.exists(g.script), "script exists: " + g.script)
		check(Inspirations.INFO.has(g.arg), "inspiration for " + g.arg)
		var info: Dictionary = Inspirations.INFO.get(g.arg, {})
		for k in ["name", "by", "story", "wiki"]:
			check(info.has(k), "%s has %s" % [g.arg, k])
		for k in info:
			if String(k).begins_with("wiki"):
				check(String(info[k]).begins_with("https://"), "%s %s is https" % [g.arg, k])


func _test_synth() -> void:
	_begin("synth")
	var s := Synth.render(440.0, 0.5, {"wave": "sine", "volume": 2.0})
	check_eq(s.size(), int(0.5 * Synth.RATE), "length")
	var peak := 0.0
	for x in s:
		peak = maxf(peak, absf(x))
	check(peak > 0.5, "has signal")
	var st := Synth.to_stream(s)
	check_eq(st.data.size(), s.size() * 2, "16-bit data")
	check_eq(Synth.mix([Synth.silence(0.1), Synth.silence(0.2)]).size(), int(0.2 * Synth.RATE), "mix length")


func _test_cycle_button() -> void:
	_begin("cycle button")
	var b := CycleButton.new().setup("x", ["a", "b", "c"], 7)
	check_eq(b.index, 2, "initial index clamped")
	b.step(1)
	check_eq(b.index, 0, "wraps forward")
	b.step(-1)
	check_eq(b.index, 2, "wraps backward")
	b.free()


func _test_pong_rules() -> void:
	_begin("pong rules")
	var g := PongGame.new()
	g.mode = PongGame.Mode.VS_HUMAN
	# straight shot: arrives at the same height
	g.ball_pos = Vector2(640, 300)
	g.ball_vel = Vector2(500, 0)
	check(absf(g._predict_y(1) - 300.0) < 0.01, "straight prediction")
	# one bounce off the bottom wall: mirrored around it
	g.ball_pos = Vector2(640, 600)
	g.ball_vel = Vector2(500, 500)
	var t := (g.paddle_x(1) - PongGame.PADDLE_SIZE.x / 2 - PongGame.BALL_SIZE / 2 - 640.0) / 500.0
	var bottom := PongGame.FIELD.y - PongGame.BALL_SIZE / 2
	check(absf(g._predict_y(1) - (2.0 * bottom - (600.0 + 500.0 * t))) < 0.01, "bounce prediction")
	# moving away: no prediction
	g.ball_vel = Vector2(-500, 0)
	check_eq(g._predict_y(1), 600.0, "ball moving away")
	# the match ends at WIN_SCORE
	var winners: Array[int] = []
	g.game_over.connect(func(w: int) -> void: winners.append(w))
	g.reset_match()
	for i in PongGame.WIN_SCORE:
		g._score(0)
	check_eq(g.state, PongGame.State.OVER, "match over")
	check_eq(winners, [0] as Array[int], "winner signalled once")
	g.free()


## Every game: opens, plays, pauses, resumes, reaches game over and goes back to the menu.
func _test_games() -> void:
	for g: Dictionary in LAUNCHER.GAMES:
		_begin("game " + g.arg)
		var shell: GameShell = load(g.script).new()
		var exits := [0]
		root.add_child(shell)
		shell.exit_requested.connect(func() -> void: exits[0] += 1)
		await _frames(20)
		check(shell.menu.root.visible, "menu shown")
		check(not shell.playing, "demo is not a match")
		shell._start_match()
		await _frames(60)
		check(shell.playing, "playing")
		check(not shell.menu.root.visible, "menu hidden while playing")
		shell._set_paused(true)
		check(shell.game.paused and shell.pause_menu.root.visible, "paused")
		shell._set_paused(false)
		check(not shell.game.paused and not shell.pause_menu.root.visible, "resumed")
		shell.go_back()
		check(shell.pause_menu.root.visible, "back button pauses")
		shell.go_back()
		check(shell.menu.root.visible, "back button returns to the menu")
		# a record is kept between sessions
		shell._start_match()
		var before := Settings.get_int(g.arg, "best", 0)
		shell.show_result("T", "S", before + 10)
		check(shell.over_menu.root.visible, "game over shown")
		if shell.tracks_best:
			check_eq(Settings.get_int(g.arg, "best", 0), before + 10, "high score saved")
		# every style can be applied
		for i in shell.skins.size():
			shell.style_idx = i
			shell._apply_style()
			await _frames(3)
		check_eq(Settings.get_int(g.arg, "style", -1), shell.skins.size() - 1, "style saved")
		shell._show_menu()
		shell.go_back()
		check_eq(exits[0], 1, "back from the menu leaves the game")
		shell.queue_free()
		await _frames(5)

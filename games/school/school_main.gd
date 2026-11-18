extends GameShell
## School Trouble: menu (with the demo behind it), messages, pause, game over and style switching.

const SKINS := [
	{"name": "Classic 1985", "script": preload("res://games/school/skins/classic_skin.gd")},
	{"name": "Chalkboard", "script": preload("res://games/school/skins/chalk_skin.gd")},
	{"name": "Cartoon", "script": preload("res://games/school/skins/cartoon_skin.gd")},
]
const STRICT := ["Distracted", "Alert"]


func _init() -> void:
	id = "school"
	skins = SKINS
	default_style = 0
	title = "SCHOOL TROUBLE"
	title_size = 64
	tagline = "1985 style: get your report card from the head's safe without being expelled"
	hint = "← → walk   ·   ↑ ↓ stairs (and ↑ at the safe)   ·   Space: jump   ·   X or J: catapult   ·   Z or K: punch\nTouch: joystick on the left; on the right: top jumps, middle catapult, bottom punch"
	prompt_offset = -240.0
	pause_pos = Vector2(1204, 20)


func _create_game() -> Node:
	var g := SchoolGame.new()
	g.expelled.connect(func() -> void: get_tree().create_timer(3.0).timeout.connect(_on_game_over))
	g.bell.connect(_on_bell)
	g.all_shields.connect(func() -> void:
		say(I18n.t("ALL THE SHIELDS! NOW KNOCK THE TEACHERS DOWN WITH THE CATAPULT TO LEARN THE SECRET"), 4.0))
	g.letter_found.connect(func(i: int, l: String) -> void: say(I18n.t("SAFE LETTER %d: %s") % [i + 1, l], 3.0))
	g.safe_opened.connect(func() -> void: say(I18n.t("YOU GOT THE REPORT CARD! LEVEL %d") % game.level, 4.0))
	return g


func _build_options(box: VBoxContainer) -> void:
	add_option(box, "Teachers", STRICT, "strict")


func _start_demo() -> void:
	game.strict = false
	game.start(SchoolGame.Mode.DEMO)


func _start_play() -> void:
	game.strict = option("strict") == 1
	game.start(SchoolGame.Mode.PLAY)


func _on_bell(p: Dictionary) -> void:
	match String(p.kind):
		"aula":
			say(I18n.t("RING! %s LESSON WITH %s") % [I18n.t(String(SchoolGame.ROOMS[p.room].name)).to_upper(), I18n.t(String(SchoolGame.TEACHERS[int(p.teacher)].name)).to_upper()], 3.0)
		"almoco":
			say(I18n.t("RING! LUNCHTIME IN THE DINING HALL"), 3.0)
		_:
			say(I18n.t("RING! PLAYTIME!"), 2.5)


func _on_game_over() -> void:
	show_result(I18n.t("EXPELLED!"), I18n.t("%d points  ·  level %d  ·  %d school days") % [game.score, game.level, game.day], game.score)

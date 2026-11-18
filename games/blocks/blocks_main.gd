extends GameShell
## Blocks: menu (with the demo behind it), messages, pause, game over and style switching.

const SKINS := [
	{"name": "Classic 1984", "script": preload("res://games/blocks/skins/classic_skin.gd")},
	{"name": "Neon", "script": preload("res://games/blocks/skins/neon_skin.gd")},
	{"name": "Wooden Toy", "script": preload("res://games/blocks/skins/wood_skin.gd")},
]
const LEVELS := [1, 5, 10, 15]
const MUSIC := ["On", "Off"]


func _init() -> void:
	id = "blocks"
	skins = SKINS
	title = "STACK"
	title_size = 70
	tagline = "falling pieces, 1984 style: complete lines to clear them"
	hint = "← → move   ·   ↓ soft drop   ·   Space: hard drop   ·   ↑ or X rotate (Z reverse)   ·   C or Shift hold\nTouch: drag to move or drop, tap to rotate (left side: reverse), quick swipe down drops, up holds"
	prompt_offset = -240.0
	pause_pos = Vector2(1200, 20)


func _ready() -> void:
	super._ready()
	add_task(BlocksMusic.prewarm())


func _create_game() -> Node:
	var g := BlocksGame.new()
	g.game_over.connect(func() -> void:
		if playing:
			get_tree().create_timer(1.6).timeout.connect(_on_game_over))
	return g


func _build_options(box: VBoxContainer) -> void:
	add_option(box, "Starting level", LEVELS, "level")
	var music := add_option(box, "Music", MUSIC, "music")
	music.value_changed.connect(func(i: int) -> void: game.skin.music_on = i == 0)


func _style_applied(_pal: Dictionary) -> void:
	game.skin.music_on = option("music") == 0


func _start_demo() -> void:
	game.start(BlocksGame.Mode.DEMO, 1)


func _start_play() -> void:
	game.start(BlocksGame.Mode.PLAY, LEVELS[option("level")])


func _on_game_over() -> void:
	show_result(I18n.t("GAME OVER"), I18n.t("%d points  ·  %d lines  ·  level %d") % [game.score, game.lines, game.level], game.score)

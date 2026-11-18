class_name BreakoutSkin
extends SkinBase
## Base of the Breakout visual styles: draws the BreakoutGame state in _draw(),
## creates the sounds in _build_sfx() and reacts to the game events.

var game: BreakoutGame


func attach(g: BreakoutGame) -> void:
	game = g
	add_voices(8)
	g.match_started.connect(_on_match_started)
	g.turn_started.connect(_on_turn_started)
	g.served.connect(_on_served)
	g.paddle_hit.connect(_on_paddle_hit)
	g.wall_hit.connect(_on_wall_hit)
	g.brick_broken.connect(_on_brick_broken)
	g.speed_changed.connect(_on_speed_changed)
	g.paddle_shrunk.connect(_on_paddle_shrunk)
	g.ball_lost.connect(_on_ball_lost)
	g.wall_cleared.connect(_on_wall_cleared)
	g.game_over.connect(_on_game_over)
	load_sfx()
	_setup()


## The menu demo is silent.
func _is_silent() -> bool:
	return game == null or game.mode == BreakoutGame.Mode.DEMO


func _process(delta: float) -> void:
	if game == null:
		return
	if not game.paused:
		_tick(delta)
	queue_redraw()


## Score text: 3-digit score, as in the original.
func score_text(score: int) -> String:
	return "%03d" % score


# ---- for the styles to override ----

func _setup() -> void:
	pass


func _tick(_delta: float) -> void:
	pass


func _on_match_started() -> void:
	pass


func _on_turn_started(_player: int) -> void:
	pass


func _on_served() -> void:
	pass


func _on_paddle_hit(_pos: Vector2) -> void:
	play("paddle")


func _on_wall_hit(_pos: Vector2) -> void:
	play("wall")


func _on_brick_broken(row: int, _col: int, _pos: Vector2, _points: int) -> void:
	play("brick%d" % (row / 2))


func _on_speed_changed(_level: int) -> void:
	pass


func _on_paddle_shrunk() -> void:
	pass


func _on_ball_lost(_player: int) -> void:
	play("lose")


func _on_wall_cleared(_player: int) -> void:
	play("clear")


func _on_game_over() -> void:
	pass

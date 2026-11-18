class_name PongSkin
extends SkinBase
## Base of the Pong visual styles. A skin draws the PongGame state in _draw(),
## creates its sounds in _build_sfx() and reacts to the events (hits, points, etc.).
## To create a new style, just extend this class.

var game: PongGame


func attach(g: PongGame) -> void:
	game = g
	add_voices(6)
	g.match_started.connect(_on_match_started)
	g.served.connect(_on_served)
	g.paddle_hit.connect(_on_paddle_hit)
	g.wall_hit.connect(_on_wall_hit)
	g.point_scored.connect(_on_point_scored)
	g.game_over.connect(_on_game_over)
	load_sfx()
	_setup()


## The menu demo is silent.
func _is_silent() -> bool:
	return game == null or game.mode == PongGame.Mode.DEMO


func _process(delta: float) -> void:
	if game == null:
		return
	if not game.paused:
		_tick(delta)
	queue_redraw()


# ---- methods for the styles to override ----

func _setup() -> void:
	pass


func _tick(_delta: float) -> void:
	pass


func _on_match_started() -> void:
	pass


func _on_served() -> void:
	pass


func _on_paddle_hit(_side: int, _pos: Vector2, _rel: float) -> void:
	play("paddle")


func _on_wall_hit(_pos: Vector2) -> void:
	play("wall")


func _on_point_scored(_side: int) -> void:
	play("score")


func _on_game_over(_winner: int) -> void:
	play("win")

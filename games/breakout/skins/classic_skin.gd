extends BreakoutSkin
## Classic 1976: as in the Atari machine, the monitor was black and white and the colours came
## from strips of cellophane stuck on the glass. So everything in a band (ball, walls)
## takes that band's colour, and the paddle is blue.

const WHITE := Color(0.93, 0.93, 0.93)
const DIM := Color(0.42, 0.42, 0.42)
const RED := Color("c84848")
const ORANGE := Color("c66c3a")
const GREEN := Color("48a048")
const YELLOW := Color("a2a22a")
const BLUE := Color("4f63d8")

var bands: Array = []   # [y0, y1, colour]


func _setup() -> void:
	var t := BreakoutGame.BRICK_TOP
	var h := BreakoutGame.BRICK.y * 2
	bands = [
		[t, t + h, RED], [t + h, t + 2 * h, ORANGE],
		[t + 2 * h, t + 3 * h, GREEN], [t + 3 * h, t + 4 * h, YELLOW],
		[BreakoutGame.PADDLE_Y - 34.0, BreakoutGame.PADDLE_Y + 30.0, BLUE],
	]


func _build_sfx() -> void:
	# Square-wave beeps: each brick colour has its own pitch (higher at the top).
	var tones := [880.0, 740.0, 587.0, 494.0]
	for i in 4:
		sfx["brick%d" % i] = Synth.tone(tones[i], 0.05, {"wave": "square", "volume": 0.25})
	sfx.paddle = Synth.tone(330.0, 0.05, {"wave": "square", "volume": 0.25})
	sfx.wall = Synth.tone(220.0, 0.03, {"wave": "square", "volume": 0.22})
	sfx.lose = Synth.tone(240.0, 0.5, {"wave": "square", "freq_end": 70.0, "volume": 0.25})


func _on_wall_cleared(_player: int) -> void:
	pass  # the original had no sound for this


func color_at(y: float) -> Color:
	for b in bands:
		if y >= b[0] and y < b[1]:
			return b[2]
	return WHITE


func _draw() -> void:
	var g := game
	var inner := BreakoutGame.INNER
	var w := BreakoutGame.WALL
	draw_rect(Rect2(Vector2.ZERO, BreakoutGame.SCREEN), Color.BLACK)

	# walls (in slices, so they pick up the colour of the cellophane strips)
	draw_rect(Rect2(inner.position.x - w, inner.position.y - w, inner.size.x + 2 * w, w), WHITE)
	var y := inner.position.y
	while y < BreakoutGame.SCREEN.y:
		var c := color_at(y)
		draw_rect(Rect2(inner.position.x - w, y, w, 8), c)
		draw_rect(Rect2(inner.end.x, y, w, 8), c)
		y += 8.0

	# bricks
	for row in BreakoutGame.ROWS:
		var c: Color = bands[row / 2][2]
		for col in BreakoutGame.COLS:
			if g.brick_alive(row, col):
				var r := g.brick_rect(row, col)
				draw_rect(Rect2(r.position.x + 2, r.position.y + 2, r.size.x - 4, r.size.y - 4), c)

	draw_rect(g.paddle_rect(), BLUE)
	if g.ball_visible():
		draw_rect(g.ball_rect(), color_at(g.ball_pos.y))

	# displays: score (3 digits) and ball number
	var left_x := (inner.position.x - w) / 2
	var right_x := inner.end.x + w + (BreakoutGame.SCREEN.x - inner.end.x - w) / 2
	_draw_player(0, left_x)
	if g.players.size() > 1:
		_draw_player(1, right_x)
	else:
		BlockDigits.draw(self, score_text(g.best), right_x, 48, 10, DIM)


func _draw_player(i: int, cx: float) -> void:
	var p: Dictionary = game.players[i]
	var c := WHITE if (i == game.current or game.players.size() == 1) else DIM
	BlockDigits.draw(self, score_text(p.score), cx, 48, 10, c)
	var ball_no := clampi(game.start_balls - p.balls + 1, 1, game.start_balls)
	if p.balls > 0:
		BlockDigits.draw(self, str(ball_no), cx, 140, 8, c)


func ui_palette() -> Dictionary:
	return {
		"panel": Color(0, 0, 0, 0.92),
		"border": WHITE,
		"text": WHITE,
		"accent": WHITE,
		"button": Color.BLACK,
		"button_hover": Color(1, 1, 1, 0.16),
		"radius": 0,
		"dim": Color(0, 0, 0, 0.45),
	}

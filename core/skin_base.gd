class_name SkinBase
extends Node2D
## Shared base of every visual style ("skin"): a small pool of audio players, the style's
## sounds (built once per session in _build_sfx() and cached by Synth) and play().
## Each game has its own skin base (e.g. PongSkin) that extends this one, keeps a typed
## `game` reference, connects to the game's signals in attach() and draws in _draw().

var sfx := {}
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0


## Creates `count` audio players, so several sounds can overlap.
func add_voices(count: int) -> void:
	for i in count:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


## Loads this style's sounds: from the cache (Synth.prewarm may have built them already)
## or by calling _build_sfx() once.
func load_sfx() -> void:
	var key: String = get_script().resource_path
	var cached: Variant = Synth.cache_get(key)
	if cached != null:
		sfx = cached
	else:
		_build_sfx()
		Synth.cache_set(key, sfx)


## Plays a sound by id (unknown ids are ignored). Silent while _is_silent() is true.
func play(id: String, pitch := 1.0, volume_db := 0.0) -> void:
	if _is_silent() or not sfx.has(id) or _players.is_empty():
		return
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = sfx[id]
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()


## The menu demo is silent; each game's skin base says when it is running.
func _is_silent() -> bool:
	return false


## Builds the sounds into `sfx` (id -> AudioStream). Also called from a worker thread
## by Synth.prewarm(), so it must only create resources (no nodes in the tree).
func _build_sfx() -> void:
	pass


## Colours for the menus of this style (see UI.make_theme).
func ui_palette() -> Dictionary:
	return UI.LAUNCHER_PALETTE

class_name Settings
extends RefCounted
## Preferences saved between sessions (user://settings.cfg), one section per game.
## Values read back are validated: a damaged or hand-edited file never crashes a game.

## File in use; the tests point it elsewhere with use_file().
static var path := "user://settings.cfg"
static var _cfg: ConfigFile


## Switches to another settings file (used by the tests, so they never touch the player's).
static func use_file(p_path: String) -> void:
	path = p_path
	_cfg = null


static func _ensure() -> void:
	if _cfg == null:
		_cfg = ConfigFile.new()
		_cfg.load(path)


static func get_value(section: String, key: String, default: Variant) -> Variant:
	_ensure()
	return _cfg.get_value(section, key, default)


## An integer (ints and whole floats are accepted; anything else gives `default`).
static func get_int(section: String, key: String, default: int) -> int:
	var v: Variant = get_value(section, key, default)
	if v is int:
		return v
	if v is float and is_finite(v) and v == floorf(v):
		return int(v)
	return default


## An index into a list of `count` items; out-of-range values give `default`.
static func get_index(section: String, key: String, default: int, count: int) -> int:
	var i := get_int(section, key, default)
	if i < 0 or i >= count:
		return clampi(default, 0, maxi(count - 1, 0))
	return i


static func set_value(section: String, key: String, value: Variant) -> void:
	_ensure()
	_cfg.set_value(section, key, value)
	_cfg.save(path)

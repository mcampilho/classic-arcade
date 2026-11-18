class_name Synth
extends RefCounted
## Minimal synthesizer: generates sound effects in code (no audio files).
## Each game/style can create its sounds with tone()/render()/mix()/concat().

const RATE := 22050
const WAVES := {"square": 0, "sine": 1, "saw": 2, "triangle": 3, "noise": 4}

# Sounds already generated, per style (synthesis happens only once per session).
static var _cache := {}
static var _mutex := Mutex.new()


static func cache_get(key: String) -> Variant:
	_mutex.lock()
	var v: Variant = _cache.get(key)
	_mutex.unlock()
	return v


static func cache_set(key: String, value: Dictionary) -> void:
	_mutex.lock()
	_cache[key] = value
	_mutex.unlock()


## Generates the sounds of several styles in the background (skin scripts with _build_sfx()),
## so that switching styles in the menu is instant. Returns the task id.
static func prewarm(skin_scripts: Array) -> int:
	return WorkerThreadPool.add_task(func() -> void:
		for script: Script in skin_scripts:
			if cache_get(script.resource_path) != null:
				continue
			var skin: Object = script.new()
			skin._build_sfx()
			cache_set(script.resource_path, skin.sfx)
			skin.free())


## Generates a simple sound, ready to play.
static func tone(freq: float, dur: float, opts := {}) -> AudioStreamWAV:
	return to_stream(render(freq, dur, opts))


## Generates samples (-1..1). Options:
##  wave: "square" | "sine" | "saw" | "triangle" | "noise"
##  volume, freq_end (frequency sweep), decay (exponential decay /s),
##  attack, release (seconds), lowpass (0..1, softens the sound; 1 = no filter)
static func render(freq: float, dur: float, opts := {}) -> PackedFloat32Array:
	var wave: int = WAVES.get(opts.get("wave", "square"), 0)
	var vol: float = opts.get("volume", 0.5)
	var freq_end: float = opts.get("freq_end", freq)
	var decay: float = opts.get("decay", 0.0)
	var attack: float = opts.get("attack", 0.002)
	var release: float = opts.get("release", 0.004)
	var lp: float = opts.get("lowpass", 1.0)
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1972
	var inv_rate := 1.0 / RATE
	var df := (freq_end - freq) / maxf(n - 1, 1)
	var f := freq
	var phase := 0.0
	var y := 0.0
	var env := 1.0
	var env_mul := exp(-decay * inv_rate)        # exponential decay, step by step
	var attack_n := attack * RATE
	var release_n := release * RATE
	for i in n:
		phase += f * inv_rate
		if phase >= 1.0:
			phase -= floorf(phase)
		f += df
		var s := 0.0
		if wave == 0:
			s = 1.0 if phase < 0.5 else -1.0
		elif wave == 1:
			s = sin(phase * TAU)
		elif wave == 2:
			s = phase * 2.0 - 1.0
		elif wave == 3:
			s = 1.0 - 4.0 * absf(phase - 0.5)
		else:
			s = rng.randf_range(-1.0, 1.0)
		y += lp * (s - y)
		var e := env
		if i < attack_n:
			e *= i / attack_n
		var rem := n - i
		if rem < release_n:
			e *= rem / release_n
		out[i] = y * e * vol
		env *= env_mul
	return out


static func silence(dur: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(dur * RATE))
	out.fill(0.0)
	return out


## Mixes several sounds (sample-by-sample sum).
static func mix(parts: Array) -> PackedFloat32Array:
	var size := 0
	for p: PackedFloat32Array in parts:
		size = maxi(size, p.size())
	var out := PackedFloat32Array()
	out.resize(size)
	out.fill(0.0)
	for p: PackedFloat32Array in parts:
		for i in p.size():
			out[i] += p[i]
	return out



## Puts several sounds in sequence.
static func concat(parts: Array) -> AudioStreamWAV:
	var all := PackedFloat32Array()
	for p: PackedFloat32Array in parts:
		all.append_array(p)
	return to_stream(all)


static func to_stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	return s

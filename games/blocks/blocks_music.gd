class_name BlocksMusic
extends RefCounted
## Stack music: "Korobeiniki", a 19th-century Russian folk song (public domain),
## in an original arrangement with three timbres — one per style. Uses the OutRun synthesizer.

const MELODY := [
	"E5 - B4 C5 D5 - C5 B4", "A4 - A4 C5 E5 - D5 C5", "B4 - - C5 D5 - E5 -", "C5 - A4 - A4 - . .",
	". D5 - F5 A5 - G5 F5", "E5 - - C5 E5 - D5 C5", "B4 - B4 C5 D5 - E5 -", "C5 - A4 - A4 - . .",
	"E5 - B4 C5 D5 - C5 B4", "A4 - A4 C5 E5 - D5 C5", "B4 - - C5 D5 - E5 -", "C5 - A4 - A4 - . .",
	". D5 - F5 A5 - G5 F5", "E5 - - C5 E5 - D5 C5", "B4 - B4 C5 D5 - E5 -", "C5 - A4 - A4 - . .",
	"E5 - - - C5 - - -", "D5 - - - B4 - - -", "C5 - - - A4 - - -", "G#4 - - - B4 - - -",
	"E5 - - - C5 - - -", "D5 - - - B4 - - -", "C5 - E5 - A5 - - -", "G#5 - - - - - . .",
]
const CHORDS := "Am Am E Am Dm C E Am Am Am E Am Dm C E Am Am E Am E Am E Am E"

const VARIANTS := [
	{   # 8-bit chip
		"bpm": 144.0, "melody": MELODY, "chords": CHORDS,
		"bass": "0 12 0 12 0 12 0 12", "arp": [0, 1, 2, 1],
		"lead": {"wave": "square", "volume": 0.1, "lowpass": 0.35, "decay": 1.5, "release": 0.02},
		"bass_opts": {"wave": "triangle", "volume": 0.2, "release": 0.02},
		"arp_opts": {"wave": "square", "volume": 0.0, "decay": 12.0},
	},
	{   # synthesizer with drums
		"bpm": 150.0, "melody": MELODY, "chords": CHORDS,
		"bass": "0 . 12 0 . 0 12 .", "arp": [0, 1, 2, 1],
		"kick": "x...x...x...x...", "snare": "....x.......x...", "hat": "..x...x...x...x.",
		"lead": {"wave": "saw", "volume": 0.085, "lowpass": 0.25, "decay": 1.2, "release": 0.03},
		"bass_opts": {"wave": "saw", "volume": 0.15, "lowpass": 0.07, "decay": 4.0, "release": 0.02},
		"arp_opts": {"wave": "square", "volume": 0.025, "lowpass": 0.2, "decay": 14.0},
	},
	{   # music box
		"bpm": 120.0, "melody": MELODY, "chords": CHORDS,
		"bass": "0 - - - 7 - - -", "arp": [0, 1, 2, 1],
		"lead": {"wave": "sine", "volume": 0.22, "decay": 3.5, "release": 0.05},
		"bass_opts": {"wave": "triangle", "volume": 0.14, "decay": 2.0, "release": 0.05},
		"arp_opts": {"wave": "sine", "volume": 0.04, "decay": 8.0},
	},
]


static func cache_key(i: int) -> String:
	return "blocks_song_%d" % i


static func stream(i: int) -> AudioStreamWAV:
	var d: Variant = Synth.cache_get(cache_key(i))
	if d == null:
		return null
	return (d as Dictionary).stream


static func prewarm() -> int:
	return WorkerThreadPool.add_task(func() -> void:
		for i in VARIANTS.size():
			if Synth.cache_get(cache_key(i)) == null:
				Synth.cache_set(cache_key(i), {"stream": OutRunMusic.build_song(VARIANTS[i])}))

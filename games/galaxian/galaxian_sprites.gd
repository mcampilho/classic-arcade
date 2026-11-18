class_name GalaxianSprites
extends RefCounted
## Original (multicolour) drawings for Galaxian. Letters = palette colours of each kind.

## Kinds: 0 flagship, 1 escort (red), 2 emissary (purple), 3 drone (blue)
const ALIEN := [
	[   # wings down
		"..C.....C..",
		"...C...C...",
		"..BBBBBBB..",
		".BBYYBYYBB.",
		"BBBBBBBBBBB",
		"B.CCBBBCC.B",
		"B..B...B..B",
		"...C...C...",
	],
	[   # wings up
		"..C.....C..",
		"...C...C...",
		"B.BBBBBBB.B",
		"BBBYYBYYBBB",
		".BBBBBBBBB.",
		"..CCBBBCC..",
		"...B...B...",
		"..C.....C..",
	],
]

const FLAGSHIP := [
	[
		"......Y......",
		".....YYY.....",
		"..R..YYY..R..",
		".RR.YYYYY.RR.",
		"RRRYYRYRYYRRR",
		"RRYYYYYYYYYRR",
		".R.YYYYYYY.R.",
		"...Y.YYY.Y...",
		"..Y...Y...Y..",
		".Y.........Y.",
	],
	[
		"......Y......",
		".....YYY.....",
		".R...YYY...R.",
		"RR..YYYYY..RR",
		"RRRYYRYRYYRRR",
		".RYYYYYYYYYR.",
		"..RYYYYYYYR..",
		"...Y.YYY.Y...",
		"...Y..Y..Y...",
		"..Y.......Y..",
	],
]

const PLAYER := [
	"......W......",
	"......W......",
	".....RWR.....",
	".....WWW.....",
	"..R..WWW..R..",
	"..W.WWBWW.W..",
	".WWWWBBBWWWW.",
	"WWWWWWBWWWWWW",
	"WW.RR.W.RR.WW",
	"W..R.....R..W",
]

const BOOM := [
	["....Y....", "..Y.R.Y..", "...RRR...", "YRRWWWRRY", "...RRR...", "..Y.R.Y..", "....Y...."],
	["Y...R...Y", ".R..Y..R.", "...W.W...", "RY.....YR", "...W.W...", ".R..Y..R.", "Y...R...Y"],
]

const PALETTES := [
	{"R": Color("e03131"), "Y": Color("ffd43b"), "B": Color("ffd43b"), "C": Color("e03131")},   # flagship
	{"B": Color("e03131"), "C": Color("ffd43b"), "Y": Color("f8f9fa")},                         # escort
	{"B": Color("ae3ec9"), "C": Color("f06595"), "Y": Color("f8f9fa")},                         # emissary
	{"B": Color("1c7ed6"), "C": Color("3bc9db"), "Y": Color("ffe066")},                         # drone
]
const PLAYER_PALETTE := {"W": Color("f1f3f5"), "R": Color("f03e3e"), "B": Color("339af0")}
const BOOM_PALETTE := {"Y": Color("ffd43b"), "R": Color("ff6b6b"), "W": Color("ffffff")}


static func frame(kind: int, f: int) -> Array:
	return FLAGSHIP[f] if kind == 0 else ALIEN[f]

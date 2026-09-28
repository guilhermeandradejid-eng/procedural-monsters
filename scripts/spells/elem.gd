class_name Elem
extends RefCounted
## Essences, their fusions and their colours.
## "arcane" is raw ink magic: what a sentence produces with no essence at all.

const BASE: Array[String] = ["ember", "frost", "storm", "void", "venom", "radiant"]

const FUSIONS := {
	"ember+frost": "steam",
	"ember+storm": "plasma",
	"ember+void": "blackflame",
	"ember+venom": "brimstone",
	"ember+radiant": "solar",
	"frost+storm": "crystal",
	"frost+void": "entropy",
	"frost+venom": "miasma",
	"frost+radiant": "prism",
	"storm+void": "rift",
	"storm+venom": "neurotoxin",
	"storm+radiant": "judgement",
	"void+venom": "blight",
	"void+radiant": "eclipse",
	"venom+radiant": "sap",
}

## core = hottest centre, main = body colour, dark = edges/smoke, rim = fresnel accent.
const PALETTES := {
	"arcane": {"core": Color("fff4d6"), "main": Color("e0b867"), "dark": Color("2a1d17"), "rim": Color("ffd98a")},
	"ember": {"core": Color("fff1c1"), "main": Color("ff7a1f"), "dark": Color("a8230e"), "rim": Color("ffc15a")},
	"frost": {"core": Color("f4ffff"), "main": Color("7fe3ff"), "dark": Color("2a5fc4"), "rim": Color("d8fbff")},
	"storm": {"core": Color("ffffff"), "main": Color("ffe94d"), "dark": Color("7a4cff"), "rim": Color("fff7b8")},
	"void": {"core": Color("ffb3fa"), "main": Color("9b4dff"), "dark": Color("16052b"), "rim": Color("ff7af0")},
	"venom": {"core": Color("efffb8"), "main": Color("86f04a"), "dark": Color("3b6e1f"), "rim": Color("c77dff")},
	"radiant": {"core": Color("ffffff"), "main": Color("ffe9a3"), "dark": Color("d9962e"), "rim": Color("fffbe6")},
	"steam": {"core": Color("ffffff"), "main": Color("e9e4dc"), "dark": Color("7f9fb3"), "rim": Color("ffb27a")},
	"plasma": {"core": Color("ffffff"), "main": Color("ff4fc8"), "dark": Color("ff7a1f"), "rim": Color("ffd0f2")},
	"blackflame": {"core": Color("ffb36b"), "main": Color("3a0a18"), "dark": Color("0a0306"), "rim": Color("ff4a2a")},
	"brimstone": {"core": Color("fffbd0"), "main": Color("d8f23a"), "dark": Color("b3470f"), "rim": Color("ffe36a")},
	"solar": {"core": Color("ffffff"), "main": Color("ffc53a"), "dark": Color("ff5e1a"), "rim": Color("fff0b0")},
	"crystal": {"core": Color("ffffff"), "main": Color("b9a6ff"), "dark": Color("4a6dff"), "rim": Color("e6ddff")},
	"entropy": {"core": Color("d9f4ff"), "main": Color("5566ff"), "dark": Color("0b0b2a"), "rim": Color("9ad0ff")},
	"miasma": {"core": Color("e0fff0"), "main": Color("6fe0b0"), "dark": Color("234d40"), "rim": Color("b9ffd9")},
	"prism": {"core": Color("ffffff"), "main": Color("bff6ff"), "dark": Color("ff7ad9"), "rim": Color("fff6a0")},
	"rift": {"core": Color("fff27a"), "main": Color("c03cff"), "dark": Color("22073d"), "rim": Color("ffe25a")},
	"neurotoxin": {"core": Color("ffffff"), "main": Color("c8ff1a"), "dark": Color("4a1a8a"), "rim": Color("e9ff9a")},
	"judgement": {"core": Color("ffffff"), "main": Color("fff2a8"), "dark": Color("c98a1a"), "rim": Color("ffffff")},
	"blight": {"core": Color("c6ff7a"), "main": Color("7a3fb3"), "dark": Color("141f08"), "rim": Color("b6ff6a")},
	"eclipse": {"core": Color("ffe7a0"), "main": Color("ffcf5a"), "dark": Color("120824"), "rim": Color("ff9a3a")},
	"sap": {"core": Color("fffde0"), "main": Color("a8ff8a"), "dark": Color("2f8a3a"), "rim": Color("fff09a")},
}

## Particle personality of each base essence (fusions mix both parents).
const MOTES := {
	"arcane": "ink",
	"ember": "flame",
	"frost": "shard",
	"storm": "spark",
	"void": "implode",
	"venom": "bubble",
	"radiant": "twinkle",
}


## Turns the ordered list of essence glyphs of a clause into its resolved element.
static func resolve(essences: Array) -> Dictionary:
	var distinct: Array[String] = []
	for e in essences:
		if not distinct.has(e):
			distinct.append(e)
	if distinct.is_empty():
		return {"key": "arcane", "parts": [], "intensity": 0}
	if distinct.size() == 1:
		return {"key": distinct[0], "parts": [distinct[0]], "intensity": essences.size()}
	var a: String = distinct[0]
	var b: String = distinct[1]
	if BASE.find(a) > BASE.find(b):
		var t := a
		a = b
		b = t
	return {"key": FUSIONS["%s+%s" % [a, b]], "parts": [a, b], "intensity": essences.size()}


static func is_fusion(key: String) -> bool:
	return not BASE.has(key) and key != "arcane"


static func parts_of(key: String) -> Array[String]:
	if BASE.has(key):
		return [key]
	for pair in FUSIONS:
		if FUSIONS[pair] == key:
			var s: PackedStringArray = pair.split("+")
			return [s[0], s[1]]
	return []


static func palette(key: String) -> Dictionary:
	return PALETTES.get(key, PALETTES["arcane"])


static func main_color(key: String) -> Color:
	return palette(key)["main"]


static func has_part(key: String, base: String) -> bool:
	return key == base or parts_of(key).has(base)


static func motes(key: String) -> Array[String]:
	var out: Array[String] = []
	var parts := parts_of(key)
	if parts.is_empty():
		out.append(MOTES["arcane"])
	for p in parts:
		out.append(MOTES[p])
	return out


static func display_name(key: String) -> String:
	return TranslationServer.translate("E_%s" % key.to_upper())

class_name GlyphDB
extends RefCounted
## Every glyph a knight can ink into a grimoire page.
## Glyphs are read left to right like words in a sentence:
##   FORM (noun) · ESSENCE (adjective) · INFLECTION (adverb) · LINK (conjunction)

enum Type { FORM, ESSENCE, INFLECTION, LINK }

## Rarity drives drop weights and shop prices.
enum Rarity { COMMON, UNCOMMON, RARE }

## How a form is aimed.
enum Aim { DIRECTION, POINT, SELF }

const FORMS := {
	"bolt": {"dmg": 12.0, "cd": 0.55, "speed": 24.0, "life": 0.85, "radius": 0.32, "aim": Aim.DIRECTION, "anim": "cast_thrust", "gender": "m", "rarity": Rarity.COMMON, "kind": "projectile"},
	"orb": {"dmg": 5.0, "cd": 1.7, "speed": 7.5, "life": 2.4, "radius": 0.85, "aim": Aim.DIRECTION, "anim": "cast_thrust", "gender": "m", "rarity": Rarity.COMMON, "kind": "projectile"},
	"nova": {"dmg": 20.0, "cd": 2.0, "radius": 3.8, "aim": Aim.SELF, "anim": "cast_slam", "gender": "f", "rarity": Rarity.COMMON, "kind": "burst"},
	"lance": {"dmg": 17.0, "cd": 1.15, "length": 11.0, "radius": 0.45, "aim": Aim.DIRECTION, "anim": "cast_thrust", "gender": "f", "rarity": Rarity.COMMON, "kind": "line"},
	"wave": {"dmg": 13.0, "cd": 1.25, "speed": 13.0, "life": 0.6, "radius": 1.6, "aim": Aim.DIRECTION, "anim": "cast_sweep", "gender": "f", "rarity": Rarity.COMMON, "kind": "projectile"},
	"rain": {"dmg": 8.0, "cd": 2.8, "radius": 2.6, "count": 6, "aim": Aim.POINT, "range": 9.0, "anim": "cast_raise", "gender": "f", "rarity": Rarity.UNCOMMON, "kind": "point"},
	"orbit": {"dmg": 7.0, "cd": 6.0, "radius": 2.2, "count": 3, "life": 4.0, "aim": Aim.SELF, "anim": "cast_spin", "gender": "m", "rarity": Rarity.UNCOMMON, "kind": "aura"},
	"mine": {"dmg": 28.0, "cd": 1.8, "radius": 2.6, "life": 6.0, "aim": Aim.POINT, "range": 7.0, "anim": "cast_slam", "gender": "f", "rarity": Rarity.COMMON, "kind": "point"},
	"chakram": {"dmg": 10.0, "cd": 1.4, "speed": 20.0, "life": 1.3, "radius": 0.6, "range": 8.0, "aim": Aim.DIRECTION, "anim": "cast_spin", "gender": "m", "rarity": Rarity.COMMON, "kind": "projectile"},
	"meteor": {"dmg": 42.0, "cd": 3.4, "radius": 3.2, "delay": 0.7, "aim": Aim.POINT, "range": 10.0, "anim": "cast_raise", "gender": "m", "rarity": Rarity.RARE, "kind": "point"},
	"vortex": {"dmg": 4.0, "cd": 5.0, "radius": 4.0, "life": 2.2, "aim": Aim.POINT, "range": 8.0, "anim": "cast_thrust", "gender": "m", "rarity": Rarity.RARE, "kind": "point"},
	"totem": {"dmg": 6.0, "cd": 7.0, "radius": 10.0, "life": 6.0, "rate": 0.7, "aim": Aim.SELF, "anim": "cast_raise", "gender": "f", "rarity": Rarity.UNCOMMON, "kind": "aura"},
	"serpent": {"dmg": 7.0, "cd": 2.2, "speed": 11.0, "life": 2.2, "radius": 0.5, "count": 6, "aim": Aim.DIRECTION, "anim": "cast_sweep", "gender": "f", "rarity": Rarity.UNCOMMON, "kind": "projectile"},
	"blink": {"dmg": 9.0, "cd": 2.6, "radius": 1.8, "range": 6.5, "aim": Aim.DIRECTION, "anim": "cast_blink", "gender": "m", "rarity": Rarity.UNCOMMON, "kind": "self"},
}

const ESSENCES := {
	"ember": {"rarity": Rarity.COMMON},
	"frost": {"rarity": Rarity.COMMON},
	"storm": {"rarity": Rarity.COMMON},
	"void": {"rarity": Rarity.UNCOMMON},
	"venom": {"rarity": Rarity.UNCOMMON},
	"radiant": {"rarity": Rarity.UNCOMMON},
}

## Inflections: multiplicative tweaks. cd = cooldown multiplier per stack.
const INFLECTIONS := {
	"split": {"cd": 1.14, "rarity": Rarity.COMMON},
	"echo": {"cd": 1.28, "rarity": Rarity.UNCOMMON},
	"seek": {"cd": 1.06, "rarity": Rarity.COMMON},
	"pierce": {"cd": 1.05, "rarity": Rarity.COMMON},
	"bounce": {"cd": 1.06, "rarity": Rarity.COMMON},
	"grow": {"cd": 1.2, "rarity": Rarity.COMMON},
	"swift": {"cd": 0.82, "rarity": Rarity.COMMON},
	"volatile": {"cd": 1.12, "rarity": Rarity.UNCOMMON},
	"linger": {"cd": 1.12, "rarity": Rarity.UNCOMMON},
	"twin": {"cd": 1.15, "rarity": Rarity.UNCOMMON},
	"spiral": {"cd": 1.05, "rarity": Rarity.UNCOMMON},
	"delay": {"cd": 1.0, "rarity": Rarity.COMMON},
	"leech": {"cd": 1.1, "rarity": Rarity.RARE},
	"heavy": {"cd": 1.08, "rarity": Rarity.COMMON},
	"sharpen": {"cd": 1.04, "rarity": Rarity.UNCOMMON},
	"magnet": {"cd": 1.08, "rarity": Rarity.UNCOMMON},
	"chain": {"cd": 1.12, "rarity": Rarity.UNCOMMON},
	"ward": {"cd": 1.15, "rarity": Rarity.RARE},
}

## Links split a sentence: what follows becomes a payload fired by the event.
## power = damage multiplier applied to the payload (on top of depth falloff).
const LINKS := {
	"on_hit": {"power": 0.8, "rarity": Rarity.UNCOMMON, "cd_share": 0.4},
	"on_end": {"power": 1.0, "rarity": Rarity.COMMON, "cd_share": 0.45},
	"on_kill": {"power": 1.25, "rarity": Rarity.UNCOMMON, "cd_share": 0.3},
	"pulse": {"power": 0.5, "rarity": Rarity.RARE, "cd_share": 0.55},
	"then": {"power": 0.9, "rarity": Rarity.COMMON, "cd_share": 0.6},
}

const MAX_DEPTH := 3


static func type_of(id: String) -> int:
	if FORMS.has(id):
		return Type.FORM
	if ESSENCES.has(id):
		return Type.ESSENCE
	if INFLECTIONS.has(id):
		return Type.INFLECTION
	if LINKS.has(id):
		return Type.LINK
	return -1


static func exists(id: String) -> bool:
	return type_of(id) != -1


static func rarity_of(id: String) -> int:
	for table in [FORMS, ESSENCES, INFLECTIONS, LINKS]:
		if table.has(id):
			return int(table[id].get("rarity", Rarity.COMMON))
	return Rarity.COMMON


static func all_ids() -> Array[String]:
	var out: Array[String] = []
	for table in [FORMS, ESSENCES, INFLECTIONS, LINKS]:
		for k in table:
			out.append(k)
	return out


## Glyphs available in the loot pool on a fresh save; the rest unlock via the Candelabrum.
static func starting_pool() -> Array:
	return [
		"bolt", "orb", "nova", "lance", "wave", "mine", "chakram", "rain", "serpent",
		"ember", "frost", "storm", "venom",
		"split", "seek", "pierce", "bounce", "grow", "swift", "delay", "heavy", "echo", "volatile", "twin",
		"on_hit", "on_end", "then",
	]


static func glyph_name(id: String) -> String:
	return TranslationServer.translate("G_%s" % id.to_upper())


static func glyph_desc(id: String) -> String:
	return TranslationServer.translate("G_%s_DESC" % id.to_upper())


static func type_name(t: int) -> String:
	match t:
		Type.FORM:
			return TranslationServer.translate("GT_FORM")
		Type.ESSENCE:
			return TranslationServer.translate("GT_ESSENCE")
		Type.INFLECTION:
			return TranslationServer.translate("GT_INFLECTION")
		Type.LINK:
			return TranslationServer.translate("GT_LINK")
	return ""


static func price(id: String) -> int:
	return [40, 70, 110][rarity_of(id)]

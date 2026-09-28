class_name SpellNamer
extends RefCounted
## Procedural names and sentences for spells, in Brazilian Portuguese (with
## gender agreement) and English. Synonyms are picked from the spell seed, so
## the same page always gets the same name.

# --- Portuguese ------------------------------------------------------------------
## form -> [[noun, gender], ...]
const NOUNS_PT := {
	"bolt": [["Dardo", "m"], ["Agulha", "f"], ["Seta", "f"], ["Farpa", "f"]],
	"orb": [["Orbe", "m"], ["Esfera", "f"], ["Globo", "m"]],
	"nova": [["Nova", "f"], ["Eclosão", "f"], ["Explosão", "f"]],
	"lance": [["Lança", "f"], ["Raio", "m"], ["Estocada", "f"]],
	"wave": [["Onda", "f"], ["Crescente", "m"], ["Vaga", "f"]],
	"rain": [["Chuva", "f"], ["Garoa", "f"], ["Aguaceiro", "m"]],
	"orbit": [["Coroa", "f"], ["Halo", "m"], ["Órbita", "f"]],
	"mine": [["Runa", "f"], ["Armadilha", "f"], ["Selo", "m"]],
	"chakram": [["Chakram", "m"], ["Disco", "m"], ["Aro", "m"]],
	"meteor": [["Meteoro", "m"], ["Cometa", "m"], ["Astro", "m"]],
	"vortex": [["Vórtice", "m"], ["Redemoinho", "m"], ["Voragem", "f"]],
	"totem": [["Sentinela", "f"], ["Vigia", "f"], ["Obelisco", "m"]],
	"serpent": [["Serpente", "f"], ["Víbora", "f"], ["Enguia", "f"]],
	"blink": [["Passo", "m"], ["Salto", "m"], ["Travessia", "f"]],
}
## element -> [[masc, fem], ...]
const ADJ_PT := {
	"arcane": [["Arcano", "Arcana"], ["Rúnico", "Rúnica"], ["de Nanquim", "de Nanquim"]],
	"ember": [["Ígneo", "Ígnea"], ["Ardente", "Ardente"], ["Rubro", "Rubra"]],
	"frost": [["Gélido", "Gélida"], ["Glacial", "Glacial"], ["Álgido", "Álgida"]],
	"storm": [["Voltaico", "Voltaica"], ["Trovejante", "Trovejante"], ["Fulgurante", "Fulgurante"]],
	"void": [["Abissal", "Abissal"], ["Umbral", "Umbral"], ["Oco", "Oca"]],
	"venom": [["Peçonhento", "Peçonhenta"], ["Venenoso", "Venenosa"], ["Tóxico", "Tóxica"]],
	"radiant": [["Radiante", "Radiante"], ["Áureo", "Áurea"], ["Luminoso", "Luminosa"]],
	"steam": [["Escaldante", "Escaldante"], ["Vaporoso", "Vaporosa"]],
	"plasma": [["Plasmático", "Plasmática"], ["Incandescente", "Incandescente"]],
	"blackflame": [["Fuliginoso", "Fuliginosa"], ["de Chama Negra", "de Chama Negra"]],
	"brimstone": [["Sulfúreo", "Sulfúrea"], ["Sulfuroso", "Sulfurosa"]],
	"solar": [["Solar", "Solar"], ["Helíaco", "Helíaca"]],
	"crystal": [["Cristalino", "Cristalina"], ["Facetado", "Facetada"]],
	"entropy": [["Entrópico", "Entrópica"], ["Estático", "Estática"]],
	"miasma": [["Miasmático", "Miasmática"], ["Pútrido", "Pútrida"]],
	"prism": [["Prismático", "Prismática"], ["Iridescente", "Iridescente"]],
	"rift": [["Fendido", "Fendida"], ["Dimensional", "Dimensional"]],
	"neurotoxin": [["Neurotóxico", "Neurotóxica"], ["Paralisante", "Paralisante"]],
	"judgement": [["Justiceiro", "Justiceira"], ["Celestial", "Celestial"]],
	"blight": [["Pestilento", "Pestilenta"], ["Carcomido", "Carcomida"]],
	"eclipse": [["Eclíptico", "Eclíptica"], ["Crepuscular", "Crepuscular"]],
	"sap": [["Seivoso", "Seivosa"], ["Verdejante", "Verdejante"]],
}
const INTENSE_PT := {
	"ember": ["Infernal", "Infernal"], "frost": ["Hibernal", "Hibernal"],
	"storm": ["Tonitruante", "Tonitruante"], "void": ["Insondável", "Insondável"],
	"venom": ["Letal", "Letal"], "radiant": ["Sagrado", "Sagrada"],
}
const MOD_PT := {
	"split": ["Bifurcado", "Bifurcada"], "echo": ["Ecoante", "Ecoante"],
	"seek": ["Faminto", "Faminta"], "pierce": ["Perfurante", "Perfurante"],
	"bounce": ["Saltitante", "Saltitante"], "grow": ["Colossal", "Colossal"],
	"swift": ["Célere", "Célere"], "volatile": ["Instável", "Instável"],
	"linger": ["Persistente", "Persistente"], "twin": ["Gêmeo", "Gêmea"],
	"spiral": ["Rodopiante", "Rodopiante"], "delay": ["Paciente", "Paciente"],
	"leech": ["Vampírico", "Vampírica"], "heavy": ["Esmagador", "Esmagadora"],
	"sharpen": ["Afiado", "Afiada"], "magnet": ["Magnético", "Magnética"],
	"chain": ["Encadeado", "Encadeada"], "ward": ["Guardião", "Guardiã"],
}
const ESSENCE_NOUN_PT := {
	"arcane": "Nanquim", "ember": "Brasa", "frost": "Geada", "storm": "Tempestade",
	"void": "Vazio", "venom": "Peçonha", "radiant": "Aurora", "steam": "Vapor",
	"plasma": "Plasma", "blackflame": "Chama Negra", "brimstone": "Enxofre", "solar": "Sol",
	"crystal": "Cristal", "entropy": "Entropia", "miasma": "Miasma", "prism": "Prisma",
	"rift": "Fenda", "neurotoxin": "Neurotoxina", "judgement": "Juízo", "blight": "Praga",
	"eclipse": "Eclipse", "sap": "Seiva",
}
const LINK_PT := {
	"on_hit": "que, ao tocar, desperta",
	"on_end": "que, ao findar, se torna",
	"on_kill": "que, ao abater, liberta",
	"pulse": "que pulsa, conjurando",
	"then": "e então",
}

# --- English ---------------------------------------------------------------------
const NOUNS_EN := {
	"bolt": ["Bolt", "Needle", "Dart", "Shard"], "orb": ["Orb", "Sphere", "Globe"],
	"nova": ["Nova", "Burst", "Bloom"], "lance": ["Lance", "Ray", "Spear"],
	"wave": ["Wave", "Crescent", "Tide"], "rain": ["Rain", "Downpour", "Hail"],
	"orbit": ["Halo", "Crown", "Orbit"], "mine": ["Rune", "Snare", "Seal"],
	"chakram": ["Chakram", "Disc", "Ring"], "meteor": ["Meteor", "Comet", "Star"],
	"vortex": ["Vortex", "Maelstrom", "Whirl"], "totem": ["Sentinel", "Warden", "Obelisk"],
	"serpent": ["Serpent", "Viper", "Eel"], "blink": ["Step", "Leap", "Passage"],
}
const ADJ_EN := {
	"arcane": ["Arcane", "Runic", "Inked"], "ember": ["Fiery", "Burning", "Crimson"],
	"frost": ["Frozen", "Glacial", "Rime"], "storm": ["Voltaic", "Thundering", "Fulgent"],
	"void": ["Abyssal", "Umbral", "Hollow"], "venom": ["Venomous", "Toxic", "Viperous"],
	"radiant": ["Radiant", "Golden", "Luminous"], "steam": ["Scalding", "Vaporous"],
	"plasma": ["Plasmic", "Incandescent"], "blackflame": ["Blackflame", "Sooty"],
	"brimstone": ["Sulphurous", "Brimstone"], "solar": ["Solar", "Heliac"],
	"crystal": ["Crystalline", "Faceted"], "entropy": ["Entropic", "Stilled"],
	"miasma": ["Miasmic", "Putrid"], "prism": ["Prismatic", "Iridescent"],
	"rift": ["Riven", "Rifting"], "neurotoxin": ["Neurotoxic", "Numbing"],
	"judgement": ["Judging", "Celestial"], "blight": ["Blighted", "Pestilent"],
	"eclipse": ["Eclipsed", "Twilight"], "sap": ["Verdant", "Sapful"],
}
const INTENSE_EN := {
	"ember": "Infernal", "frost": "Hibernal", "storm": "Tempestuous",
	"void": "Unfathomable", "venom": "Lethal", "radiant": "Hallowed",
}
const MOD_EN := {
	"split": "Forked", "echo": "Echoing", "seek": "Hungry", "pierce": "Piercing",
	"bounce": "Ricocheting", "grow": "Colossal", "swift": "Swift", "volatile": "Volatile",
	"linger": "Lingering", "twin": "Twin", "spiral": "Spiraling", "delay": "Patient",
	"leech": "Vampiric", "heavy": "Crushing", "sharpen": "Keen", "magnet": "Magnetic",
	"chain": "Chained", "ward": "Warding",
}
const ESSENCE_NOUN_EN := {
	"arcane": "Ink", "ember": "Ember", "frost": "Frost", "storm": "Storm", "void": "Void",
	"venom": "Venom", "radiant": "Aurora", "steam": "Steam", "plasma": "Plasma",
	"blackflame": "Blackflame", "brimstone": "Brimstone", "solar": "Sun", "crystal": "Crystal",
	"entropy": "Entropy", "miasma": "Miasma", "prism": "Prism", "rift": "Rift",
	"neurotoxin": "Neurotoxin", "judgement": "Judgement", "blight": "Blight",
	"eclipse": "Eclipse", "sap": "Sap",
}
const LINK_EN := {
	"on_hit": "that on hit awakens",
	"on_end": "that on fading becomes",
	"on_kill": "that on a kill releases",
	"pulse": "that pulses, casting",
	"then": "and then",
}

const ROMAN := ["", "I", "II", "III", "IV", "V"]


static func _pick(arr: Array, seed: int, salt: int) -> Variant:
	return arr[absi(hash(seed + salt * 131)) % arr.size()]


static func _is_pt(locale: String) -> bool:
	return locale.begins_with("pt")


## Returns [noun, gender] for pt or [noun] for en.
static func _noun(form: String, seed: int, pt: bool) -> Array:
	if pt:
		return _pick(NOUNS_PT[form], seed, 1)
	return [_pick(NOUNS_EN[form], seed, 1)]


static func _element_adj(c: SpellClause, gender: String, pt: bool) -> String:
	var key := c.element
	var intense := c.intensity >= 2 and c.element_parts.size() == 1
	if pt:
		if intense and INTENSE_PT.has(key):
			return INTENSE_PT[key][0 if gender == "m" else 1]
		var pair: Array = _pick(ADJ_PT[key], c.seed, 2)
		return pair[0 if gender == "m" else 1]
	if intense and INTENSE_EN.has(key):
		return INTENSE_EN[key]
	return _pick(ADJ_EN[key], c.seed, 2)


## The inflection with the most stacks gives the epithet (ties: first placed).
static func _top_mod(c: SpellClause) -> String:
	var best := ""
	var best_n := 0
	for m in c.mods:
		if int(c.mods[m]) > best_n:
			best = m
			best_n = int(c.mods[m])
	return best


static func clause_title(c: SpellClause, locale: String, with_epithet := true) -> String:
	var pt := _is_pt(locale)
	var form := c.dominant_form()
	var noun := _noun(form, c.seed, pt)
	var gender: String = noun[1] if pt else "m"
	var adj := _element_adj(c, gender, pt)
	var mod := _top_mod(c) if with_epithet else ""
	if pt:
		var s: String = "%s %s" % [noun[0], adj]
		if mod != "":
			s += " " + MOD_PT[mod][0 if gender == "m" else 1]
		return s
	var e := ""
	if mod != "":
		e = MOD_EN[mod] + " "
	return "%s%s %s" % [e, adj, noun[0]]


static func name_program(p: SpellProgram, locale: String) -> String:
	if p == null or p.empty:
		return TranslationServer.translate("SPELL_BLANK")
	var cl := p.clauses()
	var s := clause_title(cl[0], locale)
	if cl.size() > 1:
		var joiner := " de " if _is_pt(locale) else " of "
		s += joiner + clause_title(cl[1], locale, false)
	if cl.size() > 2:
		s += " · " + ROMAN[mini(cl.size(), 5)]
	return s


static func _article(noun: String, gender: String, pt: bool) -> String:
	if pt:
		return "uma" if gender == "f" else "um"
	return "an" if "AEIOU".contains(noun.substr(0, 1).to_upper()) else "a"


## Full readable sentence, used on the grimoire page under the spell name.
static func sentence(p: SpellProgram, locale: String) -> String:
	if p == null or p.empty:
		return TranslationServer.translate("SPELL_BLANK_SENTENCE")
	var pt := _is_pt(locale)
	var parts: PackedStringArray = []
	for c in p.clauses():
		var forms_txt: PackedStringArray = []
		var first_gender := "m"
		for i in c.forms.size():
			var f: String = c.forms[i]
			var noun := _noun(f, c.seed + i, pt)
			var g: String = noun[1] if pt else "m"
			if i == 0:
				first_gender = g
			forms_txt.append("%s %s" % [_article(noun[0], g, pt), noun[0].to_lower()])
		var and_word := " e " if pt else " and "
		var phrase := and_word.join(forms_txt)
		var ess: String = (ESSENCE_NOUN_PT if pt else ESSENCE_NOUN_EN)[c.element]
		phrase += (" de " if pt else " of ") + ess.to_lower()
		if c.intensity >= 2 and c.element_parts.size() == 1:
			phrase += " (×%d)" % c.intensity
		var mods_txt: PackedStringArray = []
		for m in c.mods:
			var w: String = (MOD_PT[m][0 if first_gender == "m" else 1] if pt else MOD_EN[m]).to_lower()
			if int(c.mods[m]) > 1:
				w += " ×%d" % int(c.mods[m])
			mods_txt.append(w)
		if not mods_txt.is_empty():
			phrase += ", " + ", ".join(mods_txt)
		if c.link != "":
			phrase += ", " + (LINK_PT if pt else LINK_EN)[c.link]
		parts.append(phrase)
	var text := " ".join(parts) + "."
	return text.substr(0, 1).to_upper() + text.substr(1)

class_name SpellProgram
extends RefCounted
## A compiled grimoire page. Compiling reads the glyphs as a sentence:
##  - forms, essences and inflections accumulate in the current clause;
##  - a link closes the clause and opens its payload clause;
##  - a clause without a form is completed with an implicit Bolt.

const DEPTH_FALLOFF := 0.65
const MIN_COOLDOWN := 0.3
const MAX_COOLDOWN := 14.0

var glyphs: Array[String] = []
var root: SpellClause = null
var cooldown := 1.0
var seed := 0
var empty := true
## Grammar notes shown in the grimoire: {"kind": String, "index": int}
var notes: Array[Dictionary] = []

var _name_cache := {}


static func compile(source: Array) -> SpellProgram:
	var p := SpellProgram.new()
	for g in source:
		p.glyphs.append(String(g))
	var root := SpellClause.new()
	var cur := root
	var used: Array[String] = []
	for i in p.glyphs.size():
		var id := p.glyphs[i]
		if id == "":
			continue
		var t := GlyphDB.type_of(id)
		match t:
			GlyphDB.Type.FORM:
				if cur.forms.size() >= 3:
					p.notes.append({"kind": "too_many_forms", "index": i})
					continue
				cur.forms.append(id)
			GlyphDB.Type.ESSENCE:
				cur.essences.append(id)
			GlyphDB.Type.INFLECTION:
				cur.mods[id] = int(cur.mods.get(id, 0)) + 1
			GlyphDB.Type.LINK:
				if cur.depth >= GlyphDB.MAX_DEPTH:
					p.notes.append({"kind": "too_deep", "index": i})
					continue
				cur.link = id
				cur.glyph_indices.append(i)
				cur.glyph_ids.append(id)
				used.append(id)
				var nxt := SpellClause.new()
				nxt.depth = cur.depth + 1
				nxt.parent = cur
				cur.child = nxt
				cur = nxt
				continue
			_:
				continue
		cur.glyph_indices.append(i)
		cur.glyph_ids.append(id)
		used.append(id)
	# A link with nothing after it has no payload: drop it.
	if cur != root and cur.is_empty():
		var parent := cur.parent
		p.notes.append({"kind": "dangling_link", "index": parent.glyph_indices[-1] if not parent.glyph_indices.is_empty() else -1})
		parent.link = ""
		parent.child = null
	p.empty = used.is_empty()
	p.root = root
	for c in root.clauses():
		if c.forms.is_empty():
			c.forms.append("bolt")
			c.implicit_form = true
			if not p.empty:
				p.notes.append({"kind": "implicit_form", "index": c.glyph_indices[0] if not c.glyph_indices.is_empty() else -1})
		var r := Elem.resolve(c.essences)
		c.element = r.key
		c.element_parts = r.parts
		c.intensity = r.intensity
	p.seed = ("|".join(used)).hash()
	_assign_power(root, 1.0, p.seed)
	p.cooldown = clampf(_clause_cooldown(root), MIN_COOLDOWN, MAX_COOLDOWN)
	# Parent links were only needed while parsing; dropping them avoids RefCounted cycles.
	for c in root.clauses():
		c.parent = null
	return p


static func _assign_power(c: SpellClause, power: float, seed: int) -> void:
	c.power = power
	c.seed = hash(seed + c.depth * 7919)
	if c.child:
		var link_power: float = GlyphDB.LINKS[c.link].power
		_assign_power(c.child, power * DEPTH_FALLOFF * link_power, seed)


static func _clause_cooldown(c: SpellClause) -> float:
	var base := 0.0
	var extra := 0.0
	for f in c.forms:
		var fcd: float = GlyphDB.FORMS[f].cd
		if fcd > base:
			extra += base
			base = fcd
		else:
			extra += fcd
	var cd := base + extra * 0.4
	for m in c.mods:
		cd *= pow(float(GlyphDB.INFLECTIONS[m].cd), int(c.mods[m]))
	cd *= 1.0 + 0.07 * c.essences.size()
	if c.element_parts.size() > 1:
		cd *= 1.06
	if c.child:
		cd += _clause_cooldown(c.child) * float(GlyphDB.LINKS[c.link].cd_share)
	c.cooldown = cd
	return cd


func clauses() -> Array[SpellClause]:
	return root.clauses() if root else []


func depth() -> int:
	return clauses().size()


func dominant_form() -> String:
	return root.dominant_form() if root else "bolt"


func element() -> String:
	return root.element if root else "arcane"


func has_note(kind: String) -> bool:
	for n in notes:
		if n.kind == kind:
			return true
	return false


## Name in the current language (cached per locale).
func display_name() -> String:
	var loc := TranslationServer.get_locale()
	if not _name_cache.has(loc):
		_name_cache[loc] = SpellNamer.name_program(self, loc)
	return _name_cache[loc]


func sentence() -> String:
	return SpellNamer.sentence(self, TranslationServer.get_locale())


## Damage estimate of the root clause's first instance (for UI only).
func estimate_damage() -> float:
	if root == null:
		return 0.0
	var f: Dictionary = GlyphDB.FORMS[root.dominant_form()]
	var dmg: float = f.dmg * root.power
	dmg *= pow(1.35, root.mod("grow")) * pow(0.9, root.mod("swift")) * pow(1.1, root.mod("heavy"))
	if root.mod("split") > 0:
		dmg *= 0.7
	return dmg

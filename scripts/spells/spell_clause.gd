class_name SpellClause
extends RefCounted
## One "sentence" of a spell: its forms share the same essences and inflections.
## If `link` is set, `child` is the payload fired by that event.

var forms: Array[String] = []
var essences: Array[String] = []
var mods := {}
var link := ""
var child: SpellClause = null
var parent: SpellClause = null
var depth := 0
## Indices of the source glyphs that formed this clause (for UI highlighting).
var glyph_indices: Array[int] = []
## The glyph ids themselves, in reading order (links included).
var glyph_ids: Array[String] = []
var implicit_form := false

# Resolved during compile.
var element := "arcane"
var element_parts: Array = []
var intensity := 0
## Damage multiplier from depth falloff and link type.
var power := 1.0
var cooldown := 0.0
var seed := 0


func mod(id: String) -> int:
	return int(mods.get(id, 0))


func has_mod(id: String) -> bool:
	return mods.has(id)


func dominant_form() -> String:
	return forms[0] if not forms.is_empty() else "bolt"


## Status potency: repeated essences intensify, fused essences share the load.
func potency() -> float:
	if element == "arcane":
		return 0.0
	var p := 1.0 + 0.5 * maxf(0.0, intensity - 1.0)
	if element_parts.size() > 1:
		p *= 0.8
	return p


func is_empty() -> bool:
	return forms.is_empty() and essences.is_empty() and mods.is_empty()


func clauses() -> Array[SpellClause]:
	var out: Array[SpellClause] = []
	var c: SpellClause = self
	while c:
		out.append(c)
		c = c.child
	return out

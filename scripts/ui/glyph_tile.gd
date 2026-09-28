class_name GlyphTile
extends RefCounted
## Draws a glyph as a small inked stamp on a scrap of paper.


static func _scrap(r: Rect2, seed: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		for k in 4:
			var t := float(k) / 4.0
			var p := a.lerp(b, t)
			var n := (b - a).normalized().orthogonal()
			pts.append(p + n * rng.randf_range(-1.6, 1.6))
	return pts


static func draw(ci: CanvasItem, r: Rect2, id: String, state := "", scale := 1.0) -> void:
	if id == "":
		return
	var seed := hash(id)
	var lift := Vector2(0, -5.0 * scale) if state == "hover" else Vector2.ZERO
	var rr := Rect2(r.position + lift, r.size)
	if state == "hover":
		ci.draw_colored_polygon(_scrap(r.grow(1.0), seed) as PackedVector2Array, Color(0, 0, 0, 0.18))
	var paper := Pal.PAPER_LIGHT if state != "ghost" else Color(Pal.PAPER_LIGHT, 0.35)
	var poly := _scrap(rr, seed)
	ci.draw_colored_polygon(poly, paper)
	var t := GlyphDB.type_of(id)
	var tcol := GlyphArt.type_color(t)
	# Corner mark shows the word class at a glance.
	var cm := PackedVector2Array([rr.position, rr.position + Vector2(18, 0) * scale, rr.position + Vector2(0, 18) * scale])
	ci.draw_colored_polygon(cm, _type_mark(t))
	var border := Color(Pal.INK, 0.55 if state != "ghost" else 0.2)
	ci.draw_polyline(poly + PackedVector2Array([poly[0]]), border, 1.4 * scale, true)
	var tex := Fx.icons.for_glyph(id)
	var pad := rr.size.x * 0.14
	var col := GlyphArt.glyph_color(id)
	if state == "ghost":
		col.a = 0.3
	ci.draw_texture_rect(tex, rr.grow(-pad), false, col)
	var rar := GlyphDB.rarity_of(id)
	if rar >= 1:
		var p := rr.end - Vector2(10, 10) * scale
		ci.draw_circle(p, 4.0 * scale, Pal.GOLD if rar == 1 else Color("c08cff"))
		ci.draw_arc(p, 4.0 * scale, 0.0, TAU, 12, Pal.INK, 1.0, true)
	if state == "selected":
		ci.draw_polyline(_scrap(rr.grow(4.0 * scale), seed + 3) + PackedVector2Array([_scrap(rr.grow(4.0 * scale), seed + 3)[0]]), Pal.GOLD, 2.6 * scale, true)


static func _type_mark(t: int) -> Color:
	match t:
		GlyphDB.Type.FORM:
			return Color("3a2a22")
		GlyphDB.Type.ESSENCE:
			return Color("b8452a")
		GlyphDB.Type.INFLECTION:
			return Color("2d6f91")
		GlyphDB.Type.LINK:
			return Color("c9a15b")
	return Pal.INK


## Empty slot: a dashed inked circle on the sentence line.
static func draw_slot(ci: CanvasItem, r: Rect2, highlighted: bool, scale := 1.0) -> void:
	var c := r.get_center()
	var rad := r.size.x * 0.42
	var col := Color(Pal.INK, 0.45) if not highlighted else Pal.WAX
	for k in 14:
		if k % 2 == 0:
			var a0 := TAU * k / 14.0
			ci.draw_arc(c, rad, a0, a0 + TAU / 14.0, 5, col, 1.6 * scale, true)

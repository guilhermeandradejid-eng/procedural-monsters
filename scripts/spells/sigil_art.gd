class_name SigilArt
extends RefCounted
## Procedural sigil of a spell: rings, a {n/k} star polygon, the page's glyphs
## around the circle, the dominant form in the centre and an essence
## flourish on the rim. Deterministic from the program seed.

const FLOURISH := {
	"ember": "flames", "frost": "crystals", "storm": "zigzag", "void": "dots",
	"venom": "drips", "radiant": "rays", "arcane": "runes",
}


static func spec(p: SpellProgram) -> Dictionary:
	var ids: Array[String] = []
	if p:
		for g in p.glyphs:
			if g != "":
				ids.append(g)
	var element := p.element() if p and not p.empty else "arcane"
	var center := p.dominant_form() if p and not p.empty else ""
	var links := p.clauses().size() - 1 if p else 0
	return spec_from(ids, p.seed if p else 0, element, center, links)


static func spec_clause(c: SpellClause) -> Dictionary:
	return spec_from(c.glyph_ids, c.seed, c.element, c.dominant_form(), 1 if c.child else 0)


static func spec_from(ids: Array[String], seed: int, element: String, center_form: String, links: int) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = seed
	var n := clampi(ids.size() + 2, 3, 9)
	var k := 1
	var ks: Array[int] = []
	for kk in range(2, int(n / 2.0) + 1):
		if _gcd(n, kk) == 1:
			ks.append(kk)
	if not ks.is_empty():
		k = ks[r.randi() % ks.size()]
	var parts := Elem.parts_of(element)
	var flourishes: Array[String] = []
	for part in parts:
		flourishes.append(FLOURISH[part])
	if flourishes.is_empty():
		flourishes.append("runes")
	return {
		"ids": ids,
		"n": n,
		"k": k,
		"rot": r.randf() * TAU,
		"rings": r.randi_range(1, 3),
		"dashed": r.randf() < 0.5,
		"ticks": r.randi_range(12, 36),
		"flourishes": flourishes,
		"center": center_form,
		"links": links,
		"seed": r.randi(),
		"inner_ratio": r.randf_range(0.52, 0.64),
	}


static func _gcd(a: int, b: int) -> int:
	while b != 0:
		var t := b
		b = a % b
		a = t
	return a


## Draws the sigil into `ci`. `progress` < 1 draws it partially (ink being written).
static func draw(ci: CanvasItem, sp: Dictionary, center: Vector2, radius: float, col: Color, progress := 1.0, line_w := -1.0) -> void:
	var w := line_w if line_w > 0.0 else maxf(1.2, radius * 0.028)
	var steps: Array[Callable] = []
	var R := radius
	# Outer ring.
	steps.append(func(): Quill.stroke(ci, Quill.arc_points(center, R * 0.97, 0.0, TAU + 0.05, 72), w * 1.3, col, 0.15, 0.0))
	var rings: int = sp.rings
	for i in rings:
		var rr := R * (0.9 - 0.06 * i)
		if sp.dashed and i == rings - 1:
			steps.append(func():
				var segs := 36
				for s in segs:
					if s % 2 == 0:
						var a0 := TAU * s / segs
						Quill.stroke(ci, Quill.arc_points(center, rr, a0, a0 + TAU / segs, 4), w * 0.8, col, 0.4))
		else:
			steps.append(func(): Quill.stroke(ci, Quill.arc_points(center, rr, 0.0, TAU + 0.05, 64), w * 0.7, col, 0.1))
	# Ticks.
	steps.append(func():
		var t: int = sp.ticks
		for i in t:
			var a := TAU * i / t + float(sp.rot)
			var d := Vector2(cos(a), sin(a))
			var l := 0.05 if i % 3 == 0 else 0.025
			Quill.stroke(ci, PackedVector2Array([center + d * R * 0.97, center + d * R * (0.97 - l)]), w * 0.7, col, 0.3))
	# Flourish per essence.
	for f in sp.flourishes:
		steps.append(func(): _flourish(ci, f, center, R, w, col, int(sp.seed)))
	# Star polygon {n/k}.
	steps.append(func():
		var n: int = sp.n
		var k: int = sp.k
		var rr := R * float(sp.inner_ratio)
		var pts := PackedVector2Array()
		var idx := 0
		for i in n + 1:
			var a := float(sp.rot) + TAU * float(idx) / n - PI * 0.5
			pts.append(center + Vector2(cos(a), sin(a)) * rr)
			idx = (idx + k) % n
		var dense := PackedVector2Array()
		for i in pts.size() - 1:
			var seg := Quill.line_points(pts[i], pts[i + 1], 5)
			if i > 0:
				seg.remove_at(0)
			dense.append_array(seg)
		Quill.stroke(ci, dense, w * 0.75, col, 0.05))
	# Glyph icons around the middle ring.
	var ids: Array = sp.ids
	var m := ids.size()
	for i in m:
		var gid: String = ids[i]
		steps.append(func():
			var a := float(sp.rot) * 0.5 + TAU * float(i) / maxf(m, 1.0) - PI * 0.5
			var p := center + Vector2(cos(a), sin(a)) * R * 0.76
			var s := R * 0.17
			Quill.stroke(ci, Quill.arc_points(p, s * 0.72, 0.0, TAU + 0.05, 24), w * 0.6, col, 0.1)
			Quill.draw_strokes(ci, GlyphArt.strokes(gid), Rect2(p - Vector2(s, s) * 0.5, Vector2(s, s)), w * 0.65, col, 0.5))
	# Link arcs between consecutive clause starts.
	if int(sp.links) > 0:
		steps.append(func():
			for i in int(sp.links):
				var a0 := float(sp.rot) + TAU * (0.15 + 0.3 * i)
				Quill.stroke(ci, Quill.arc_points(center, R * 0.42, a0, a0 + PI * 0.6, 18), w * 0.9, col, 0.9))
	# Centre: the dominant form, big.
	if String(sp.center) != "":
		steps.append(func():
			var s := R * 0.46
			Quill.draw_strokes(ci, GlyphArt.strokes(sp.center), Rect2(center - Vector2(s, s) * 0.5, Vector2(s, s)), w * 1.3, col, 0.6))
	var count := int(ceil(steps.size() * clampf(progress, 0.0, 1.0)))
	for i in count:
		steps[i].call()


static func _flourish(ci: CanvasItem, kind: String, c: Vector2, R: float, w: float, col: Color, seed: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed
	match kind:
		"flames":
			var n := 12
			for i in n:
				var a := TAU * i / n
				var d := Vector2(cos(a), sin(a))
				var t := Vector2(-d.y, d.x)
				var base := c + d * R * 0.97
				Quill.stroke(ci, GlyphArt._curve([base - t * R * 0.04, base + d * R * 0.08 + t * R * 0.02, base + d * R * 0.14], 5), w * 0.9, col, 0.9)
		"crystals":
			for i in 6:
				var a := TAU * i / 6.0 + PI / 6.0
				var d := Vector2(cos(a), sin(a))
				var p := c + d * R * 1.0
				var t := Vector2(-d.y, d.x)
				Quill.stroke(ci, PackedVector2Array([p - d * R * 0.04, p + d * R * 0.1]), w, col, 0.4)
				Quill.stroke(ci, PackedVector2Array([p + d * R * 0.03 - t * R * 0.05, p + d * R * 0.07, p + d * R * 0.03 + t * R * 0.05]), w * 0.7, col, 0.3)
		"zigzag":
			var pts := PackedVector2Array()
			var n := 40
			for i in n + 1:
				var a := TAU * i / n
				var rr := R * (1.02 if i % 2 == 0 else 0.93)
				pts.append(c + Vector2(cos(a), sin(a)) * rr)
			Quill.stroke(ci, pts, w * 0.7, col, 0.0)
		"dots":
			for i in 24:
				var a := TAU * i / 24.0
				Quill.dot(ci, c + Vector2(cos(a), sin(a)) * R * 0.83, w * (0.9 if i % 2 == 0 else 0.5), col)
		"drips":
			for i in 7:
				var a := r.randf_range(0.2, PI - 0.2)
				var p := c + Vector2(cos(a), sin(a)) * R * 0.97
				var l := R * r.randf_range(0.06, 0.16)
				Quill.stroke(ci, PackedVector2Array([p, p + Vector2(0, l)]), w * 1.1, col, 0.2)
				Quill.dot(ci, p + Vector2(0, l + w), w * 1.1, col)
		"rays":
			for i in 16:
				var a := TAU * i / 16.0
				var d := Vector2(cos(a), sin(a))
				var l := 0.12 if i % 2 == 0 else 0.06
				Quill.stroke(ci, PackedVector2Array([c + d * R * 1.0, c + d * R * (1.0 + l)]), w * 0.8, col, 0.6)
		_:
			for i in 8:
				var a := TAU * i / 8.0 + 0.2
				var d := Vector2(cos(a), sin(a))
				var p := c + d * R * 1.04
				var t := Vector2(-d.y, d.x)
				Quill.stroke(ci, PackedVector2Array([p - t * R * 0.03, p + d * R * 0.05, p + t * R * 0.03]), w * 0.7, col, 0.2)

class_name Quill
extends RefCounted
## Draws pen strokes with pressure (tapered width) and a soft feathered edge,
## straight onto a CanvasItem through the RenderingServer triangle API.
## Used for glyph icons, sigils and hand-inked UI ornaments.


## pts: stroke path. w: max width. taper: 0 = uniform, 1 = pointed ends.
## wobble: pseudo hand jitter (pixels), seeded so a stroke is stable between frames.
static func stroke(ci: CanvasItem, pts: PackedVector2Array, w: float, col: Color, taper := 0.7, wobble := 0.0, seed := 0, feather := 1.0) -> void:
	var n := pts.size()
	if n < 2 or col.a <= 0.001:
		return
	# Cumulative length for pressure profile.
	var lens := PackedFloat32Array()
	lens.resize(n)
	var total := 0.0
	lens[0] = 0.0
	for i in range(1, n):
		total += pts[i].distance_to(pts[i - 1])
		lens[i] = total
	if total < 0.001:
		return
	var verts := PackedVector2Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	var clear := Color(col.r, col.g, col.b, 0.0)
	for i in n:
		var t := lens[i] / total
		var prev := pts[maxi(i - 1, 0)]
		var next := pts[mini(i + 1, n - 1)]
		var tangent := (next - prev).normalized()
		if tangent == Vector2.ZERO:
			tangent = Vector2.RIGHT
		var normal := Vector2(-tangent.y, tangent.x)
		var pressure := lerpf(1.0, pow(sin(PI * clampf(t, 0.02, 0.98)), 0.55), taper)
		var hw := maxf(0.35, w * 0.5 * pressure)
		var p := pts[i]
		if wobble > 0.0:
			var j := sin(float(seed) * 0.37 + lens[i] * 0.11) * 0.6 + sin(float(seed) * 1.7 + lens[i] * 0.043)
			p += normal * j * wobble
		verts.append(p + normal * (hw + feather))
		verts.append(p + normal * hw)
		verts.append(p - normal * hw)
		verts.append(p - normal * (hw + feather))
		cols.append(clear)
		cols.append(col)
		cols.append(col)
		cols.append(clear)
		if i > 0:
			var a := (i - 1) * 4
			var b := i * 4
			for k in 3:
				idx.append_array([a + k, a + k + 1, b + k, b + k, a + k + 1, b + k + 1])
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), idx, verts, cols)


## Filled dot (ink drop).
static func dot(ci: CanvasItem, p: Vector2, r: float, col: Color) -> void:
	ci.draw_circle(p, r, col)
	ci.draw_arc(p, r, 0.0, TAU, 16, Color(col.r, col.g, col.b, col.a * 0.5), 1.0, true)


static func arc_points(c: Vector2, r: float, a0: float, a1: float, seg := 24) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in seg + 1:
		var a := lerpf(a0, a1, float(i) / seg)
		out.append(c + Vector2(cos(a), sin(a)) * r)
	return out


static func line_points(a: Vector2, b: Vector2, seg := 6) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in seg + 1:
		out.append(a.lerp(b, float(i) / seg))
	return out


## Transforms unit-box strokes (0..1) into a rect.
static func fit(strokes: Array, rect: Rect2) -> Array:
	var out: Array = []
	for s in strokes:
		var t := PackedVector2Array()
		for p in (s as PackedVector2Array):
			t.append(rect.position + p * rect.size)
		out.append(t)
	return out


static func draw_strokes(ci: CanvasItem, strokes: Array, rect: Rect2, w: float, col: Color, taper := 0.6, wobble := 0.0, seed := 0) -> void:
	var i := 0
	for s in fit(strokes, rect):
		stroke(ci, s, w, col, taper, wobble, seed + i * 13)
		i += 1

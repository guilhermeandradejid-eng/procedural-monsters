class_name GlyphArt
extends RefCounted
## Hand-designed ink icons for every glyph, as pen strokes in a unit box.
## Rendered with Quill so they look written, never like stock icons.

static var _cache := {}


static func strokes(id: String) -> Array:
	if _cache.has(id):
		return _cache[id]
	var s := _build(id)
	_cache[id] = s
	return s


# --- stroke helpers -----------------------------------------------------------------
static func _l(a: Vector2, b: Vector2) -> PackedVector2Array:
	return Quill.line_points(a, b, 6)


static func _poly(pts: Array, closed := false) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in pts.size() - 1:
		var seg := Quill.line_points(pts[i], pts[i + 1], 4)
		if i > 0:
			seg.remove_at(0)
		out.append_array(seg)
	if closed:
		var seg := Quill.line_points(pts[-1], pts[0], 4)
		seg.remove_at(0)
		out.append_array(seg)
	return out


static func _arc(c: Vector2, r: float, a0: float, a1: float, seg := 20) -> PackedVector2Array:
	return Quill.arc_points(c, r, deg_to_rad(a0), deg_to_rad(a1), seg)


static func _circle(c: Vector2, r: float) -> PackedVector2Array:
	return _arc(c, r, -90.0, 272.0, 28)


static func _ellipse(c: Vector2, rx: float, ry: float, rot_deg := 0.0, seg := 28) -> PackedVector2Array:
	var out := PackedVector2Array()
	var rot := deg_to_rad(rot_deg)
	for i in seg + 2:
		var a := TAU * float(i) / seg
		out.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return out


## Catmull-Rom through control points.
static func _curve(ctrl: Array, samples := 8, closed := false) -> PackedVector2Array:
	var pts: Array = ctrl.duplicate()
	var n := pts.size()
	var out := PackedVector2Array()
	var count := n if closed else n - 1
	for i in count:
		var p0: Vector2 = pts[(i - 1 + n) % n] if closed else pts[maxi(i - 1, 0)]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[(i + 1) % n]
		var p3: Vector2 = pts[(i + 2) % n] if closed else pts[mini(i + 2, n - 1)]
		for s in samples:
			var t := float(s) / samples
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	out.append(pts[0] if closed else pts[-1])
	return out


static func _head(tip: Vector2, from: Vector2, size := 0.13) -> Array:
	var d := (tip - from).normalized()
	var n := Vector2(-d.y, d.x)
	return [_l(tip, tip - d * size + n * size * 0.7), _l(tip, tip - d * size - n * size * 0.7)]


static func _spiral(c: Vector2, r0: float, r1: float, turns: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var steps := int(turns * 32)
	for i in steps + 1:
		var t := float(i) / steps
		var a := t * turns * TAU
		out.append(c + Vector2(cos(a), sin(a)) * lerpf(r0, r1, t))
	return out


static func _rays(c: Vector2, n: int, r0: float, r1: float, alt := 0.0, offset_deg := 0.0) -> Array:
	var out: Array = []
	for i in n:
		var a := deg_to_rad(offset_deg) + TAU * i / n
		var rr := r1 - (alt if i % 2 == 1 else 0.0)
		out.append(_l(c + Vector2(cos(a), sin(a)) * r0, c + Vector2(cos(a), sin(a)) * rr))
	return out


static func _build(id: String) -> Array:
	var C := Vector2(0.5, 0.5)
	var s: Array = []
	match id:
		# ---------------- forms
		"bolt":
			s.append(_l(Vector2(0.18, 0.82), Vector2(0.78, 0.22)))
			s.append_array(_head(Vector2(0.8, 0.2), Vector2(0.18, 0.82), 0.2))
			s.append(_l(Vector2(0.18, 0.82), Vector2(0.12, 0.64)))
			s.append(_l(Vector2(0.18, 0.82), Vector2(0.36, 0.88)))
		"orb":
			s.append(_circle(C, 0.32))
			s.append(_arc(C, 0.19, 200.0, 300.0, 10))
			s.append(_circle(Vector2(0.4, 0.4), 0.035))
		"nova":
			s.append(_circle(C, 0.13))
			s.append_array(_rays(C, 8, 0.22, 0.44, 0.1, 22.5))
		"lance":
			s.append(_l(Vector2(0.14, 0.86), Vector2(0.6, 0.4)))
			s.append(_poly([Vector2(0.6, 0.4), Vector2(0.64, 0.25), Vector2(0.88, 0.12), Vector2(0.75, 0.36)], true))
			s.append(_l(Vector2(0.5, 0.36), Vector2(0.64, 0.5)))
		"wave":
			s.append(_arc(Vector2(0.36, 0.5), 0.36, -65.0, 65.0))
			s.append(_arc(Vector2(0.28, 0.5), 0.3, -55.0, 55.0))
			s.append(_l(Vector2(0.08, 0.4), Vector2(0.24, 0.4)))
			s.append(_l(Vector2(0.03, 0.5), Vector2(0.2, 0.5)))
			s.append(_l(Vector2(0.08, 0.6), Vector2(0.24, 0.6)))
		"rain":
			for p in [[0.28, 0.12], [0.52, 0.08], [0.76, 0.16], [0.42, 0.4], [0.66, 0.44]]:
				s.append(_l(Vector2(p[0], p[1]), Vector2(p[0] - 0.07, p[1] + 0.2)))
			s.append(_l(Vector2(0.1, 0.86), Vector2(0.9, 0.86)))
			s.append(_arc(Vector2(0.32, 0.86), 0.07, 190.0, 350.0, 8))
			s.append(_arc(Vector2(0.62, 0.86), 0.07, 190.0, 350.0, 8))
		"orbit":
			s.append(_circle(C, 0.08))
			s.append(_ellipse(C, 0.4, 0.17, -20.0))
			s.append(_circle(C + Vector2(0.4, 0.0).rotated(deg_to_rad(-20.0)) * Vector2(0.85, 0.85) + Vector2(0.0, -0.06), 0.06))
		"mine":
			var hex: Array = []
			for i in 6:
				var a := deg_to_rad(30.0 + 60.0 * i)
				hex.append(C + Vector2(cos(a), sin(a)) * 0.38)
			s.append(_poly(hex, true))
			s.append(_l(Vector2(0.5, 0.28), Vector2(0.5, 0.72)))
			s.append(_l(Vector2(0.31, 0.5), Vector2(0.69, 0.5)))
			s.append(_circle(C, 0.09))
		"chakram":
			s.append(_circle(C, 0.24))
			for k in 4:
				var a0 := deg_to_rad(90.0 * k)
				s.append(_curve([C + Vector2(cos(a0), sin(a0)) * 0.24, C + Vector2(cos(a0 + 0.5), sin(a0 + 0.5)) * 0.46, C + Vector2(cos(a0 + 1.05), sin(a0 + 1.05)) * 0.27], 6))
		"meteor":
			s.append(_l(Vector2(0.1, 0.9), Vector2(0.5, 0.5)))
			s.append(_l(Vector2(0.24, 0.94), Vector2(0.55, 0.6)))
			s.append(_l(Vector2(0.06, 0.74), Vector2(0.42, 0.45)))
			s.append(_circle(Vector2(0.64, 0.36), 0.17))
		"vortex":
			s.append(_spiral(C, 0.03, 0.42, 2.3))
		"totem":
			s.append(_poly([Vector2(0.38, 0.88), Vector2(0.41, 0.26), Vector2(0.5, 0.1), Vector2(0.59, 0.26), Vector2(0.62, 0.88)]))
			s.append(_l(Vector2(0.26, 0.88), Vector2(0.74, 0.88)))
			s.append(_circle(Vector2(0.5, 0.42), 0.06))
			s.append(_l(Vector2(0.24, 0.42), Vector2(0.33, 0.42)))
			s.append(_l(Vector2(0.67, 0.42), Vector2(0.76, 0.42)))
		"serpent":
			s.append(_curve([Vector2(0.14, 0.86), Vector2(0.36, 0.74), Vector2(0.3, 0.52), Vector2(0.52, 0.38), Vector2(0.72, 0.22)], 8))
			s.append(_circle(Vector2(0.77, 0.19), 0.06))
			s.append(_poly([Vector2(0.82, 0.14), Vector2(0.9, 0.1), Vector2(0.93, 0.05)]))
		"blink":
			var path := _curve([Vector2(0.16, 0.78), Vector2(0.45, 0.35), Vector2(0.8, 0.32)], 10)
			for i in range(0, path.size() - 2, 4):
				s.append(PackedVector2Array([path[i], path[mini(i + 2, path.size() - 1)]]))
			s.append(_circle(Vector2(0.16, 0.8), 0.06))
			s.append_array(_rays(Vector2(0.82, 0.32), 4, 0.05, 0.15, 0.0, 45.0))
		# ---------------- essences
		"ember":
			s.append(_curve([Vector2(0.5, 0.9), Vector2(0.27, 0.72), Vector2(0.31, 0.46), Vector2(0.44, 0.3), Vector2(0.45, 0.08), Vector2(0.63, 0.3), Vector2(0.73, 0.52), Vector2(0.7, 0.74)], 7, true))
			s.append(_curve([Vector2(0.5, 0.82), Vector2(0.42, 0.68), Vector2(0.5, 0.5), Vector2(0.57, 0.66)], 6, true))
		"frost":
			for i in 6:
				var a := deg_to_rad(90.0 + 60.0 * i)
				var d := Vector2(cos(a), sin(a))
				var n := Vector2(-d.y, d.x)
				s.append(_l(C, C + d * 0.4))
				s.append(_l(C + d * 0.24, C + d * 0.32 + n * 0.08))
				s.append(_l(C + d * 0.24, C + d * 0.32 - n * 0.08))
		"storm":
			s.append(_poly([Vector2(0.6, 0.06), Vector2(0.34, 0.5), Vector2(0.54, 0.5), Vector2(0.38, 0.94)]))
			s.append(_poly([Vector2(0.54, 0.5), Vector2(0.72, 0.6), Vector2(0.68, 0.72)]))
		"void":
			s.append(_circle(C, 0.36))
			s.append(_circle(Vector2(0.58, 0.44), 0.22))
		"venom":
			s.append(_curve([Vector2(0.5, 0.08), Vector2(0.36, 0.44), Vector2(0.32, 0.66), Vector2(0.5, 0.88), Vector2(0.68, 0.66), Vector2(0.64, 0.44)], 7, true))
			s.append(_circle(Vector2(0.44, 0.63), 0.06))
			s.append(_circle(Vector2(0.58, 0.5), 0.03))
		"radiant":
			s.append(_circle(C, 0.17))
			s.append_array(_rays(C, 12, 0.25, 0.45, 0.08))
		# ---------------- inflections
		"split":
			s.append(_l(Vector2(0.5, 0.9), Vector2(0.5, 0.5)))
			s.append(_l(Vector2(0.5, 0.5), Vector2(0.18, 0.14)))
			s.append(_l(Vector2(0.5, 0.5), Vector2(0.82, 0.14)))
			s.append(_l(Vector2(0.5, 0.5), Vector2(0.5, 0.1)))
		"echo":
			s.append(_circle(Vector2(0.2, 0.5), 0.05))
			for r in [0.2, 0.35, 0.5]:
				s.append(_arc(Vector2(0.2, 0.5), r, -48.0, 48.0, 12))
		"seek":
			s.append(_curve([Vector2(0.1, 0.5), Vector2(0.5, 0.22), Vector2(0.9, 0.5)], 8))
			s.append(_curve([Vector2(0.1, 0.5), Vector2(0.5, 0.78), Vector2(0.9, 0.5)], 8))
			s.append(_circle(C, 0.11))
		"pierce":
			s.append(_l(Vector2(0.08, 0.5), Vector2(0.9, 0.5)))
			s.append_array(_head(Vector2(0.92, 0.5), Vector2(0.08, 0.5), 0.14))
			s.append(_l(Vector2(0.38, 0.28), Vector2(0.38, 0.72)))
			s.append(_l(Vector2(0.6, 0.28), Vector2(0.6, 0.72)))
		"bounce":
			s.append(_poly([Vector2(0.1, 0.18), Vector2(0.3, 0.8), Vector2(0.5, 0.3), Vector2(0.7, 0.8), Vector2(0.9, 0.34)]))
			s.append(_l(Vector2(0.08, 0.88), Vector2(0.92, 0.88)))
		"grow":
			s.append(_poly([Vector2(0.38, 0.38), Vector2(0.62, 0.38), Vector2(0.62, 0.62), Vector2(0.38, 0.62)], true))
			for d in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
				var a: Vector2 = C + d * 0.15
				var b: Vector2 = C + d * 0.38
				s.append(_l(a, b))
				s.append_array(_head(b, a, 0.1))
		"swift":
			for x in [0.18, 0.4, 0.62]:
				s.append(_poly([Vector2(x, 0.24), Vector2(x + 0.18, 0.5), Vector2(x, 0.76)]))
		"volatile":
			var star: Array = []
			for i in 16:
				var a := TAU * i / 16.0
				var r := 0.44 if i % 2 == 0 else 0.2
				star.append(C + Vector2(cos(a), sin(a)) * r)
			s.append(_poly(star, true))
		"linger":
			s.append(_ellipse(Vector2(0.5, 0.74), 0.36, 0.12))
			s.append(_l(Vector2(0.4, 0.16), Vector2(0.4, 0.44)))
			s.append(_circle(Vector2(0.4, 0.5), 0.04))
			s.append(_l(Vector2(0.62, 0.26), Vector2(0.62, 0.48)))
			s.append(_circle(Vector2(0.62, 0.54), 0.035))
		"twin":
			s.append(_l(Vector2(0.44, 0.5), Vector2(0.08, 0.5)))
			s.append_array(_head(Vector2(0.06, 0.5), Vector2(0.44, 0.5), 0.13))
			s.append(_l(Vector2(0.56, 0.5), Vector2(0.92, 0.5)))
			s.append_array(_head(Vector2(0.94, 0.5), Vector2(0.56, 0.5), 0.13))
			s.append(_circle(C, 0.04))
		"spiral":
			s.append(_spiral(C, 0.05, 0.36, 1.8))
		"delay":
			s.append(_l(Vector2(0.26, 0.12), Vector2(0.74, 0.12)))
			s.append(_l(Vector2(0.26, 0.88), Vector2(0.74, 0.88)))
			s.append(_poly([Vector2(0.3, 0.12), Vector2(0.5, 0.5), Vector2(0.3, 0.88)]))
			s.append(_poly([Vector2(0.7, 0.12), Vector2(0.5, 0.5), Vector2(0.7, 0.88)]))
			s.append(_l(Vector2(0.42, 0.8), Vector2(0.58, 0.8)))
		"leech":
			s.append(_curve([Vector2(0.24, 0.14), Vector2(0.33, 0.44), Vector2(0.38, 0.66), Vector2(0.44, 0.14)], 6))
			s.append(_curve([Vector2(0.56, 0.14), Vector2(0.62, 0.66), Vector2(0.67, 0.44), Vector2(0.76, 0.14)], 6))
			s.append(_curve([Vector2(0.5, 0.7), Vector2(0.44, 0.82), Vector2(0.5, 0.9), Vector2(0.56, 0.82)], 5, true))
		"heavy":
			s.append(_l(Vector2(0.5, 0.08), Vector2(0.5, 0.62)))
			s.append_array(_head(Vector2(0.5, 0.66), Vector2(0.5, 0.08), 0.16))
			s.append(_l(Vector2(0.14, 0.78), Vector2(0.86, 0.78)))
			s.append(_l(Vector2(0.3, 0.78), Vector2(0.22, 0.92)))
			s.append(_l(Vector2(0.7, 0.78), Vector2(0.78, 0.92)))
		"sharpen":
			s.append(_poly([Vector2(0.46, 0.08), Vector2(0.62, 0.5), Vector2(0.46, 0.92), Vector2(0.3, 0.5)], true))
			s.append(_l(Vector2(0.46, 0.2), Vector2(0.46, 0.8)))
			s.append(_l(Vector2(0.78, 0.12), Vector2(0.78, 0.32)))
			s.append(_l(Vector2(0.68, 0.22), Vector2(0.88, 0.22)))
		"magnet":
			s.append(_arc(Vector2(0.5, 0.46), 0.28, 0.0, 180.0, 16))
			s.append(_l(Vector2(0.22, 0.46), Vector2(0.22, 0.14)))
			s.append(_l(Vector2(0.78, 0.46), Vector2(0.78, 0.14)))
			s.append(_l(Vector2(0.12, 0.2), Vector2(0.32, 0.2)))
			s.append(_l(Vector2(0.68, 0.2), Vector2(0.88, 0.2)))
		"chain":
			s.append(_ellipse(Vector2(0.37, 0.52), 0.21, 0.12, -32.0))
			s.append(_ellipse(Vector2(0.63, 0.48), 0.21, 0.12, -32.0))
		"ward":
			s.append(_poly([Vector2(0.2, 0.16), Vector2(0.8, 0.16), Vector2(0.77, 0.55), Vector2(0.5, 0.9), Vector2(0.23, 0.55)], true))
			s.append(_l(Vector2(0.5, 0.26), Vector2(0.5, 0.76)))
		# ---------------- links
		"on_hit":
			s.append(_l(Vector2(0.1, 0.9), Vector2(0.55, 0.45)))
			s.append_array(_head(Vector2(0.58, 0.42), Vector2(0.1, 0.9), 0.14))
			s.append_array(_rays(Vector2(0.72, 0.28), 6, 0.05, 0.18, 0.05))
		"on_end":
			s.append(_l(Vector2(0.08, 0.5), Vector2(0.58, 0.5)))
			s.append(_circle(Vector2(0.75, 0.5), 0.13))
			s.append(_circle(Vector2(0.75, 0.5), 0.04))
		"on_kill":
			s.append(_arc(Vector2(0.5, 0.42), 0.27, 150.0, 390.0, 22))
			s.append(_poly([Vector2(0.36, 0.64), Vector2(0.38, 0.82), Vector2(0.62, 0.82), Vector2(0.64, 0.64)]))
			s.append(_circle(Vector2(0.41, 0.42), 0.055))
			s.append(_circle(Vector2(0.59, 0.42), 0.055))
			s.append(_l(Vector2(0.5, 0.7), Vector2(0.5, 0.82)))
		"pulse":
			s.append(_poly([Vector2(0.05, 0.55), Vector2(0.3, 0.55), Vector2(0.38, 0.28), Vector2(0.48, 0.8), Vector2(0.56, 0.42), Vector2(0.62, 0.55), Vector2(0.95, 0.55)]))
		"then":
			s.append(_circle(Vector2(0.14, 0.5), 0.06))
			s.append(_l(Vector2(0.24, 0.5), Vector2(0.86, 0.5)))
			s.append_array(_head(Vector2(0.9, 0.5), Vector2(0.24, 0.5), 0.14))
		# ---------------- reward icons (doors, pedestals, HUD)
		"reward_glyph":
			s.append(_curve([Vector2(0.72, 0.1), Vector2(0.5, 0.35), Vector2(0.34, 0.6), Vector2(0.26, 0.78)], 8))
			s.append(_curve([Vector2(0.72, 0.1), Vector2(0.62, 0.3), Vector2(0.44, 0.52), Vector2(0.28, 0.74)], 8))
			s.append(_l(Vector2(0.26, 0.78), Vector2(0.2, 0.9)))
			s.append(_curve([Vector2(0.14, 0.9), Vector2(0.4, 0.84), Vector2(0.6, 0.92), Vector2(0.86, 0.86)], 6))
		"reward_relic":
			s.append(_poly([Vector2(0.5, 0.14), Vector2(0.78, 0.4), Vector2(0.5, 0.88), Vector2(0.22, 0.4)], true))
			s.append(_l(Vector2(0.22, 0.4), Vector2(0.78, 0.4)))
			s.append(_poly([Vector2(0.36, 0.4), Vector2(0.5, 0.14), Vector2(0.64, 0.4), Vector2(0.5, 0.88)], true))
		"reward_gold":
			for i in 3:
				s.append(_ellipse(Vector2(0.44 + i * 0.05, 0.72 - i * 0.16), 0.24, 0.08))
			s.append(_ellipse(Vector2(0.62, 0.34), 0.16, 0.16))
			s.append(_l(Vector2(0.62, 0.26), Vector2(0.62, 0.42)))
		"reward_heal":
			s.append(_poly([Vector2(0.38, 0.9), Vector2(0.38, 0.5), Vector2(0.62, 0.5), Vector2(0.62, 0.9)], true))
			s.append(_curve([Vector2(0.5, 0.44), Vector2(0.4, 0.3), Vector2(0.5, 0.1), Vector2(0.6, 0.3)], 6, true))
			s.append(_l(Vector2(0.28, 0.9), Vector2(0.72, 0.9)))
		"reward_page":
			s.append(_poly([Vector2(0.26, 0.1), Vector2(0.6, 0.1), Vector2(0.76, 0.26), Vector2(0.76, 0.9), Vector2(0.26, 0.9)], true))
			s.append(_poly([Vector2(0.6, 0.1), Vector2(0.6, 0.26), Vector2(0.76, 0.26)]))
			s.append(_l(Vector2(0.51, 0.42), Vector2(0.51, 0.74)))
			s.append(_l(Vector2(0.35, 0.58), Vector2(0.67, 0.58)))
		"reward_shop":
			s.append(_curve([Vector2(0.3, 0.42), Vector2(0.24, 0.66), Vector2(0.3, 0.88), Vector2(0.7, 0.88), Vector2(0.76, 0.66), Vector2(0.7, 0.42)], 6))
			s.append(_l(Vector2(0.3, 0.42), Vector2(0.7, 0.42)))
			s.append(_curve([Vector2(0.38, 0.42), Vector2(0.44, 0.2), Vector2(0.56, 0.2), Vector2(0.62, 0.42)], 6))
			s.append(_circle(Vector2(0.5, 0.64), 0.07))
		"reward_elite":
			s.append(_arc(Vector2(0.5, 0.5), 0.25, 150.0, 390.0, 22))
			s.append(_poly([Vector2(0.38, 0.72), Vector2(0.4, 0.86), Vector2(0.6, 0.86), Vector2(0.62, 0.72)]))
			s.append(_circle(Vector2(0.41, 0.5), 0.05))
			s.append(_circle(Vector2(0.59, 0.5), 0.05))
			s.append(_poly([Vector2(0.3, 0.3), Vector2(0.36, 0.1), Vector2(0.44, 0.24), Vector2(0.5, 0.06), Vector2(0.56, 0.24), Vector2(0.64, 0.1), Vector2(0.7, 0.3)]))
		"reward_boss":
			s.append(_poly([Vector2(0.14, 0.2), Vector2(0.5, 0.28), Vector2(0.86, 0.2), Vector2(0.86, 0.82), Vector2(0.5, 0.9), Vector2(0.14, 0.82)], true))
			s.append(_l(Vector2(0.5, 0.28), Vector2(0.5, 0.9)))
			s.append(_l(Vector2(0.14, 0.4), Vector2(0.86, 0.66)))
			s.append(_l(Vector2(0.14, 0.66), Vector2(0.86, 0.4)))
		"reward_ember":
			s.append(_curve([Vector2(0.5, 0.9), Vector2(0.27, 0.72), Vector2(0.31, 0.46), Vector2(0.44, 0.3), Vector2(0.45, 0.08), Vector2(0.63, 0.3), Vector2(0.73, 0.52), Vector2(0.7, 0.74)], 7, true))
		_:
			s.append(_circle(C, 0.3))
			s.append(_l(Vector2(0.4, 0.4), Vector2(0.6, 0.6)))
	return s


## Colour family of a glyph type, for UI accents (ink colours, not neon).
static func type_color(t: int) -> Color:
	match t:
		GlyphDB.Type.FORM:
			return Color("2b1f1a")
		GlyphDB.Type.ESSENCE:
			return Color("8a2a1c")
		GlyphDB.Type.INFLECTION:
			return Color("1f3f5e")
		GlyphDB.Type.LINK:
			return Color("6a4a14")
	return Pal.INK


static func glyph_color(id: String) -> Color:
	var t := GlyphDB.type_of(id)
	if t == GlyphDB.Type.ESSENCE:
		return Elem.palette(id)["dark"].lerp(Pal.INK, 0.25)
	return type_color(t)

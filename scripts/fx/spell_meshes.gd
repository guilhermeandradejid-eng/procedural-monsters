class_name SpellMeshes
extends RefCounted
## Procedural low-poly meshes for spell bodies. Facets are intentional: they
## catch the fresnel rim and read well at gameplay distance.

static var _cache := {}


static func _finish(st: SurfaceTool) -> ArrayMesh:
	st.generate_normals()
	return st.commit()


## Bolt body: a spindle pointing to -Z with `spikes` twisted fins.
static func spindle(spikes: int, twist: float, shape: int) -> ArrayMesh:
	var key := "spindle|%d|%.2f|%d" % [spikes, twist, shape]
	if _cache.has(key):
		return _cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := 5 + shape
	var tip := Vector3(0, 0, -1.0)
	var tail := Vector3(0, 0, 0.7 + 0.15 * shape)
	var ring: Array[Vector3] = []
	for i in sides:
		var a := TAU * i / sides
		ring.append(Vector3(cos(a) * 0.32, sin(a) * 0.32, -0.15))
	for i in sides:
		var a := ring[i]
		var b := ring[(i + 1) % sides]
		st.add_vertex(tip)
		st.add_vertex(b)
		st.add_vertex(a)
		st.add_vertex(tail)
		st.add_vertex(a)
		st.add_vertex(b)
	for i in spikes:
		var a := TAU * i / spikes
		var tw := twist * 0.9
		var base0 := Vector3(cos(a) * 0.25, sin(a) * 0.25, -0.25)
		var base1 := Vector3(cos(a + 0.35) * 0.25, sin(a + 0.35) * 0.25, 0.25)
		var outer := Vector3(cos(a + tw) * 0.62, sin(a + tw) * 0.62, 0.45)
		st.add_vertex(base0)
		st.add_vertex(outer)
		st.add_vertex(base1)
		st.add_vertex(base0)
		st.add_vertex(base1)
		st.add_vertex(outer)
	var m := _finish(st)
	_cache[key] = m
	return m


## Wave body: a crescent facing -Z.
static func crescent(arc_deg := 130.0) -> ArrayMesh:
	var key := "crescent|%d" % int(arc_deg)
	if _cache.has(key):
		return _cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 22
	var half := deg_to_rad(arc_deg) * 0.5
	var prev: Array = []
	for i in seg + 1:
		var t := float(i) / seg
		var a := lerpf(-half, half, t)
		var thick := sin(PI * t) * 0.32 + 0.02
		var d := Vector3(sin(a), 0.0, -cos(a))
		var outer := d * 1.0
		var inner := d * (1.0 - thick)
		var h := 0.18 * sin(PI * t) + 0.02
		var cur := [outer + Vector3.UP * h * 0.3, inner, outer - Vector3.UP * h * 0.3, outer + Vector3.UP * h]
		if not prev.is_empty():
			for q in [[0, 1], [1, 2], [3, 1]]:
				var p0: Vector3 = prev[q[0]]
				var p1: Vector3 = prev[q[1]]
				var c0: Vector3 = cur[q[0]]
				var c1: Vector3 = cur[q[1]]
				st.add_vertex(p0)
				st.add_vertex(c0)
				st.add_vertex(p1)
				st.add_vertex(p1)
				st.add_vertex(c0)
				st.add_vertex(c1)
		prev = cur
	var m := _finish(st)
	_cache[key] = m
	return m


## Chakram: a ring with curved blades, in the XZ plane.
static func chakram(blades: int) -> ArrayMesh:
	var key := "chakram|%d" % blades
	if _cache.has(key):
		return _cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 28
	for i in seg:
		var a0 := TAU * i / seg
		var a1 := TAU * (i + 1) / seg
		var o0 := Vector3(cos(a0), 0, sin(a0)) * 0.62
		var o1 := Vector3(cos(a1), 0, sin(a1)) * 0.62
		var i0 := Vector3(cos(a0), 0, sin(a0)) * 0.42
		var i1 := Vector3(cos(a1), 0, sin(a1)) * 0.42
		var up := Vector3.UP * 0.07
		for s in [1.0, -1.0]:
			st.add_vertex(o0 + up * s)
			st.add_vertex(i0 + up * s)
			st.add_vertex(o1 + up * s)
			st.add_vertex(o1 + up * s)
			st.add_vertex(i0 + up * s)
			st.add_vertex(i1 + up * s)
		st.add_vertex(o0 + up)
		st.add_vertex(o1 + up)
		st.add_vertex(o0 - up)
		st.add_vertex(o0 - up)
		st.add_vertex(o1 + up)
		st.add_vertex(o1 - up)
	for b in blades:
		var a := TAU * b / blades
		var p0 := Vector3(cos(a), 0, sin(a)) * 0.58
		var p1 := Vector3(cos(a + 0.55), 0, sin(a + 0.55)) * 1.05
		var p2 := Vector3(cos(a + 0.7), 0, sin(a + 0.7)) * 0.6
		for s in [1.0, -1.0]:
			var up := Vector3.UP * 0.04 * s
			st.add_vertex(p0 + up)
			st.add_vertex(p1)
			st.add_vertex(p2 + up)
	var m := _finish(st)
	_cache[key] = m
	return m


static func rock(seed: int) -> ArrayMesh:
	var key := "rock|%d" % (seed % 6)
	if _cache.has(key):
		return _cache[key]
	var sm := SphereMesh.new()
	sm.radial_segments = 8
	sm.rings = 5
	sm.radius = 1.0
	sm.height = 2.0
	var arrays := sm.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var r := RandomNumberGenerator.new()
	r.seed = seed % 6
	var jitter := {}
	for i in verts.size():
		var k := Vector3i(verts[i] * 100.0)
		if not jitter.has(k):
			jitter[k] = r.randf_range(0.78, 1.12)
		verts[i] *= jitter[k]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for i in idx:
		st.add_vertex(verts[i])
	var m := _finish(st)
	_cache[key] = m
	return m


static func sphere(segments := 12) -> SphereMesh:
	var key := "sphere|%d" % segments
	if _cache.has(key):
		return _cache[key]
	var sm := SphereMesh.new()
	sm.radial_segments = segments
	sm.rings = int(segments / 2.0)
	sm.radius = 1.0
	sm.height = 2.0
	_cache[key] = sm
	return sm


static func obelisk() -> CylinderMesh:
	if _cache.has("obelisk"):
		return _cache["obelisk"]
	var c := CylinderMesh.new()
	c.top_radius = 0.1
	c.bottom_radius = 0.34
	c.height = 2.3
	c.radial_segments = 4
	c.rings = 1
	_cache["obelisk"] = c
	return c


static func flat_quad() -> PlaneMesh:
	if _cache.has("flat"):
		return _cache["flat"]
	var p := PlaneMesh.new()
	p.size = Vector2(2, 2)
	_cache["flat"] = p
	return p


## Vertical strip for beams: UV.x across, UV.y along +(-Z).
static func beam_strip() -> ArrayMesh:
	if _cache.has("beam"):
		return _cache["beam"]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts := [[Vector3(-0.5, 0, 0), Vector2(0, 0)], [Vector3(0.5, 0, 0), Vector2(1, 0)], [Vector3(-0.5, 0, -1), Vector2(0, 1)], [Vector3(0.5, 0, -1), Vector2(1, 1)]]
	for i in [0, 2, 1, 1, 2, 3]:
		st.set_uv(pts[i][1])
		st.add_vertex(pts[i][0])
	var m := st.commit()
	_cache["beam"] = m
	return m

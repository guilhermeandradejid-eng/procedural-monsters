class_name RoomBuilder
extends RefCounted
## Builds a page: parchment floor on a thick book block, invisible walls at
## the page edges, a frame of pop-up scenery, interior obstacles and candles.

const PROP_DIR := "res://assets/models/props/"

## r = collision radius (0 = decorative only), h = height, light = has flames.
const PROPS := {
	"bookshelf": {"r": 0.0, "box": Vector3(1.7, 2.4, 0.6), "h": 2.4},
	"book_stack": {"r": 0.5, "h": 1.1, "light": true},
	"big_book": {"r": 0.0, "box": Vector3(1.8, 0.45, 1.3), "h": 0.45},
	"candles": {"r": 0.45, "h": 0.8, "light": true},
	"pillar": {"r": 0.48, "h": 3.0},
	"broken_pillar": {"r": 0.5, "h": 1.4},
	"arch": {"r": 0.0, "h": 3.4},
	"bush": {"r": 0.0, "h": 0.8},
	"scroll_pile": {"r": 0.0, "h": 0.3},
	"lectern": {"r": 0.4, "h": 1.4},
	"pedestal": {"r": 0.55, "h": 0.9},
	"ember_tree": {"r": 0.6, "h": 2.6, "light": true},
	"dummy": {"r": 0.35, "h": 1.6},
	"gravestone": {"r": 0.45, "h": 1.1, "light": true},
	"ink_kelp": {"r": 0.25, "h": 2.2},
	"chest": {"r": 0.5, "h": 0.8},
	"paper_tree0": {"r": 0.45, "h": 2.6},
	"paper_tree1": {"r": 0.45, "h": 2.4},
	"rock0": {"r": 0.7, "h": 0.8},
	"rock1": {"r": 0.75, "h": 0.8},
}

## Scenery per chapter: frame (edges), obstacles (interior), small decor.
const KITS := {
	"grove": {"frame": ["paper_tree0", "paper_tree1", "paper_tree0", "bush", "rock1"], "obstacles": ["paper_tree1", "rock0", "rock1", "book_stack", "broken_pillar"], "decor": ["bush", "scroll_pile", "candles"]},
	"catacombs": {"frame": ["bookshelf", "pillar", "bookshelf", "gravestone"], "obstacles": ["pillar", "broken_pillar", "gravestone", "book_stack", "rock0"], "decor": ["candles", "scroll_pile", "gravestone"]},
	"inksea": {"frame": ["ink_kelp", "bookshelf", "ink_kelp", "rock1", "broken_pillar"], "obstacles": ["ink_kelp", "rock0", "big_book", "broken_pillar", "book_stack"], "decor": ["ink_kelp", "scroll_pile", "candles"]},
	"hub": {"frame": ["bookshelf", "bookshelf", "candles", "pillar"], "obstacles": [], "decor": ["candles", "scroll_pile", "book_stack"]},
}

static var _flame_cache := {}


static func build_page(level: Node3D, size: Vector2, mood: String, seed: float) -> MeshInstance3D:
	var floor_mi := MeshInstance3D.new()
	floor_mi.name = "Page"
	var pm := PlaneMesh.new()
	pm.size = size
	pm.subdivide_width = 2
	pm.subdivide_depth = 2
	floor_mi.mesh = pm
	floor_mi.material_override = Stage.page_material(mood, size, seed)
	level.add_child(floor_mi)
	# The book block: stacked page edges and the leather cover under the page.
	var md := Stage.mood(mood)
	for i in 3:
		var slab := MeshInstance3D.new()
		var bm := BoxMesh.new()
		var inset := 0.12 * i
		bm.size = Vector3(size.x - 0.2 - inset, 0.14, size.y - 0.2 - inset)
		slab.mesh = bm
		slab.position = Vector3(0.05 * i, -0.08 - 0.14 * i, 0.06 * i)
		slab.material_override = Toon.material("Paper", Color(md.paper_dark).darkened(0.08 * i), {"paper": 0.3})
		level.add_child(slab)
	var cover := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(size.x + 0.8, 0.22, size.y + 0.8)
	cover.mesh = cm
	cover.position = Vector3(0.15, -0.58, 0.2)
	cover.material_override = Toon.material("Cover", Color("5a1a16"))
	level.add_child(cover)
	# Ground collider (not strictly needed for floating bodies, but keeps raycasts sane).
	var body := StaticBody3D.new()
	body.collision_layer = Combat.LAYER_WORLD
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, 0.2, size.y)
	cs.shape = box
	cs.position = Vector3(0, -0.1, 0)
	body.add_child(cs)
	level.add_child(body)
	return floor_mi


## Invisible walls just inside the page edge; `gaps` leaves openings (x ranges) on the far edge.
static func build_walls(level: Node3D, size: Vector2, margin := 0.9) -> void:
	var hx := size.x * 0.5 - margin
	var hz := size.y * 0.5 - margin
	var walls := [
		[Vector3(0, 1.5, -hz - 0.5), Vector3(size.x, 3.0, 1.0)],
		[Vector3(0, 1.5, hz + 0.5), Vector3(size.x, 3.0, 1.0)],
		[Vector3(-hx - 0.5, 1.5, 0), Vector3(1.0, 3.0, size.y)],
		[Vector3(hx + 0.5, 1.5, 0), Vector3(1.0, 3.0, size.y)],
	]
	for w in walls:
		var b := StaticBody3D.new()
		b.collision_layer = Combat.LAYER_WORLD
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = w[1]
		cs.shape = box
		b.add_child(cs)
		level.add_child(b)
		b.position = w[0]


## Spawns a prop with collision and returns it (not yet raised: see popup()).
static func prop(level: Node3D, id: String, pos: Vector3, yaw := 0.0, scale := 1.0) -> Node3D:
	var path := PROP_DIR + id + ".glb"
	if not ResourceLoader.exists(path):
		return null
	var info: Dictionary = PROPS.get(id, {"r": 0.5, "h": 1.0})
	var root := StaticBody3D.new()
	root.name = id
	root.collision_layer = Combat.LAYER_WORLD if (float(info.r) > 0.0 or info.has("box")) else 0
	var model := Toon.spawn(path)
	root.add_child(model)
	if float(info.r) > 0.0:
		var cs := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = float(info.r) * scale
		cyl.height = float(info.h) * scale
		cs.shape = cyl
		cs.position = Vector3.UP * float(info.h) * scale * 0.5
		root.add_child(cs)
	elif info.has("box"):
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = (info.box as Vector3) * scale
		cs.shape = box
		cs.position = Vector3.UP * (info.box as Vector3).y * scale * 0.5
		root.add_child(cs)
	level.add_child(root)
	root.position = pos
	root.rotation.y = yaw
	root.scale = Vector3.ONE * scale
	if info.get("light", false):
		_light_flames(model)
	return root


## Candle flames on every "Flame*" marker exported from Blender.
static func _light_flames(model: Node3D) -> void:
	var markers: Array[Node3D] = []
	var stack: Array[Node] = [model]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n is Node3D and String(n.name).begins_with("Flame"):
			markers.append(n)
	var first := true
	for m in markers:
		var em := Fx.emitter(m, "flame", Pal.EMBER_HOT, Pal.EMBER, 10, 0.7)
		var pm := em.process_material as ParticleProcessMaterial
		if pm:
			var key := "candle"
			if not _flame_cache.has(key):
				var copy := pm.duplicate() as ParticleProcessMaterial
				copy.emission_sphere_radius = 0.025
				copy.spread = 12.0
				copy.initial_velocity_min = 0.3
				copy.initial_velocity_max = 0.8
				copy.scale_min = 0.12
				copy.scale_max = 0.2
				_flame_cache[key] = copy
			em.process_material = _flame_cache[key]
		if first:
			first = false
			var l := CandleLight.new()
			m.add_child(l)


## Pop-up book reveal: props fold up from the page, staggered from the centre.
static func popup(nodes: Array, center := Vector3.ZERO, delay := 0.0) -> void:
	for n in nodes:
		if n == null or not is_instance_valid(n):
			continue
		var node := n as Node3D
		var final_scale := node.scale
		var final_rot := node.rotation
		var d := Combat.flat_dist(node.position, center)
		var wait := delay + d * 0.035 + randf() * 0.08
		node.scale = Vector3(final_scale.x, 0.02, final_scale.z)
		node.rotation.x = -1.3
		var t := node.create_tween()
		t.tween_interval(wait)
		t.set_parallel(true)
		t.tween_property(node, "scale", final_scale, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(node, "rotation", final_rot, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.chain().tween_callback(func():
			if randf() < 0.35:
				Audio.play("paper_fold", node.global_position, -16.0, randf_range(0.9, 1.2), 0.1, 40))


## Poisson-ish scatter inside a rectangle, keeping clear of `avoid` circles [pos, r].
static func scatter(rng: RandomNumberGenerator, rect: Rect2, count: int, min_dist: float, avoid: Array) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var tries := 0
	while out.size() < count and tries < count * 40:
		tries += 1
		var p := Vector3(rng.randf_range(rect.position.x, rect.end.x), 0.0, rng.randf_range(rect.position.y, rect.end.y))
		var ok := true
		for q in out:
			if q.distance_to(p) < min_dist:
				ok = false
				break
		if ok:
			for a in avoid:
				if Combat.flat_dist(a[0], p) < float(a[1]):
					ok = false
					break
		if ok:
			out.append(p)
	return out


## Decorative ink illustration on the page: a huge faded sigil of a random sentence.
static func page_illustration(level: Node3D, rng: RandomNumberGenerator, pos: Vector3, size: float) -> void:
	var ids := GlyphDB.all_ids()
	var src: Array = []
	for i in rng.randi_range(3, 6):
		src.append(ids[rng.randi() % ids.size()])
	var prog := SpellProgram.compile(src)
	var mi := MeshInstance3D.new()
	mi.mesh = SpellMeshes.flat_quad()
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/fx/page_ink.gdshader")
	m.set_shader_parameter("sigil", Fx.sigils.for_program(prog))
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	level.add_child(mi)
	mi.position = pos + Vector3.UP * 0.008
	mi.rotation.y = rng.randf() * TAU
	mi.scale = Vector3.ONE * size

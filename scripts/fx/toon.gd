class_name Toon
extends RefCounted
## Replaces imported glTF materials with the toon shader, keyed by material
## name (the naming contract lives in tools/blender/lib.py). Colours can be
## overridden per instance, e.g. each knight's Cloth takes the player colour.

const SHADER := preload("res://shaders/toon.gdshader")

## name -> parameters. "color" null means "keep the imported base colour".
const PRESETS := {
	"Cloth": {"shade": 0.6},
	"ClothDark": {"shade": 0.55},
	"Metal": {"sheen": 0.35, "rim": 0.3, "shade": 0.72},
	"Trim": {"sheen": 0.9, "rim": 0.45},
	"Nib": {"sheen": 1.0, "rim": 0.5},
	"Leather": {"shade": 0.5},
	"Wax": {"rim": 0.35, "emission": 0.12},
	"Eyes": {"emission": 3.5},
	"Gem": {"emission": 2.5},
	"Ink": {"rim": 0.6, "shade": 0.2},
	"InkGloss": {"rim": 0.9, "sheen": 0.8, "shade": 0.2},
	"Quill": {"rim": 0.25},
	"Paper": {"rim": 0.15, "paper": 0.16},
	"Cover": {"shade": 0.6},
	"Stone": {"paper": 0.12},
	"Wood": {"paper": 0.1},
	"Glow": {"emission": 2.0},
}

static var _cache := {}


static func material(name: String, col: Color, extra := {}) -> ShaderMaterial:
	var preset: Dictionary = PRESETS.get(name, {})
	var key := "%s|%s|%s" % [name, col.to_html(), str(extra)]
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("albedo", col)
	m.set_shader_parameter("shade_strength", float(extra.get("shade", preset.get("shade", 0.62))))
	m.set_shader_parameter("rim_strength", float(extra.get("rim", preset.get("rim", 0.28))))
	m.set_shader_parameter("sheen", float(extra.get("sheen", preset.get("sheen", 0.0))))
	m.set_shader_parameter("wobble_paper", float(extra.get("paper", preset.get("paper", 0.0))))
	var emission := float(extra.get("emission", preset.get("emission", 0.0)))
	if emission > 0.0:
		m.set_shader_parameter("emission_color", extra.get("emission_color", col))
		m.set_shader_parameter("emission_strength", emission)
	_cache[key] = m
	return m


## Walks `root` and swaps every surface material for its toon version.
## overrides: {"Cloth": Color(...), ...}
static func apply(root: Node, overrides := {}) -> void:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if not (n is MeshInstance3D):
			continue
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(s)
			var mat_name := src.resource_name if src else ""
			var col := Color.WHITE
			if src is BaseMaterial3D:
				col = (src as BaseMaterial3D).albedo_color
			if overrides.has(mat_name):
				col = overrides[mat_name]
			mi.set_surface_override_material(s, material(mat_name, col))


## Instantiates a model scene and applies toon materials.
static func spawn(path: String, overrides := {}) -> Node3D:
	var packed: PackedScene = load(path)
	var inst: Node3D = packed.instantiate()
	apply(inst, overrides)
	return inst


static func find_anim_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root
	for c in root.get_children():
		var a := find_anim_player(c)
		if a:
			return a
	return null


static func find_skeleton(root: Node) -> Skeleton3D:
	if root is Skeleton3D:
		return root
	for c in root.get_children():
		var s := find_skeleton(c)
		if s:
			return s
	return null

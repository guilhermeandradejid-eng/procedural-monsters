class_name Stage
extends RefCounted
## Builds the shared look of every 3D space: environment (tonemap, glow,
## SSAO, grading), candle-warm key light, cool fill, and the ink outline pass.

const OUTLINE := preload("res://shaders/ink_outline.gdshader")

## Per-chapter mood. paper/ink feed the page shader, light/ambient the scene.
const MOODS := {
	"hub": {"light": Color("ffe2b8"), "energy": 1.15, "fill": Color("8fa6d6"), "ambient": Color("6b5448"), "bg": Color("120c0b"),
		"paper": Color("efe2c4"), "paper_dark": Color("d9c49a"), "ink": Color("1c1411"), "rubric": Color("9e2b25")},
	"grove": {"light": Color("ffe0b0"), "energy": 1.2, "fill": Color("9bb8d8"), "ambient": Color("5e5040"), "bg": Color("0f0d09"),
		"paper": Color("efe2c4"), "paper_dark": Color("d6bf92"), "ink": Color("2a2016"), "rubric": Color("7a5a1c")},
	"catacombs": {"light": Color("ffc89a"), "energy": 1.25, "fill": Color("a07aa0"), "ambient": Color("503838"), "bg": Color("140909"),
		"paper": Color("e6d2ae"), "paper_dark": Color("c9a878"), "ink": Color("2a1210"), "rubric": Color("a3261e")},
	"inksea": {"light": Color("dfe8ff"), "energy": 1.2, "fill": Color("5e86c8"), "ambient": Color("38424f"), "bg": Color("070a12"),
		"paper": Color("dfe0d6"), "paper_dark": Color("b9bcae"), "ink": Color("101a2e"), "rubric": Color("27508a")},
}


static func mood(id: String) -> Dictionary:
	return MOODS.get(id, MOODS["hub"])


static func build(parent: Node3D, mood_id := "hub") -> Dictionary:
	var md := mood(mood_id)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = md.bg
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = md.ambient
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_strength = 0.95
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.05
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.6
	env.ssao_power = 1.4
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.06
	env.adjustment_saturation = 1.08
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	parent.add_child(we)
	var key := DirectionalLight3D.new()
	key.name = "Key"
	key.light_color = md.light
	key.light_energy = md.energy
	key.shadow_enabled = true
	key.shadow_blur = 1.6
	key.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	key.directional_shadow_max_distance = 70.0
	key.rotation_degrees = Vector3(-58.0, 32.0, 0.0)
	parent.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.name = "Fill"
	fill.light_color = md.fill
	fill.light_energy = 0.22
	fill.shadow_enabled = false
	fill.rotation_degrees = Vector3(-35.0, -150.0, 0.0)
	parent.add_child(fill)
	return {"environment": env, "key": key, "fill": fill}


## Full-screen ink outline quad; parent it to the active camera.
static func outline_quad() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "InkOutline"
	var q := QuadMesh.new()
	q.size = Vector2(2, 2)
	q.flip_faces = false
	mi.mesh = q
	var m := ShaderMaterial.new()
	m.shader = OUTLINE
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 16384.0
	mi.position = Vector3(0, 0, -1.0)
	return mi


static func page_material(mood_id: String, size: Vector2, seed := 0.0, writing := 0.55) -> ShaderMaterial:
	var md := mood(mood_id)
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/page.gdshader")
	m.set_shader_parameter("paper", md.paper)
	m.set_shader_parameter("paper_dark", md.paper_dark)
	m.set_shader_parameter("ink", md.ink)
	m.set_shader_parameter("rubric", md.rubric)
	m.set_shader_parameter("page_size", size)
	m.set_shader_parameter("seed", seed)
	m.set_shader_parameter("writing", writing)
	return m

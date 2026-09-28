extends Node
## Visual effect spawner: procedural particles, rings, ink splats, flashes,
## floating numbers, telegraphs and sigil textures. Gameplay code calls these
## without knowing which level is loaded.

const MOTE_ADD := preload("res://shaders/fx/mote_add.gdshader")
const MOTE_MIX := preload("res://shaders/fx/mote_mix.gdshader")
const RING := preload("res://shaders/fx/ring.gdshader")
const SPLAT := preload("res://shaders/fx/splat.gdshader")
const TELEGRAPH := preload("res://shaders/fx/telegraph.gdshader")
const MAX_SPLATS := 140

## Particle recipes. speed/scale are [min, max]; gravity is Y acceleration.
const KINDS := {
	"spark": {"shape": 2, "blend": "add", "amount": 14, "life": 0.35, "speed": [5.0, 11.0], "gravity": -9.0, "damping": 7.0, "scale": [0.09, 0.18], "spread": 180.0},
	"flame": {"shape": 5, "blend": "add", "amount": 12, "life": 0.6, "speed": [1.0, 3.5], "gravity": 4.0, "damping": 2.0, "scale": [0.16, 0.34], "spread": 60.0},
	"shard": {"shape": 1, "blend": "add", "amount": 12, "life": 0.5, "speed": [3.0, 8.0], "gravity": -14.0, "damping": 2.0, "scale": [0.1, 0.22], "spread": 180.0},
	"bubble": {"shape": 3, "blend": "add", "amount": 9, "life": 0.8, "speed": [0.6, 2.2], "gravity": 1.6, "damping": 1.0, "scale": [0.12, 0.28], "spread": 120.0},
	"twinkle": {"shape": 4, "blend": "add", "amount": 10, "life": 0.6, "speed": [1.0, 4.0], "gravity": 0.5, "damping": 3.0, "scale": [0.16, 0.34], "spread": 180.0},
	"glow": {"shape": 0, "blend": "add", "amount": 8, "life": 0.35, "speed": [0.5, 3.0], "gravity": 0.0, "damping": 4.0, "scale": [0.35, 0.7], "spread": 180.0},
	"implode": {"shape": 0, "blend": "add", "amount": 16, "life": 0.45, "speed": [0.0, 0.5], "gravity": 0.0, "damping": 0.0, "scale": [0.12, 0.24], "spread": 180.0, "radial": -18.0, "ring": 1.6},
	"ink": {"shape": 6, "blend": "mix", "amount": 14, "life": 0.55, "speed": [3.0, 7.5], "gravity": -20.0, "damping": 1.0, "scale": [0.1, 0.26], "spread": 70.0},
	"dust": {"shape": 0, "blend": "mix", "amount": 6, "life": 0.55, "speed": [0.4, 1.6], "gravity": 0.6, "damping": 2.5, "scale": [0.35, 0.7], "spread": 90.0},
	"paper": {"shape": 7, "blend": "mix", "amount": 8, "life": 1.3, "speed": [2.0, 5.5], "gravity": -4.0, "damping": 1.5, "scale": [0.16, 0.32], "spread": 80.0, "spin": 8.0},
}

var level: Node3D = null
var sigils: SigilBank
var _proc_cache := {}
var _draw_cache := {}
var _splats: Array[Node3D] = []
var _quad_flat: PlaneMesh
var _num_font: Font


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	sigils = SigilBank.new()
	sigils.name = "Sigils"
	add_child(sigils)
	_quad_flat = PlaneMesh.new()
	_quad_flat.size = Vector2(2, 2)


func register_level(l: Node3D) -> void:
	level = l
	_splats.clear()


func root() -> Node3D:
	if level and is_instance_valid(level) and level.is_inside_tree():
		var fx := level.get_node_or_null("Fx")
		return fx if fx else level
	return null


func _add(n: Node3D, pos: Vector3) -> bool:
	var r := root()
	if r == null:
		n.free()
		return false
	r.add_child(n)
	n.global_position = pos
	return true


# --- Particles ---------------------------------------------------------------------------
func _process_material(kind: String, col: Color, col2: Color) -> ParticleProcessMaterial:
	var key := "%s|%s|%s" % [kind, col.to_html(), col2.to_html()]
	if _proc_cache.has(key):
		return _proc_cache[key]
	var k: Dictionary = KINDS.get(kind, KINDS["glow"])
	var m := ParticleProcessMaterial.new()
	if k.has("ring"):
		m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
		m.emission_ring_axis = Vector3.UP
		m.emission_ring_radius = k.ring
		m.emission_ring_inner_radius = k.ring * 0.8
		m.emission_ring_height = 0.2
	else:
		m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		m.emission_sphere_radius = 0.2
	m.direction = Vector3.UP
	m.spread = k.get("spread", 180.0)
	m.initial_velocity_min = k.speed[0]
	m.initial_velocity_max = k.speed[1]
	m.gravity = Vector3(0, k.get("gravity", 0.0), 0)
	m.damping_min = k.get("damping", 0.0)
	m.damping_max = k.get("damping", 0.0) * 1.3
	m.scale_min = k.scale[0]
	m.scale_max = k.scale[1]
	m.angle_min = -180.0
	m.angle_max = 180.0
	if k.has("spin"):
		m.angular_velocity_min = -k.spin * 60.0
		m.angular_velocity_max = k.spin * 60.0
	if k.has("radial"):
		m.radial_accel_min = k.radial
		m.radial_accel_max = k.radial * 0.7
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.3))
	curve.add_point(Vector2(0.15, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	var ct := CurveTexture.new()
	ct.curve = curve
	m.scale_curve = ct
	var g := Gradient.new()
	g.set_color(0, Color(col.r, col.g, col.b, 1.0))
	g.set_color(1, Color(col2.r, col2.g, col2.b, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	m.color_ramp = gt
	_proc_cache[key] = m
	return m


func _draw_mesh(kind: String) -> QuadMesh:
	if _draw_cache.has(kind):
		return _draw_cache[kind]
	var k: Dictionary = KINDS.get(kind, KINDS["glow"])
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	var mat := ShaderMaterial.new()
	mat.shader = MOTE_ADD if k.blend == "add" else MOTE_MIX
	mat.set_shader_parameter("shape", k.shape)
	q.material = mat
	_draw_cache[kind] = q
	return q


func _make_particles(kind: String, col: Color, col2: Color, amount: int, life_mult := 1.0) -> GPUParticles3D:
	var k: Dictionary = KINDS.get(kind, KINDS["glow"])
	var p := GPUParticles3D.new()
	p.amount = maxi(1, amount)
	p.lifetime = k.life * life_mult
	p.local_coords = false
	p.process_material = _process_material(kind, col, col2)
	p.draw_pass_1 = _draw_mesh(kind)
	p.visibility_aabb = AABB(Vector3(-10, -4, -10), Vector3(20, 14, 20))
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p


## One-shot burst that frees itself.
func burst(pos: Vector3, kind: String, col: Color, col2 := Color(0, 0, 0, 0), amount := -1, scale := 1.0, dir := Vector3.ZERO) -> void:
	if col2.a == 0.0 and col2 == Color(0, 0, 0, 0):
		col2 = col
	var k: Dictionary = KINDS.get(kind, KINDS["glow"])
	var p := _make_particles(kind, col, col2, amount if amount > 0 else int(k.amount), 1.0)
	p.one_shot = true
	p.explosiveness = 0.92
	p.randomness = 0.4
	p.speed_scale = 1.0
	if scale != 1.0:
		p.scale = Vector3.ONE * scale
	if not _add(p, pos):
		return
	if dir != Vector3.ZERO:
		# Point the emitter's local +Y (its emission direction) along `dir`.
		var nd := dir.normalized()
		var up := Vector3.UP if absf(nd.dot(Vector3.UP)) < 0.99 else Vector3.FORWARD
		p.basis = Basis.looking_at(nd, up) * Basis(Vector3.RIGHT, -PI * 0.5)
	p.emitting = true
	get_tree().create_timer(p.lifetime + 0.4, false).timeout.connect(p.queue_free)


## Continuous emitter parented to `parent`; call stop_emitter() when done.
func emitter(parent: Node3D, kind: String, col: Color, col2: Color, amount: int, life_mult := 1.0) -> GPUParticles3D:
	var p := _make_particles(kind, col, col2, amount, life_mult)
	p.explosiveness = 0.0
	p.randomness = 0.5
	parent.add_child(p)
	p.emitting = true
	return p


func stop_emitter(p: GPUParticles3D) -> void:
	if p == null or not is_instance_valid(p):
		return
	p.emitting = false
	var r := root()
	if r and p.get_parent() != r:
		var gt := p.global_transform
		p.get_parent().remove_child(p)
		r.add_child(p)
		p.global_transform = gt
	get_tree().create_timer(p.lifetime + 0.2, false).timeout.connect(p.queue_free)


# --- Flat effects on the page -------------------------------------------------------
func ring(pos: Vector3, radius: float, col: Color, core := Color.WHITE, duration := 0.35, thickness := 0.14, glow := 3.0) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = _quad_flat
	var mat := ShaderMaterial.new()
	mat.shader = RING
	mat.set_shader_parameter("color", col)
	mat.set_shader_parameter("core", core)
	mat.set_shader_parameter("glow", glow)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not _add(mi, Vector3(pos.x, 0.06, pos.z)):
		return
	mi.scale = Vector3.ONE * radius
	mi.set_instance_shader_parameter(&"thickness", thickness)
	mi.set_instance_shader_parameter(&"seed", randf() * 10.0)
	var t := mi.create_tween()
	t.tween_method(func(v: float): mi.set_instance_shader_parameter(&"progress", v), 0.0, 1.0, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_callback(mi.queue_free)


## Ink splat that stays on the page (oldest ones fade when the cap is reached).
func splat(pos: Vector3, size: float, tint := Pal.INK) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = _quad_flat
	var mat := _splat_material()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not _add(mi, Vector3(pos.x, 0.012 + randf() * 0.01, pos.z)):
		return
	mi.rotation.y = randf() * TAU
	mi.scale = Vector3.ONE * size
	mi.set_instance_shader_parameter(&"seed", randf() * 100.0)
	mi.set_instance_shader_parameter(&"tint", tint)
	mi.set_instance_shader_parameter(&"grow", 0.3)
	var t := mi.create_tween()
	t.tween_method(func(v: float): mi.set_instance_shader_parameter(&"grow", v), 0.3, 1.0, 0.14).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_splats.append(mi)
	while _splats.size() > MAX_SPLATS:
		var old: Node3D = _splats.pop_front()
		if is_instance_valid(old):
			var ft := old.create_tween()
			ft.tween_method(func(v: float): old.set_instance_shader_parameter(&"fade", v), 1.0, 0.0, 0.6)
			ft.tween_callback(old.queue_free)


var _splat_mat: ShaderMaterial


func _splat_material() -> ShaderMaterial:
	if _splat_mat == null:
		_splat_mat = ShaderMaterial.new()
		_splat_mat.shader = SPLAT
	return _splat_mat


func light_flash(pos: Vector3, col: Color, energy := 4.0, range_ := 5.0, duration := 0.18) -> void:
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = range_
	l.shadow_enabled = false
	if not _add(l, pos + Vector3.UP * 1.0):
		return
	var t := l.create_tween()
	t.tween_property(l, "light_energy", 0.0, duration).set_ease(Tween.EASE_IN)
	t.tween_callback(l.queue_free)


## Ground warning for enemy attacks. shape: 0 circle, 1 cone, 2 line.
func telegraph(pos: Vector3, shape: int, size: Vector2, duration: float, facing := Vector3.FORWARD, half_angle := 0.6, col := Pal.TELEGRAPH) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2, 2)
	if shape == 2:
		pm.center_offset = Vector3(0, 0, -1)
	mi.mesh = pm
	var mat := ShaderMaterial.new()
	mat.shader = TELEGRAPH
	mat.set_shader_parameter("color", col)
	mat.set_shader_parameter("shape", shape)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not _add(mi, Vector3(pos.x, 0.035, pos.z)):
		return null
	var f := Combat.flat(facing)
	if f.length() > 0.01:
		mi.look_at(mi.global_position + f.normalized(), Vector3.UP)
	mi.scale = Vector3(size.x, 1.0, size.y)
	mi.set_instance_shader_parameter(&"half_angle", half_angle)
	var t := mi.create_tween()
	t.tween_method(func(v: float): mi.set_instance_shader_parameter(&"charge", v), 0.0, 1.0, duration)
	t.tween_method(func(v: float): mi.set_instance_shader_parameter(&"fade", v), 1.0, 0.0, 0.12)
	t.tween_callback(mi.queue_free)
	return mi


# --- Floating text ----------------------------------------------------------------------
func _numbers_font() -> Font:
	if _num_font == null:
		_num_font = UiFonts.numbers()
	return _num_font


func damage_number(pos: Vector3, amount: float, col: Color, crit := false, small := false) -> void:
	if not Game.settings.get("damage_numbers", true) or amount < 0.5:
		return
	var txt := str(int(round(amount)))
	if crit:
		txt += "!"
	var size := 58 if crit else (30 if small else 42)
	var c := col.lerp(Color.WHITE, 0.25) if not crit else Pal.GOLD_BRIGHT
	_float_text(pos, txt, c, size, crit)


func heal_number(pos: Vector3, amount: float) -> void:
	_float_text(pos, "+%d" % int(round(amount)), Pal.HEAL, 40, false)


func text_pop(pos: Vector3, text: String, col: Color, size := 46) -> void:
	_float_text(pos, text, col, size, true, 0.9)


func _float_text(pos: Vector3, txt: String, col: Color, size: int, big: bool, hold := 0.45) -> void:
	var l := Label3D.new()
	l.text = txt
	l.font = _numbers_font()
	l.font_size = size
	l.outline_size = int(size * 0.28)
	l.outline_modulate = Pal.INK
	l.modulate = col
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = true
	l.pixel_size = 0.00055
	l.render_priority = 10
	l.outline_render_priority = 9
	var jitter := Vector3(randf_range(-0.35, 0.35), 0.0, randf_range(-0.2, 0.2))
	if not _add(l, pos + jitter):
		return
	l.scale = Vector3.ONE * 0.4
	var t := l.create_tween()
	t.set_parallel(true)
	t.tween_property(l, "scale", Vector3.ONE * (1.25 if big else 1.0), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "global_position", l.global_position + Vector3(jitter.x * 0.8, 1.1, 0.0), 0.7).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	t.chain().tween_property(l, "scale", Vector3.ONE, 0.08)
	t.tween_property(l, "modulate:a", 0.0, 0.25).set_delay(hold)
	t.tween_property(l, "outline_modulate:a", 0.0, 0.25).set_delay(hold)
	t.chain().tween_callback(l.queue_free)

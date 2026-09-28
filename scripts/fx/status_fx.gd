class_name StatusFx
extends Node3D
## Shows an actor's conditions: flames when burning, bubbles when poisoned,
## an ice shell when frozen, a void mark over the head, stun stars, chill tint.

var actor: Actor
var _burn: GPUParticles3D
var _venom: GPUParticles3D
var _ice: MeshInstance3D
var _mark: MeshInstance3D
var _stun: Node3D
var _last_tint := Color(0, 0, 0, 0)
static var _ice_mat: ShaderMaterial
static var _mark_mat: ShaderMaterial


func _height() -> float:
	var h = actor.get("height")
	return float(h) if h != null else 1.6


func _process(delta: float) -> void:
	if actor == null or not is_instance_valid(actor) or actor.dead:
		return
	var st := actor.status
	_burn = _toggle_emitter(_burn, st.burning(), "flame", Elem.main_color("ember"), Color("a8230e"), 14)
	_venom = _toggle_emitter(_venom, st.poisoned(), "bubble", Elem.main_color("venom"), Color("3b6e1f"), 4 + st.venom_stacks * 2)
	_update_ice(st.frozen())
	_update_mark(st.marked(), delta)
	_update_stun(st.stun_time > 0.0 and not st.frozen(), delta)
	var tint := Color(0, 0, 0, 0)
	if st.frozen():
		tint = Color(0.75, 0.95, 1.0, 0.55)
	elif st.chill_stacks > 0:
		tint = Color(0.6, 0.9, 1.0, 0.15 * st.chill_stacks)
	elif st.entropy_time > 0.0:
		tint = Color(0.4, 0.45, 1.0, 0.3)
	elif st.poisoned():
		tint = Color(0.55, 1.0, 0.35, 0.05 * st.venom_stacks)
	if not tint.is_equal_approx(_last_tint):
		_last_tint = tint
		actor.set_shader_instance(&"tint", tint)


func _toggle_emitter(em: GPUParticles3D, on: bool, kind: String, c1: Color, c2: Color, amount: int) -> GPUParticles3D:
	if on and (em == null or not is_instance_valid(em)):
		em = Fx.emitter(self, kind, c1, c2, amount, 1.0)
		em.position = Vector3.UP * _height() * 0.55
		var pm := em.process_material as ParticleProcessMaterial
		if pm:
			pm.emission_sphere_radius = actor.radius * 0.8
		return em
	if not on and em != null and is_instance_valid(em):
		Fx.stop_emitter(em)
		return null
	return em


func _update_ice(on: bool) -> void:
	if on and _ice == null:
		if _ice_mat == null:
			_ice_mat = ShaderMaterial.new()
			_ice_mat.shader = preload("res://shaders/fx/energy.gdshader")
			var pal := Elem.palette("frost")
			_ice_mat.set_shader_parameter("core_color", Color(1, 1, 1))
			_ice_mat.set_shader_parameter("main_color", pal.main)
			_ice_mat.set_shader_parameter("dark_color", pal.dark)
			_ice_mat.set_shader_parameter("rim_color", pal.rim)
			_ice_mat.set_shader_parameter("glow", 1.2)
			_ice_mat.set_shader_parameter("wobble", 0.0)
			_ice_mat.set_shader_parameter("pulse_hz", 0.0)
		_ice = MeshInstance3D.new()
		_ice.mesh = SpellMeshes.rock(3)
		_ice.material_override = _ice_mat
		_ice.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_ice)
		var r := actor.radius * 1.5
		_ice.position = Vector3.UP * _height() * 0.45
		_ice.scale = Vector3(r, _height() * 0.6, r) * 0.2
		_ice.set_instance_shader_parameter(&"fade", 0.55)
		var t := _ice.create_tween()
		t.tween_property(_ice, "scale", Vector3(r, _height() * 0.6, r), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	elif not on and _ice != null:
		Fx.burst(_ice.global_position, "shard", Color.WHITE, Color("5aa9ff"), 10, 0.8)
		_ice.queue_free()
		_ice = null


func _update_mark(on: bool, delta: float) -> void:
	if on and _mark == null:
		if _mark_mat == null:
			_mark_mat = ShaderMaterial.new()
			_mark_mat.shader = preload("res://shaders/fx/ring.gdshader")
			_mark_mat.set_shader_parameter("color", Elem.main_color("void"))
			_mark_mat.set_shader_parameter("core", Color("ffb3fa"))
			_mark_mat.set_shader_parameter("glow", 2.5)
		_mark = MeshInstance3D.new()
		_mark.mesh = SpellMeshes.flat_quad()
		_mark.material_override = _mark_mat
		_mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_mark)
		_mark.position = Vector3.UP * (_height() + 0.5)
		_mark.scale = Vector3.ONE * 0.45
		_mark.set_instance_shader_parameter(&"progress", 0.6)
		_mark.set_instance_shader_parameter(&"thickness", 0.25)
	elif not on and _mark != null:
		_mark.queue_free()
		_mark = null
	if _mark:
		_mark.rotate_y(delta * 3.0)


func _update_stun(on: bool, delta: float) -> void:
	if on and _stun == null:
		_stun = Node3D.new()
		add_child(_stun)
		_stun.position = Vector3.UP * (_height() + 0.35)
		for i in 3:
			var l := Label3D.new()
			l.text = "✦"
			l.font_size = 48
			l.modulate = Pal.GOLD_BRIGHT
			l.outline_modulate = Pal.INK
			l.outline_size = 10
			l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			l.pixel_size = 0.006
			var a := TAU * i / 3.0
			l.position = Vector3(cos(a), 0, sin(a)) * 0.45
			_stun.add_child(l)
	elif not on and _stun != null:
		_stun.queue_free()
		_stun = null
	if _stun:
		_stun.rotate_y(delta * 5.0)

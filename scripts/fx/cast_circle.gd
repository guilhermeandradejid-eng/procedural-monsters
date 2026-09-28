class_name CastCircle
extends RefCounted
## The spell's own sigil drawn on the floor (and in the air for aimed forms)
## while the knight casts: the page literally signs itself into the world.


static func spawn(p: Node3D, prog: SpellProgram, duration: float) -> void:
	if Level.current == null or prog == null or prog.root == null:
		return
	var v := SpellVisual.for_clause(prog.root, prog.dominant_form())
	var tex := Fx.sigils.for_program(prog)
	var ground := _quad(tex, v, 1.6)
	Level.current.add_fx(ground)
	ground.global_position = p.global_position + Vector3.UP * 0.04
	_animate(ground, duration, 1.9)
	var aim: int = GlyphDB.FORMS[prog.dominant_form()].aim
	if aim == GlyphDB.Aim.DIRECTION and p.has_method("aim_state"):
		var st: Dictionary = p.aim_state()
		var front := _quad(tex, v, 2.4)
		Level.current.add_fx(front)
		var d: Vector3 = st.dir
		front.global_position = p.global_position + d * 0.9 + Vector3.UP * 0.95
		# Stand the quad up, facing along the aim direction.
		front.global_transform.basis = Basis.looking_at(d, Vector3.UP) * Basis(Vector3.RIGHT, PI * 0.5)
		_animate(front, duration, 0.85)
	Audio.play("sigil", p.global_position, -10.0, 1.0 + float(prog.seed % 9) * 0.02, 0.05)


static func _quad(tex: Texture2D, v: SpellVisual, spin: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = SpellMeshes.flat_quad()
	mi.material_override = SpellFx.sigil_material(tex, v.main, v.core, spin)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func _animate(mi: MeshInstance3D, duration: float, size: float) -> void:
	mi.scale = Vector3.ONE * size * 0.6
	mi.set_instance_shader_parameter(&"reveal", 0.0)
	mi.set_instance_shader_parameter(&"spin_offset", randf() * TAU)
	var t := mi.create_tween()
	t.set_parallel(true)
	t.tween_method(func(f: float): mi.set_instance_shader_parameter(&"reveal", f), 0.0, 1.0, minf(0.16, duration * 0.6))
	t.tween_property(mi, "scale", Vector3.ONE * size, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.chain().tween_method(func(f: float): mi.set_instance_shader_parameter(&"fade", f), 1.0, 0.0, 0.3).set_delay(maxf(0.05, duration - 0.15))
	t.chain().tween_callback(mi.queue_free)

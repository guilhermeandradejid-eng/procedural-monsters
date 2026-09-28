class_name SwingFx
extends RefCounted
## Ink brush-stroke arcs for the quill combo.

const SHADER := preload("res://shaders/fx/slash.gdshader")

static var _meshes := {}
static var _mats := {}
static var _flip := false


## Flat ring-sector with UVs: x along the arc, y from inner to outer radius.
static func arc_mesh(arc_deg: float) -> ArrayMesh:
	var key := int(arc_deg)
	if _meshes.has(key):
		return _meshes[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 24
	var half := deg_to_rad(arc_deg) * 0.5
	for i in seg:
		var a0 := lerpf(-half, half, float(i) / seg)
		var a1 := lerpf(-half, half, float(i + 1) / seg)
		var u0 := float(i) / seg
		var u1 := float(i + 1) / seg
		var d0 := Vector3(sin(a0), 0.0, cos(a0))
		var d1 := Vector3(sin(a1), 0.0, cos(a1))
		var quad := [[d0 * 0.45, Vector2(u0, 0)], [d0, Vector2(u0, 1)], [d1, Vector2(u1, 1)], [d1 * 0.45, Vector2(u1, 0)]]
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_uv(quad[k][1])
			st.add_vertex(quad[k][0])
	var m := st.commit()
	_meshes[key] = m
	return m


static func _material(col: Color) -> ShaderMaterial:
	var key := col.to_html()
	if not _mats.has(key):
		var m := ShaderMaterial.new()
		m.shader = SHADER
		m.set_shader_parameter("rim", col)
		_mats[key] = m
	return _mats[key]


static func slash(p: Player, dir: Vector3, radius: float, arc_deg: float, finisher: bool) -> void:
	if Level.current == null:
		return
	var mi := MeshInstance3D.new()
	mi.mesh = arc_mesh(arc_deg)
	mi.material_override = _material(p.profile.flame_color())
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Level.current.add_fx(mi)
	mi.global_position = p.global_position + Vector3.UP * (0.75 if not finisher else 0.25)
	mi.rotation.y = atan2(dir.x, dir.z)
	mi.scale = Vector3.ONE * radius * (1.0 if not finisher else 1.1)
	_flip = not _flip
	mi.set_instance_shader_parameter(&"reverse", 1.0 if _flip else 0.0)
	mi.set_instance_shader_parameter(&"seed", randf() * 10.0)
	var t := mi.create_tween()
	t.tween_method(func(v: float): mi.set_instance_shader_parameter(&"progress", v), 0.0, 1.0, 0.11)
	t.tween_method(func(v: float): mi.set_instance_shader_parameter(&"fade", v), 1.0, 0.0, 0.14)
	t.tween_callback(mi.queue_free)
	if finisher:
		Fx.ring(p.global_position + dir * 1.2, 1.6, p.profile.flame_color(), Pal.PAPER_LIGHT, 0.3, 0.12, 2.0)

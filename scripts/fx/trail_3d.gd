class_name Trail3D
extends MeshInstance3D
## Camera-facing ribbon that follows a node. When its owner dies the trail is
## detached and keeps fading out on its own instead of popping.

var target: Node3D
var width := 0.5
var lifetime := 0.22
var min_step := 0.06
var detached := false
var _pts: Array[Vector3] = []
var _times: Array[float] = []
var _clock := 0.0
var _imm := ImmediateMesh.new()


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	mesh = _imm
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extra_cull_margin = 64.0


func detach() -> void:
	if detached:
		return
	detached = true
	var p := get_parent()
	if p and Level.current and p != Level.current.fx:
		var gt := global_transform
		p.remove_child(self)
		Level.current.fx.add_child(self)
		global_transform = gt


func _process(delta: float) -> void:
	_clock += delta
	if not detached and is_instance_valid(target) and target.is_inside_tree():
		var p := target.global_position
		if _pts.is_empty() or _pts[0].distance_to(p) > min_step:
			_pts.push_front(p)
			_times.push_front(_clock)
		else:
			_pts[0] = p
			_times[0] = _clock
	elif not detached:
		detach()
	while not _times.is_empty() and _clock - _times[-1] > lifetime:
		_pts.pop_back()
		_times.pop_back()
	if detached and _pts.size() < 2:
		queue_free()
		return
	_rebuild()


func _rebuild() -> void:
	_imm.clear_surfaces()
	var n := _pts.size()
	if n < 2:
		return
	var cam := get_viewport().get_camera_3d()
	var cam_pos := cam.global_position if cam else Vector3(0, 30, 20)
	_imm.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in n:
		var p := _pts[i]
		var a := _pts[maxi(i - 1, 0)]
		var b := _pts[mini(i + 1, n - 1)]
		var tangent := (a - b)
		if tangent.length() < 0.0001:
			tangent = Vector3.FORWARD
		var to_cam := (cam_pos - p).normalized()
		var side := tangent.cross(to_cam).normalized()
		var age := (_clock - _times[i]) / lifetime
		var w := width * 0.5 * (1.0 - age * 0.7)
		var u := float(i) / float(n - 1)
		var alpha := 1.0 - clampf(age, 0.0, 1.0)
		_imm.surface_set_color(Color(1, 1, 1, alpha))
		_imm.surface_set_uv(Vector2(u, 0.0))
		_imm.surface_add_vertex(p + side * w)
		_imm.surface_set_color(Color(1, 1, 1, alpha))
		_imm.surface_set_uv(Vector2(u, 1.0))
		_imm.surface_add_vertex(p - side * w)
	_imm.surface_end()

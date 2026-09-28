extends SpellEntity
## Serpent: a winding head that hunts, dragging a chain of hurting segments.

const HEIGHT := 0.7
const SPACING := 0.55

var velocity := Vector3.ZERO
var segments: Array[Vector3] = []
var _trail: Array[Vector3] = []
var _head := Vector3.ZERO
var _phase := 0.0


func _on_spawn() -> void:
	_head = Vector3(origin.x, HEIGHT, origin.z)
	position = _head
	velocity = dir * speed()
	var n := int(fdef.get("count", 6)) + 2 * clause.mod("grow")
	for i in n:
		segments.append(_head)
	_trail.append(_head)


func _tick(delta: float) -> void:
	# Hunt: turn toward the nearest target in a wide cone.
	var tgt := cast.target_in_cone(_head, dir, 12.0, -0.2, exclude)
	if tgt:
		var want := Combat.flat(tgt.global_position - _head).normalized()
		var ang := Combat.flat(velocity).normalized().signed_angle_to(want, Vector3.UP)
		velocity = velocity.rotated(Vector3.UP, clampf(ang, -2.8 * delta, 2.8 * delta) * (1.0 + clause.mod("seek")))
	dir = Combat.flat(velocity).normalized()
	_phase += delta * 9.0
	var side := Vector3(-dir.z, 0.0, dir.x)
	var prev := _head
	_head += velocity * delta + side * cos(_phase) * 5.5 * delta
	var hit := Combat.ray(get_world_3d(), prev, _head)
	if not hit.is_empty():
		finish(hit.position)
		return
	global_position = _head
	_trail.push_front(_head)
	if _trail.size() > 256:
		_trail.pop_back()
	_place_segments()
	var seg_r := radius * (0.9 if clause.mod("grow") == 0 else 1.2)
	for i in segments.size():
		var p := Vector3(segments[i].x, 0.0, segments[i].z)
		for t in cast.targets_near(p, seg_r):
			if can_hit(t, 0.35):
				deal(t, 1.0, dir)
				if finished:
					return
	if age >= life:
		finish()


func _place_segments() -> void:
	var dist := 0.0
	var seg := 0
	for i in range(1, _trail.size()):
		dist += _trail[i - 1].distance_to(_trail[i])
		while seg < segments.size() and dist >= SPACING * (seg + 1):
			segments[seg] = _trail[i]
			seg += 1
		if seg >= segments.size():
			break
	for j in range(seg, segments.size()):
		segments[j] = _trail[-1]

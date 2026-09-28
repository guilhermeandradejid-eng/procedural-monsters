extends SpellEntity
## Lance: an instantaneous piercing line, stopped only by walls.

var end_point := Vector3.ZERO
var _fired := false


func _on_spawn() -> void:
	position = Vector3(origin.x, 0.9, origin.z)
	var length: float = float(fdef.get("length", 11.0)) * pow(1.2, clause.mod("grow")) * pow(1.15, clause.mod("swift"))
	var a := Vector3(origin.x, 0.9, origin.z)
	var b := a + dir * length
	var hit := Combat.ray(get_world_3d(), a, b)
	if not hit.is_empty():
		b = hit.position
	end_point = Vector3(b.x, 0.0, b.z)
	life = 0.22
	look_at(Vector3(b.x, 0.9, b.z), Vector3.UP)


func _tick(_delta: float) -> void:
	if not _fired:
		_fired = true
		var a := Vector3(origin.x, 0.0, origin.z)
		var width := radius
		var targets := cast.targets_on_segment(a, end_point, width)
		targets.sort_custom(func(x, y): return Combat.flat_dist(x.global_position, a) < Combat.flat_dist(y.global_position, a))
		var pierces := 9999
		for t in targets:
			if not can_hit(t):
				continue
			deal(t, 1.0, dir)
			pierces -= 1
			if finished or pierces <= 0:
				break
		SpellFx.lance_fired(self)
		Juice.shake(0.12)
	if age >= life:
		finish(end_point)

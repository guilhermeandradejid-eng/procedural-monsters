extends SpellEntity
## Satellites: orbs circling the caster (or the payload point).

const HEIGHT := 0.9

var angle := 0.0
var sat_positions: Array[Vector3] = []
var _center := Vector3.ZERO


func _on_spawn() -> void:
	_center = Vector3(origin.x, 0.0, origin.z)
	position = _center
	sat_positions.resize(orbit_count)
	angle = cast.rng.randf() * TAU


func _anchor() -> Vector3:
	if clause.depth == 0 and cast.caster_alive():
		var c := cast.caster.global_position
		return Vector3(c.x, 0.0, c.z)
	return _center


func _tick(delta: float) -> void:
	_center = _anchor()
	global_position = _center
	angle += delta * 3.3 * pow(1.3, clause.mod("swift"))
	var orbit_r: float = float(fdef.get("radius", 2.2)) * pow(1.25, clause.mod("grow"))
	var hit_r := 0.55 * pow(1.3, clause.mod("grow"))
	for i in orbit_count:
		var a := angle + TAU * float(i) / float(orbit_count)
		var wob := 1.0 + 0.12 * sin(age * 5.0 + i) if clause.has_mod("spiral") else 1.0
		var p := _center + Vector3(cos(a), 0.0, sin(a)) * orbit_r * wob
		sat_positions[i] = p + Vector3.UP * HEIGHT
		for t in cast.targets_near(p, hit_r):
			if can_hit(t, 0.4):
				deal(t, 1.0, Vector3(-sin(a), 0.0, cos(a)))
				if finished:
					return
	if age >= life:
		finish(_center)

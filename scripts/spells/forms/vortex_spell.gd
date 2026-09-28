extends SpellEntity
## Vortex: a singularity that drags targets in and grinds them.

var _tick_timer := 0.0


func _on_spawn() -> void:
	position = Vector3(target.x, 0.05, target.z)


func _tick(delta: float) -> void:
	var center := Combat.flat(global_position)
	var pull := 11.0 * (1.0 + 0.5 * clause.mod("magnet")) * (1.0 + 0.4 * clause.mod("heavy"))
	for t in cast.targets_near(center, radius):
		var to := center - Combat.flat(t.global_position)
		var d := to.length()
		if d > 0.35 and not t.get("is_boss"):
			t.knock += to / d * pull * delta * clampf(d / radius + 0.4, 0.4, 1.2)
	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = 0.25
		explode(center, radius * 0.6, 1.0, 0.24)
	if age >= life:
		finish(center)

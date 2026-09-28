extends SpellEntity
## Nova: an expanding ring around its origin. Also used for Volatile bursts.

const EXPAND_TIME := 0.2

var ring := 0.0


func _on_spawn() -> void:
	position = Vector3(origin.x, 0.05, origin.z)
	life = EXPAND_TIME + 0.12
	if not secondary:
		Juice.shake(0.22 + 0.06 * clause.mod("grow"))


func _tick(_delta: float) -> void:
	ring = radius * clampf(age / EXPAND_TIME, 0.0, 1.0)
	var center := Vector3(global_position.x, 0.0, global_position.z)
	for t in cast.targets_near(center, ring):
		if can_hit(t):
			var kd := Combat.flat(t.global_position - center)
			deal(t, 1.0, kd if kd.length() > 0.1 else dir)
			if finished:
				return
	if age >= life:
		finish(center)

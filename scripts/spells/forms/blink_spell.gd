extends SpellEntity
## Step: teleports the caster and wounds everything around the arrival point.
## As a payload it pulls the caster to the event — a bolt that "carries" you.

var arrived := false
var from_pos := Vector3.ZERO
var to_pos := Vector3.ZERO


func _on_spawn() -> void:
	from_pos = Combat.flat(origin)
	if cast.caster_alive():
		from_pos = Combat.flat(cast.caster.global_position)
	var dest := from_pos + dir * float(fdef.get("range", 6.5)) * pow(1.2, clause.mod("swift"))
	if clause.depth > 0:
		dest = Combat.flat(origin)
	var hit := Combat.ray(get_world_3d(), from_pos + Vector3.UP * 0.6, dest + Vector3.UP * 0.6)
	if not hit.is_empty():
		dest = Combat.flat(hit.position) - dir * 0.6
	to_pos = dest
	position = to_pos
	life = 0.3


func _tick(_delta: float) -> void:
	if not arrived:
		arrived = true
		if cast.caster_alive() and cast.caster.has_method("teleport_to"):
			cast.caster.teleport_to(to_pos, 0.3)
		SpellFx.blink_trail(self, from_pos, to_pos)
		explode(to_pos, radius)
	if age >= life:
		finish(to_pos)

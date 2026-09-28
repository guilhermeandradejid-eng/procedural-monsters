extends SpellEntity
## Sentinel: an obelisk that keeps casting bolts of its essence on its own.

var _shot_timer := 0.3


func _on_spawn() -> void:
	var p := origin + dir * 1.3
	var hit := Combat.ray(get_world_3d(), origin + Vector3.UP * 0.5, p + Vector3.UP * 0.5)
	if not hit.is_empty():
		p = origin
	position = Vector3(p.x, 0.0, p.z)


func _tick(delta: float) -> void:
	_shot_timer -= delta
	if _shot_timer <= 0.0:
		_shot_timer = float(fdef.get("rate", 0.7)) * pow(0.8, clause.mod("swift"))
		var eye := global_position + Vector3.UP * 1.6
		var t := cast.nearest_target(eye, float(fdef.get("radius", 10.0)))
		if t:
			var d := Combat.flat(t.global_position - global_position).normalized()
			var shots := 1 + clause.mod("split")
			for i in shots:
				var a := (i - (shots - 1) * 0.5) * deg_to_rad(12.0)
				var s: SpellEntity = SpellRunner.FORM_SCRIPTS["bolt"].new()
				s.setup(cast, clause, "bolt", Combat.flat(eye) + d * 0.4, d.rotated(Vector3.UP, a), t.global_position, power * 0.5, [])
				s.secondary = true
				s.inherit_links = clause.link == "on_hit" or clause.link == "on_kill"
				Level.current.add_spell(s)
			SpellFx.totem_shot(self)
	if age >= life:
		finish(Combat.flat(global_position))

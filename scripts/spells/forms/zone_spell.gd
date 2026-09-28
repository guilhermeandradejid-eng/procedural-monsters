class_name ZoneSpell
extends SpellEntity
## Ground zones left by Linger and some fusions (Steam, Miasma, Sap).

const TICK := 0.35

var zone_kind := "linger"
var _t := 0.0


func _on_spawn() -> void:
	position = Vector3(origin.x, 0.03, origin.z)


func _tick(delta: float) -> void:
	_t -= delta
	if _t <= 0.0:
		_t = TICK
		var center := Combat.flat(global_position)
		match zone_kind:
			"sap":
				Elements.heal_allies(cast, center, radius, 1.6 * maxf(clause.potency(), 1.0))
				for t in cast.targets_near(center, radius):
					t.status.add_venom(1, 0.6)
			"steam":
				for t in cast.targets_near(center, radius):
					t.status.add_burn(2.5 * cast.might(), 1.5)
					t.status.add_slow(0.35, 0.6)
				explode(center, radius, 0.6, TICK * 0.9)
			"miasma":
				for t in cast.targets_near(center, radius):
					t.status.add_venom(1, 0.7)
					t.status.add_slow(0.2, 0.6)
			_:
				explode(center, radius, 1.0, TICK * 0.9)
	if age >= life:
		finish(Combat.flat(global_position))

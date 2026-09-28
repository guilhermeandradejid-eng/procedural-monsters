extends SpellEntity
## Rune: a sigil trap written on the page. Detonates when stepped on.

const ARM_TIME := 0.35
const TRIGGER_RADIUS := 1.3

var armed := false
var detonated := false


func _on_spawn() -> void:
	position = Vector3(target.x, 0.02, target.z)


func _tick(_delta: float) -> void:
	if detonated:
		if age >= life:
			finish(global_position)
		return
	if not armed and age >= ARM_TIME:
		armed = true
		SpellFx.mine_armed(self)
	if armed and not cast.targets_near(Combat.flat(global_position), TRIGGER_RADIUS * pow(1.2, clause.mod("grow"))).is_empty():
		_detonate()
	elif age >= float(fdef.get("life", 6.0)):
		_detonate()


func _detonate() -> void:
	detonated = true
	explode(global_position, radius)
	SpellFx.big_impact(self, Combat.flat(global_position), radius)
	Juice.shake(0.3)
	life = age + 0.1

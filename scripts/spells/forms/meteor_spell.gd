extends SpellEntity
## Meteor: a telegraphed, delayed, enormous impact.

var delay := 0.7
var landed := false


func _on_spawn() -> void:
	position = Vector3(target.x, 0.0, target.z)
	delay = float(fdef.get("delay", 0.7)) * pow(0.8, clause.mod("swift"))
	life = delay + 0.25


func _tick(_delta: float) -> void:
	if not landed and age >= delay:
		landed = true
		explode(global_position, radius)
		SpellFx.big_impact(self, Combat.flat(global_position), radius)
		Juice.shake(0.55 + 0.1 * clause.mod("grow"))
		Juice.punch(0.06)
		Juice.hitstop(0.05)
	if age >= life:
		finish(global_position)

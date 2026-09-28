extends SpellEntity
## Rain: a volley of impacts falling over the target area.

const FALL_TIME := 0.28

var drops: Array[Dictionary] = []
var _next_drop := 0.0
var _spawned := 0
var _count := 6
var _area := 2.6


func _on_spawn() -> void:
	position = Vector3(target.x, 0.0, target.z)
	_count = int(fdef.get("count", 6)) + 2 * clause.mod("grow") + clause.mod("swift")
	_area = radius
	life = 1.2 + FALL_TIME


func _tick(delta: float) -> void:
	_next_drop -= delta
	var interval := 1.0 / float(_count)
	while _next_drop <= 0.0 and _spawned < _count:
		_next_drop += interval
		_spawned += 1
		var ang := cast.rng.randf() * TAU
		var dist := sqrt(cast.rng.randf()) * _area
		var p := global_position + Vector3(cos(ang), 0.0, sin(ang)) * dist
		# Seek pulls drops toward targets inside the area.
		if clause.has_mod("seek"):
			var t := cast.nearest_target(p, _area)
			if t:
				p = p.lerp(Combat.flat(t.global_position), 0.7)
		var d := {"pos": p, "t": 0.0, "node": SpellFx.rain_drop(self, p, FALL_TIME)}
		drops.append(d)
	for d in drops.duplicate():
		d.t += delta
		if d.t >= FALL_TIME:
			drops.erase(d)
			explode(d.pos, 1.15 * pow(1.2, clause.mod("grow")), 1.0, 0.05)
			SpellFx.drop_impact(self, d.pos)
	if _spawned >= _count and drops.is_empty():
		finish(global_position)

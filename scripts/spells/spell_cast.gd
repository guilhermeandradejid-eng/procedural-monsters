class_name SpellCast
extends RefCounted
## Shared context of one cast of a grimoire page: who cast it, how much
## combinatorial budget remains, and deterministic randomness.

## Maximum payload executions a single cast can trigger (keeps chains sane).
const EVENT_BUDGET := 48

var caster: Node3D = null
var profile: PlayerProfile = null
var program: SpellProgram = null
var events_left := EVENT_BUDGET
var rng := RandomNumberGenerator.new()
## Ground point the caster aimed at (for POINT forms of the root clause).
var aim_point := Vector3.ZERO
var power_mult := 1.0
## "players" when cast by a knight, "enemies" when an erratum casts it.
var side := "players"
## Relic: "Broken Seal" makes the next cast twice.
var is_copy := false


static func make(p_caster: Node3D, p_profile: PlayerProfile, p_program: SpellProgram, p_aim_point: Vector3) -> SpellCast:
	var c := SpellCast.new()
	c.caster = p_caster
	c.profile = p_profile
	c.program = p_program
	c.aim_point = p_aim_point
	c.rng.seed = hash(p_program.seed + (p_profile.casts if p_profile else 0) * 7717)
	return c


func caster_alive() -> bool:
	return is_instance_valid(caster) and caster.is_inside_tree() and not caster.get("downed")


func might() -> float:
	return profile.stat("might") if profile else 1.0


func crit_chance(clause: SpellClause) -> float:
	var c := profile.stat("crit") if profile else 0.05
	c += 0.2 * clause.mod("sharpen")
	if clause.element == "arcane":
		c += 0.1
	return c


func crit_mult() -> float:
	return profile.stat("crit_mult") if profile else 2.0


func targets_near(pos: Vector3, r: float) -> Array[Node3D]:
	return Combat.enemies_near(pos, r) if side == "players" else Combat.players_near(pos, r)


func nearest_target(pos: Vector3, r := 999.0, exclude: Array = []) -> Node3D:
	if side == "players":
		return Combat.nearest_enemy(pos, r, exclude)
	return Combat.nearest_player(pos, r)


func target_in_cone(pos: Vector3, dir: Vector3, r: float, cos_half: float, exclude: Array = []) -> Node3D:
	if side == "players":
		return Combat.enemy_in_cone(pos, dir, r, cos_half, exclude)
	return Combat.nearest_player(pos, r)


func targets_on_segment(a: Vector3, b: Vector3, width: float) -> Array[Node3D]:
	if side == "players":
		return Combat.enemies_on_segment(a, b, width)
	return Combat.players_on_segment(a, b, width)


func allies_near(pos: Vector3, r: float) -> Array[Node3D]:
	return Combat.players_near(pos, r) if side == "players" else Combat.enemies_near(pos, r)


func spend_event() -> bool:
	if events_left <= 0:
		return false
	events_left -= 1
	return true

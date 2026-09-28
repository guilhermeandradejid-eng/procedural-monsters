class_name StatusSet
extends RefCounted
## Elemental conditions on an actor. Numbers follow Ember Knights' spirit:
## burn does not stack but refreshes, venom doubles per stack (1/2/4/8/16),
## three chill stacks freeze (bosses only slow down).

const VENOM_DPS := [0.0, 1.5, 3.0, 6.0, 12.0, 24.0]
const CHILL_SLOW := 0.17
const FREEZE_TIME := 1.3
const TICK := 0.5

var burn_time := 0.0
var burn_dps := 0.0
var chill_stacks := 0
var chill_time := 0.0
var frozen_time := 0.0
var freeze_immune := 0.0
var venom_stacks := 0
var venom_time := 0.0
var venom_pot := 1.0
var mark_time := 0.0
var entropy_time := 0.0
var stun_time := 0.0
var blackflame_time := 0.0
var slow_extra := 0.0
var slow_extra_time := 0.0
var _tick_acc := 0.0
## Profile that applied the latest DoT (so kills credit the right knight).
var dot_profile: PlayerProfile = null
var dot_source: Node3D = null


func burning() -> bool:
	return burn_time > 0.0


func frozen() -> bool:
	return frozen_time > 0.0


func marked() -> bool:
	return mark_time > 0.0


func poisoned() -> bool:
	return venom_stacks > 0


func add_burn(dps: float, duration := 3.0) -> void:
	burn_dps = maxf(burn_dps if burn_time > 0.0 else 0.0, dps)
	burn_time = maxf(burn_time, duration)


## Returns true if this chill froze the target.
func add_chill(stacks: int, is_boss: bool, potency := 1.0) -> bool:
	if frozen_time > 0.0 or freeze_immune > 0.0:
		chill_time = 3.0
		return false
	chill_stacks = mini(chill_stacks + stacks, 3)
	chill_time = 3.0
	if chill_stacks >= 3:
		chill_stacks = 0
		frozen_time = FREEZE_TIME * clampf(potency, 0.8, 1.6) * (0.45 if is_boss else 1.0)
		return true
	return false


func add_venom(stacks: int, potency: float) -> void:
	venom_stacks = mini(venom_stacks + stacks, 5)
	venom_time = 5.0
	venom_pot = maxf(venom_pot if venom_stacks > 1 else 0.0, potency)


func add_mark(duration := 4.0) -> void:
	mark_time = maxf(mark_time, duration)


func add_slow(amount: float, duration: float) -> void:
	slow_extra = maxf(slow_extra if slow_extra_time > 0.0 else 0.0, amount)
	slow_extra_time = maxf(slow_extra_time, duration)


## Movement/attack speed multiplier from chill, entropy and freeze.
func speed_mult() -> float:
	if frozen_time > 0.0:
		return 0.0
	var m := 1.0 - CHILL_SLOW * chill_stacks
	if entropy_time > 0.0:
		m *= 0.45
	if slow_extra_time > 0.0:
		m *= 1.0 - slow_extra
	return clampf(m, 0.1, 1.0)


func damage_taken_mult() -> float:
	var m := 1.0
	if mark_time > 0.0:
		m *= 1.25
	if frozen_time > 0.0:
		m *= 1.15
	return m


## Advances timers. Returns the DoT damage to apply this frame (0 most frames).
func tick(delta: float) -> Dictionary:
	burn_time = maxf(0.0, burn_time - delta)
	if burn_time <= 0.0:
		burn_dps = 0.0
	chill_time = maxf(0.0, chill_time - delta)
	if chill_time <= 0.0:
		chill_stacks = 0
	if frozen_time > 0.0:
		frozen_time = maxf(0.0, frozen_time - delta)
		if frozen_time <= 0.0:
			freeze_immune = 1.5
	freeze_immune = maxf(0.0, freeze_immune - delta)
	venom_time = maxf(0.0, venom_time - delta)
	if venom_time <= 0.0:
		venom_stacks = 0
	mark_time = maxf(0.0, mark_time - delta)
	entropy_time = maxf(0.0, entropy_time - delta)
	stun_time = maxf(0.0, stun_time - delta)
	blackflame_time = maxf(0.0, blackflame_time - delta)
	slow_extra_time = maxf(0.0, slow_extra_time - delta)
	_tick_acc += delta
	if _tick_acc < TICK:
		return {}
	_tick_acc -= TICK
	var out := {}
	if burn_time > 0.0:
		out["ember"] = burn_dps * TICK
	if venom_stacks > 0:
		out["venom"] = VENOM_DPS[venom_stacks] * venom_pot * TICK
	return out


func clear() -> void:
	burn_time = 0.0
	chill_stacks = 0
	frozen_time = 0.0
	venom_stacks = 0
	mark_time = 0.0
	entropy_time = 0.0
	stun_time = 0.0
	blackflame_time = 0.0
	slow_extra_time = 0.0

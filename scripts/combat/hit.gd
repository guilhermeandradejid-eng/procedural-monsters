class_name Hit
extends RefCounted
## One packet of damage travelling from a source to an actor.

var amount := 0.0
var element := "arcane"
## Status strength (0 = no status). See SpellClause.potency().
var potency := 0.0
var source: Node3D = null
var profile: PlayerProfile = null
var crit := false
var knockback := Vector3.ZERO
var stagger := 0.0
var pos := Vector3.ZERO
## "spell", "melee", "dot", "reaction", "enemy"
var kind := "spell"
## Reactions (arcs, splashes) must not trigger further reactions.
var no_proc := false
var clause: SpellClause = null
## Filled by the receiver.
var dealt := 0.0
var killed := false


static func make(p_amount: float, p_source: Node3D, p_pos: Vector3, p_kind := "spell") -> Hit:
	var h := Hit.new()
	h.amount = p_amount
	h.source = p_source
	h.pos = p_pos
	h.kind = p_kind
	return h


func copy_reaction(scale: float) -> Hit:
	var h := Hit.new()
	h.amount = amount * scale
	h.element = element
	h.potency = potency
	h.source = source
	h.profile = profile
	h.pos = pos
	h.kind = "reaction"
	h.no_proc = true
	h.clause = clause
	return h

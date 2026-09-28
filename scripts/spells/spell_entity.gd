class_name SpellEntity
extends Node3D
## Base for every form living in the world. Handles damage packets, crits,
## essences, inflections that apply on hit (Chain, Siphon), and the links
## (On Hit / On Fade / On Kill / Pulse) that fire payload clauses.

var cast: SpellCast
var clause: SpellClause
var form := "bolt"
var fdef: Dictionary = {}
var vis: SpellVisual
var power := 1.0
var dir := Vector3.FORWARD
var origin := Vector3.ZERO
var target := Vector3.ZERO
var exclude: Array = []
var age := 0.0
var life := 1.0
var radius := 0.5
## Suspend inflection: time spent charging before acting.
var hold := 0.0
var finished := false
var triggers_left := 3
## False for secondary effects (Volatile bursts, zones) so links do not double fire.
var inherit_links := true
var secondary := false
## Orbit form: number of satellites.
var orbit_count := 3
var _hit_times := {}
var _pulse_timer := 0.0
var _reaction_timer := 0.0
var _fx: Node3D


func setup(p_cast: SpellCast, p_clause: SpellClause, p_form: String, p_origin: Vector3, p_dir: Vector3, p_target: Vector3, p_power: float, p_exclude: Array) -> void:
	cast = p_cast
	clause = p_clause
	form = p_form
	fdef = GlyphDB.FORMS.get(p_form, GlyphDB.FORMS["bolt"]) if p_form != "zone" else {"dmg": 4.0, "radius": 1.6}
	origin = p_origin
	dir = p_dir
	target = p_target
	power = p_power
	exclude = p_exclude.duplicate()
	vis = SpellVisual.for_clause(clause, form, cast.side == "enemies")
	radius = float(fdef.get("radius", 0.5)) * pow(1.4, clause.mod("grow"))
	life = float(fdef.get("life", 1.0)) * pow(0.9, clause.mod("swift")) * pow(1.15, clause.mod("grow"))
	var delays := mini(clause.mod("delay"), 2)
	hold = 0.45 * delays
	power *= pow(1.35, delays)
	triggers_left = 5 if clause.link == "on_kill" else 3
	position = origin


func _enter_tree() -> void:
	SpellRunner.alive_entities += 1


func _exit_tree() -> void:
	SpellRunner.alive_entities -= 1


func _ready() -> void:
	_on_spawn()
	_fx = SpellFx.build(self)


## Override: create state, play spawn fx.
func _on_spawn() -> void:
	pass


func _physics_process(delta: float) -> void:
	if finished:
		return
	if hold > 0.0:
		hold -= delta
		SpellFx.charging(self, hold)
		return
	age += delta
	_reaction_timer = maxf(0.0, _reaction_timer - delta)
	if clause.link == "pulse" and inherit_links:
		_pulse_timer -= delta
		if _pulse_timer <= 0.0:
			_pulse_timer = 0.55 * pow(0.85, clause.mod("swift"))
			fire_link(global_position, dir, [])
	if clause.has_mod("magnet"):
		_magnet_pull(delta)
	_tick(delta)


## Override: per-form behaviour.
func _tick(_delta: float) -> void:
	pass


func speed() -> float:
	var s := float(fdef.get("speed", 10.0)) * pow(1.45, clause.mod("swift")) * pow(0.85, clause.mod("grow")) * pow(0.9, clause.mod("heavy")) * (1.6 if clause.mod("delay") > 0 else 1.0)
	# Hostile spells travel slower so they can be read and dodged.
	if cast.side == "enemies":
		s *= 0.42
	return s


func base_damage() -> float:
	var d: float = float(fdef.get("dmg", 10.0)) * clause.power * power * cast.might()
	d *= pow(1.35, clause.mod("grow")) * pow(0.9, clause.mod("swift")) * pow(1.1, clause.mod("heavy"))
	if cast.side == "enemies":
		d *= 0.55
	return d


func knock_force() -> float:
	return 3.0 * (1.0 + 1.6 * clause.mod("heavy"))


## True if `t` was not hit by this entity within `cooldown` seconds.
func can_hit(t: Node3D, cooldown := INF) -> bool:
	if t == null or not is_instance_valid(t):
		return false
	if exclude.has(t):
		return false
	var id := t.get_instance_id()
	if not _hit_times.has(id):
		return true
	return age - float(_hit_times[id]) >= cooldown


func deal(t: Node3D, mult := 1.0, knock_dir := Vector3.ZERO) -> Hit:
	var h := Hit.make(base_damage() * mult, cast.caster, t.global_position, "spell")
	h.element = clause.element
	h.potency = clause.potency()
	h.profile = cast.profile
	h.clause = clause
	if cast.side == "players":
		h.amount *= Relics.damage_mult(cast.profile, t)
	if cast.rng.randf() < cast.crit_chance(clause):
		h.crit = true
		h.amount *= cast.crit_mult()
	var kd := knock_dir if knock_dir != Vector3.ZERO else Combat.flat(t.global_position - global_position)
	if kd.length() > 0.01:
		h.knockback = kd.normalized() * knock_force()
	h.stagger = 0.3 * clause.mod("heavy")
	_hit_times[t.get_instance_id()] = age
	t.take_hit(h)
	_after_hit(h, t)
	return h


func _after_hit(h: Hit, t: Node3D) -> void:
	if cast.profile and cast.side == "players":
		cast.profile.damage_dealt += h.dealt
		if h.killed:
			cast.profile.kills += 1
	Elements.on_hit(h, t, self)
	if clause.has_mod("leech") and cast.caster_alive() and cast.caster.has_method("heal"):
		cast.caster.heal(minf(h.dealt * 0.06 * clause.mod("leech"), 3.0))
	if clause.has_mod("chain") and not h.no_proc:
		Elements.chain(h, t, self, 2 * clause.mod("chain"), 0.6, "chain")
	SpellFx.impact(self, h, t)
	if inherit_links:
		if clause.link == "on_hit":
			fire_link(h.pos, dir, [t])
		if h.killed and clause.link == "on_kill":
			fire_link(h.pos, dir, [t])
	if h.crit or h.killed:
		Juice.hitstop(0.045 if not h.killed else 0.06, 1.0)


## Fires the payload clause at `pos`, aiming at the next nearest target.
func fire_link(pos: Vector3, fallback_dir: Vector3, p_exclude: Array) -> void:
	if clause.child == null or triggers_left <= 0 or not inherit_links:
		return
	if not cast.spend_event():
		return
	triggers_left -= 1 if clause.link != "pulse" else 0
	var nxt := cast.nearest_target(pos, 12.0, p_exclude)
	var d := fallback_dir
	if nxt:
		var to := Combat.flat(nxt.global_position - pos)
		if to.length() > 0.1:
			d = to.normalized()
	var tpos := pos
	if nxt and GlyphDB.FORMS[clause.child.dominant_form()].aim == GlyphDB.Aim.POINT and clause.link == "pulse":
		tpos = nxt.global_position
	SpellRunner.run_clause(cast, clause.child, pos, d, tpos, p_exclude, 1.0, false)


## Ends the entity: On Fade link, Volatile burst, Linger zone, then fade out.
func finish(pos := Vector3.INF) -> void:
	if finished:
		return
	finished = true
	var p := global_position if pos == Vector3.INF else pos
	p.y = 0.0
	if inherit_links and clause.link == "on_end":
		triggers_left = maxi(triggers_left, 1)
		fire_link(p, dir, [])
	if not secondary:
		if clause.has_mod("volatile"):
			SpellRunner.burst(cast, clause, p, 1.9 * pow(1.2, clause.mod("volatile") - 1), 0.5 * clause.mod("volatile"))
		if clause.has_mod("linger"):
			SpellRunner.zone(cast, clause, p, 1.7 * pow(1.3, clause.mod("grow")), 2.5 * clause.mod("linger"), 0.3)
		if clause.has_mod("spiral") and _is_burst_like():
			_spiral_wisps(p)
	SpellFx.on_finish(self, p)
	_despawn()


## Instant area hit used by Rune, Meteor, Rain drops and Step arrivals.
func explode(center: Vector3, r: float, mult := 1.0, cooldown := INF) -> int:
	center.y = 0.0
	var n := 0
	for t in cast.targets_near(center, r):
		if can_hit(t, cooldown):
			var kd := Combat.flat(t.global_position - center)
			deal(t, mult, kd if kd.length() > 0.1 else dir)
			n += 1
			if finished:
				break
	return n


func _is_burst_like() -> bool:
	return form in ["nova", "mine", "meteor", "blink", "rain"]


func _spiral_wisps(p: Vector3) -> void:
	var n := 4 + 2 * clause.mod("spiral")
	for i in n:
		var ang := TAU * i / n
		var d := Vector3(cos(ang), 0.0, sin(ang))
		var w: SpellEntity = SpellRunner.FORM_SCRIPTS["bolt"].new()
		w.setup(cast, clause, "bolt", p + d * 0.6, d, p, 0.3 * power, exclude)
		w.inherit_links = false
		w.secondary = true
		w.spiral_wisp = true
		Level.current.add_spell(w)


func _despawn() -> void:
	set_physics_process(false)
	if _fx and is_instance_valid(_fx):
		SpellFx.detach_trails(_fx)
	var t := create_tween()
	t.tween_property(self, "scale", Vector3.ONE * 0.01, 0.12).set_ease(Tween.EASE_IN)
	t.tween_callback(queue_free)


func _magnet_pull(delta: float) -> void:
	var r := 3.2 + 0.8 * clause.mod("magnet")
	for t in cast.targets_near(global_position, r):
		if t.get("is_boss"):
			continue
		var to := Combat.flat(global_position - t.global_position)
		if to.length() > 0.4:
			t.knock += to.normalized() * delta * 16.0 * clause.mod("magnet")


func reaction_ready(cooldown: float) -> bool:
	if _reaction_timer > 0.0:
		return false
	_reaction_timer = cooldown
	return true

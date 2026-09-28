class_name Elements
extends RefCounted
## What essences DO when they touch something: statuses for the six base
## essences and one reaction for each of the fifteen fusions.


static func on_hit(h: Hit, t: Node3D, ent: SpellEntity) -> void:
	if h.potency <= 0.0 or t == null or not is_instance_valid(t):
		return
	var key := h.element
	var parts := Elem.parts_of(key)
	var share := 1.0 if parts.size() <= 1 else 0.75
	for p in parts:
		_apply_base(p, h, t, ent, share)
	if Elem.is_fusion(key) and not h.no_proc:
		_fusion(key, h, t, ent)


static func _apply_base(base: String, h: Hit, t: Node3D, ent: SpellEntity, share: float) -> void:
	var pot := h.potency * share
	var st: StatusSet = t.status
	st.dot_profile = h.profile
	st.dot_source = h.source
	match base:
		"ember":
			st.add_burn(3.5 * pot * (ent.cast.might() if ent else 1.0))
		"frost":
			if st.add_chill(1, bool(t.get("is_boss")), pot):
				SpellFx.freeze_burst(t)
		"storm":
			if not h.no_proc:
				chain(h, t, ent, 2 if pot < 1.4 else 3, 0.4, "storm")
		"void":
			st.add_mark(4.0)
			if not t.get("is_boss"):
				var to := Combat.flat(h.pos - t.global_position)
				if ent:
					to = Combat.flat(ent.global_position - t.global_position)
				if to.length() > 0.3:
					t.knock += to.normalized() * 5.0 * pot
		"venom":
			st.add_venom(1, pot)
		"radiant":
			if ent and ent.reaction_ready(0.25):
				heal_allies(ent.cast, h.pos, 2.6, 2.0 * pot)


## Storm arcs / Chain inflection: jumps from `from` to nearby targets.
static func chain(h: Hit, from: Node3D, ent: SpellEntity, jumps: int, scale: float, style: String) -> void:
	if ent == null:
		return
	var hit_set: Array = [from]
	var cur: Node3D = from
	for i in jumps:
		var nxt := ent.cast.nearest_target(cur.global_position, 4.6, hit_set)
		if nxt == null:
			break
		var r := h.copy_reaction(scale)
		r.pos = nxt.global_position
		if style == "storm" and h.element == "neurotoxin":
			nxt.status.add_venom(1, h.potency)
		SpellFx.arc(cur.global_position, nxt.global_position, h.element, style)
		nxt.take_hit(r)
		Fx.damage_number(nxt.global_position + Vector3.UP * 1.4, r.dealt, Elem.main_color(h.element), false, true)
		if r.killed and ent.cast.profile:
			ent.cast.profile.kills += 1
		hit_set.append(nxt)
		cur = nxt


static func heal_allies(c: SpellCast, pos: Vector3, r: float, amount: float) -> void:
	for a in c.allies_near(pos, r):
		if a.has_method("heal"):
			var healed: float = a.heal(amount)
			if healed > 0.05:
				Fx.heal_number(a.global_position + Vector3.UP * 1.8, healed)


static func _fusion(key: String, h: Hit, t: Node3D, ent: SpellEntity) -> void:
	if ent == null:
		return
	var st: StatusSet = t.status
	var c := ent.cast
	match key:
		"steam":
			if ent.reaction_ready(0.45):
				SpellRunner.zone(c, ent.clause, h.pos, 2.1, 2.0, 0.25, "steam")
		"plasma":
			var r := h.copy_reaction(0.35)
			for o in c.targets_near(h.pos, 1.7):
				if o != t:
					o.take_hit(r.copy_reaction(1.0))
			SpellFx.pop(h.pos, key, 1.7)
		"blackflame":
			st.blackflame_time = 4.0
			st.add_mark(2.0)
		"brimstone":
			if st.poisoned() and st.burning():
				var stacks := st.venom_stacks
				st.venom_stacks = 0
				var r := h.copy_reaction(0.0)
				r.amount = 6.0 * stacks * h.potency * c.might()
				t.take_hit(r)
				SpellFx.pop(t.global_position, key, 1.2 + 0.25 * stacks)
				Fx.damage_number(t.global_position + Vector3.UP * 2.0, r.dealt, Elem.main_color(key), true, false)
		"solar":
			if c.rng.randf() < 0.2:
				st.stun_time = maxf(st.stun_time, 0.5 if not t.get("is_boss") else 0.1)
				SpellFx.pop(h.pos, key, 1.0)
		"crystal":
			if st.frozen():
				st.frozen_time = 0.0
				var r := h.copy_reaction(1.2)
				t.take_hit(r)
				Fx.damage_number(t.global_position + Vector3.UP * 2.2, r.dealt, Elem.main_color(key), true, false)
				SpellFx.shatter(t.global_position)
				Juice.hitstop(0.06)
				var n := 0
				for o in c.targets_near(t.global_position, 4.0):
					if o != t and n < 3:
						n += 1
						var s := h.copy_reaction(0.3)
						SpellFx.arc(t.global_position, o.global_position, key, "shard")
						o.take_hit(s)
		"entropy":
			st.entropy_time = maxf(st.entropy_time, 2.0)
		"miasma":
			if ent.reaction_ready(0.8):
				SpellRunner.zone(c, ent.clause, h.pos, 1.8, 2.5, 0.2, "miasma")
		"prism":
			if ent.reaction_ready(0.3):
				var targets: Array = [t]
				for i in 3:
					var o := c.nearest_target(h.pos, 8.0, targets)
					if o == null:
						break
					targets.append(o)
					var r := h.copy_reaction(0.3)
					SpellFx.arc(h.pos, o.global_position, key, "ray")
					o.take_hit(r)
				heal_allies(c, h.pos, 2.5, 1.0 * h.potency)
		"rift":
			if ent.reaction_ready(0.35):
				for o in c.targets_near(h.pos, 3.2):
					if o.get("is_boss"):
						continue
					var to := Combat.flat(h.pos - o.global_position)
					if to.length() > 0.3:
						o.knock += to.normalized() * 9.0
				SpellFx.pop(h.pos, key, 3.2)
		"judgement":
			if ent.reaction_ready(0.3):
				var lvl := Level.current
				var tt := t
				lvl.after(0.45, func():
					if is_instance_valid(tt) and not tt.dead:
						var r := h.copy_reaction(0.55)
						r.pos = tt.global_position
						SpellFx.sky_strike(tt.global_position, key)
						tt.take_hit(r)
						heal_allies(c, tt.global_position, 2.5, 1.5 * h.potency))
		"blight":
			var n := 0
			for o in c.targets_near(t.global_position, 2.6):
				if o != t and n < 2:
					n += 1
					o.status.add_venom(1, h.potency)
		"eclipse":
			if ent.reaction_ready(0.6):
				var center := h.pos
				for o in c.targets_near(center, 2.8):
					if not o.get("is_boss"):
						o.knock += Combat.flat(center - o.global_position).normalized() * 7.0
				Level.current.after(0.5, func():
					SpellRunner.burst(c, ent.clause, center, 2.6, 0.45))
		"sap":
			if ent.reaction_ready(0.9):
				SpellRunner.zone(c, ent.clause, h.pos, 2.0, 2.5, 0.0, "sap")


## Called by enemies when they die, for death-triggered essence effects.
static func on_death(t: Node3D) -> void:
	var st: StatusSet = t.status
	if st.blackflame_time > 0.0 and st.burning():
		for o in Combat.enemies_near(t.global_position, 3.2):
			if o != t:
				o.status.add_burn(st.burn_dps * 1.1, 3.0)
				o.status.blackflame_time = 3.0
				SpellFx.arc(t.global_position, o.global_position, "blackflame", "flame")

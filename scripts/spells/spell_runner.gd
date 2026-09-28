class_name SpellRunner
extends RefCounted
## Executes compiled spells in the world: turns a clause into form entities,
## applying Split/Mirror fans, Echo recasts, Aegis shields and "And Then" links.

const FORM_SCRIPTS := {
	"bolt": preload("res://scripts/spells/forms/projectile_spell.gd"),
	"orb": preload("res://scripts/spells/forms/projectile_spell.gd"),
	"wave": preload("res://scripts/spells/forms/projectile_spell.gd"),
	"chakram": preload("res://scripts/spells/forms/projectile_spell.gd"),
	"serpent": preload("res://scripts/spells/forms/serpent_spell.gd"),
	"nova": preload("res://scripts/spells/forms/burst_spell.gd"),
	"lance": preload("res://scripts/spells/forms/lance_spell.gd"),
	"rain": preload("res://scripts/spells/forms/rain_spell.gd"),
	"orbit": preload("res://scripts/spells/forms/orbit_spell.gd"),
	"mine": preload("res://scripts/spells/forms/mine_spell.gd"),
	"meteor": preload("res://scripts/spells/forms/meteor_spell.gd"),
	"vortex": preload("res://scripts/spells/forms/vortex_spell.gd"),
	"totem": preload("res://scripts/spells/forms/totem_spell.gd"),
	"blink": preload("res://scripts/spells/forms/blink_spell.gd"),
}

## Hard cap on simultaneously alive spell entities (performance guard).
const MAX_ENTITIES := 260
static var alive_entities := 0


static func cast(c: SpellCast, origin: Vector3, dir: Vector3) -> void:
	if c.program == null or c.program.root == null:
		return
	run_clause(c, c.program.root, origin, dir, c.aim_point, [], c.power_mult, false)


static func run_clause(c: SpellCast, clause: SpellClause, origin: Vector3, dir: Vector3, target: Vector3, exclude: Array, power_mult: float, is_echo: bool) -> void:
	var level := Level.current
	if level == null or clause == null:
		return
	dir = Combat.flat(dir)
	dir = Vector3.FORWARD if dir.length() < 0.01 else dir.normalized()
	origin.y = 0.0
	target.y = 0.0
	if clause.has_mod("ward") and not is_echo:
		_ward(c, clause, origin)
	if clause.depth > 0:
		SpellFx.payload_sigil(origin, clause)
	for form in clause.forms:
		_spawn_form(c, clause, form, origin, dir, target, exclude, power_mult)
	if clause.has_mod("echo") and not is_echo:
		for k in mini(clause.mod("echo"), 3):
			level.after(0.34 * (k + 1), func():
				var o := origin
				var d := dir
				var t := target
				if clause.depth == 0 and c.caster_alive() and c.caster.has_method("aim_state"):
					var st: Dictionary = c.caster.aim_state()
					o = st.origin
					d = st.dir
					t = st.point
				SpellFx.echo_ripple(o, clause)
				run_clause(c, clause, o, d, t, exclude, power_mult * 0.6, true))
	if clause.link == "then" and clause.child:
		level.after(0.18, func():
			if not c.spend_event():
				return
			var o := origin
			var d := dir
			var t := target
			if clause.depth == 0 and c.caster_alive() and c.caster.has_method("aim_state"):
				var st: Dictionary = c.caster.aim_state()
				o = st.origin
				d = st.dir
				t = st.point
			run_clause(c, clause.child, o, d, t, [], power_mult, false))


static func _spawn_form(c: SpellCast, clause: SpellClause, form: String, origin: Vector3, dir: Vector3, target: Vector3, exclude: Array, power_mult: float) -> void:
	var fdef: Dictionary = GlyphDB.FORMS[form]
	var splits := mini(clause.mod("split"), 4)
	var count := 1 + 2 * splits
	var per_power := power_mult * (0.7 * pow(0.93, maxi(0, splits - 1)) if splits > 0 else 1.0)
	var twin := clause.has_mod("twin")
	var placements: Array = []  # [origin, dir, target]
	match int(fdef.aim):
		GlyphDB.Aim.DIRECTION:
			var step := deg_to_rad(13.0) if count <= 5 else deg_to_rad(70.0) / float(count - 1)
			for i in count:
				var a := (i - (count - 1) * 0.5) * step
				var d := dir.rotated(Vector3.UP, a)
				placements.append([origin, d, target])
				if twin:
					placements.append([origin, -d, origin * 2.0 - target])
		GlyphDB.Aim.POINT:
			var t0 := target
			if clause.depth == 0:
				var max_r: float = fdef.get("range", 8.0)
				var off := Combat.flat(target - origin)
				if off.length() > max_r:
					t0 = origin + off.normalized() * max_r
			for i in count:
				var t := t0
				if i > 0:
					var ang := TAU * float(i - 1) / float(count - 1) + c.rng.randf() * 0.4
					t = t0 + Vector3(cos(ang), 0.0, sin(ang)) * 2.2
				placements.append([origin, dir, t])
				if twin:
					var m := origin * 2.0 - t
					placements.append([origin, -dir, m])
		_:
			for i in count:
				var o := origin
				if i > 0 and form != "orbit":
					var ang := TAU * float(i - 1) / float(count - 1)
					o = origin + Vector3(cos(ang), 0.0, sin(ang)) * 2.4
				placements.append([o, dir, target])
			if twin:
				placements.append([origin - dir * 3.0, -dir, target])
	for pl in placements:
		if alive_entities >= MAX_ENTITIES:
			return
		var e: SpellEntity = FORM_SCRIPTS[form].new()
		e.setup(c, clause, form, pl[0], pl[1], pl[2], per_power, exclude)
		if form == "orbit":
			e.orbit_count = 3 * count
			Level.current.add_spell(e)
			break
		Level.current.add_spell(e)


static func _ward(c: SpellCast, clause: SpellClause, origin: Vector3) -> void:
	var amount := 6.0 * clause.mod("ward") * clause.power
	var allies: Array[Node3D] = Combat.players_near(origin, 3.5) if c.side == "players" else []
	if c.caster and not allies.has(c.caster) and c.caster.has_method("add_shield"):
		allies.append(c.caster)
	for a in allies:
		if a.has_method("add_shield"):
			a.add_shield(amount, 3.0)
	SpellFx.ward_flash(origin, clause)


## Secondary burst used by Volatile and reactions. Never fires the clause's links.
static func burst(c: SpellCast, clause: SpellClause, pos: Vector3, radius: float, power_mult: float, exclude: Array = []) -> void:
	if Level.current == null or alive_entities >= MAX_ENTITIES:
		return
	var b: SpellEntity = FORM_SCRIPTS["nova"].new()
	b.setup(c, clause, "nova", pos, Vector3.FORWARD, pos, power_mult, exclude)
	b.radius = radius
	b.inherit_links = false
	b.secondary = true
	Level.current.add_spell(b)


static func zone(c: SpellCast, clause: SpellClause, pos: Vector3, radius: float, duration: float, power_mult: float, kind := "linger") -> void:
	if Level.current == null or alive_entities >= MAX_ENTITIES:
		return
	var z := ZoneSpell.new()
	z.setup(c, clause, "zone", pos, Vector3.FORWARD, pos, power_mult, [])
	z.radius = radius
	z.life = duration
	z.zone_kind = kind
	z.inherit_links = false
	z.secondary = true
	Level.current.add_spell(z)

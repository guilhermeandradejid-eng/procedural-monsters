class_name SpellFx
extends RefCounted
## All spell visuals. Every look is assembled from the clause's SpellVisual
## (colours, silhouette, motion) so each written sentence has its own face.

const SIGIL_SHADER := preload("res://shaders/fx/sigil.gdshader")
const BEAM_SHADER := preload("res://shaders/fx/beam.gdshader")
const TRAIL_SHADER := preload("res://shaders/fx/trail.gdshader")
const ZONE_SHADER := preload("res://shaders/fx/zone.gdshader")
const MAX_LIGHTS := 18

static var lights_alive := 0
static var _trail_mats := {}
static var _beam_mats := {}


# --- materials ---------------------------------------------------------------------------
static func trail_material(v: SpellVisual) -> ShaderMaterial:
	var key := v.seed
	if _trail_mats.has(key):
		return _trail_mats[key]
	var m := ShaderMaterial.new()
	m.shader = TRAIL_SHADER
	m.set_shader_parameter("head_color", v.core.lerp(v.main, 0.35))
	m.set_shader_parameter("tail_color", v.dark if v.dark.v > 0.15 else v.main * 0.6)
	m.set_shader_parameter("glow", 2.2)
	m.set_shader_parameter("noise_scale", v.noise_scale)
	m.set_shader_parameter("jagged", 1.0 if v.jagged else 0.0)
	_trail_mats[key] = m
	if _trail_mats.size() > 300:
		_trail_mats.clear()
	return m


static func beam_material(v: SpellVisual) -> ShaderMaterial:
	var key := v.seed
	if _beam_mats.has(key):
		return _beam_mats[key]
	var m := ShaderMaterial.new()
	m.shader = BEAM_SHADER
	m.set_shader_parameter("core", v.core)
	m.set_shader_parameter("color", v.main)
	m.set_shader_parameter("jagged", 1.0 if v.jagged else 0.0)
	_beam_mats[key] = m
	return m


static func sigil_material(tex: Texture2D, col: Color, core: Color, spin := 0.6) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SIGIL_SHADER
	m.set_shader_parameter("sigil", tex)
	m.set_shader_parameter("color", col)
	m.set_shader_parameter("core", core)
	m.set_shader_parameter("spin", spin)
	return m


static func zone_material(v: SpellVisual, swirl := 0.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = ZONE_SHADER
	m.set_shader_parameter("color", v.main)
	m.set_shader_parameter("dark", v.dark)
	m.set_shader_parameter("swirl", swirl)
	return m


static func mote_kind(m: String) -> String:
	match m:
		"flame":
			return "flame"
		"shard":
			return "shard"
		"spark":
			return "spark"
		"implode":
			return "implode"
		"bubble":
			return "bubble"
		"twinkle":
			return "twinkle"
	return "glow"


static func _core(e: SpellEntity, mesh: Mesh, s: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Core"
	mi.mesh = mesh
	mi.material_override = e.vis.energy_material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.scale = s
	return mi


static func _light(parent: Node3D, col: Color, energy: float, range_: float) -> OmniLight3D:
	if lights_alive >= MAX_LIGHTS:
		return null
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = range_
	l.omni_attenuation = 1.6
	l.shadow_enabled = false
	l.tree_entered.connect(func(): SpellFx.lights_alive += 1)
	l.tree_exiting.connect(func(): SpellFx.lights_alive -= 1)
	parent.add_child(l)
	return l


static func _trail(e: SpellEntity, target: Node3D, width: float, time: float) -> Trail3D:
	var t := Trail3D.new()
	t.target = target
	t.width = width
	t.lifetime = time
	t.material_override = trail_material(e.vis)
	e.add_child(t)
	return t


static func _motes(e: SpellEntity, parent: Node3D, amount: int, life := 1.0) -> void:
	var v := e.vis
	for i in v.motes.size():
		var kind := mote_kind(v.motes[i])
		var col := v.main if i == 0 else v.rim
		Fx.emitter(parent, kind, col.lerp(v.core, 0.3), v.dark, int(amount * v.mote_rate / v.motes.size()), life)


# --- entity visuals -------------------------------------------------------------------
static func build(e: SpellEntity) -> Node3D:
	var root := Node3D.new()
	root.name = "Fx"
	e.add_child(root)
	match e.form:
		"bolt", "orb", "chakram", "wave":
			_projectile(e, root)
		"serpent":
			_serpent(e, root)
		"nova":
			_nova(e, root)
		"lance":
			_lance(e, root)
		"rain":
			_rain_area(e, root)
		"orbit":
			_orbit(e, root)
		"mine":
			_mine(e, root)
		"meteor":
			_meteor(e, root)
		"vortex":
			_vortex(e, root)
		"totem":
			_totem(e, root)
		"zone":
			_zone(e, root)
	return root


static func _projectile(e: SpellEntity, root: Node3D) -> void:
	var v := e.vis
	var r := e.radius
	var core: MeshInstance3D
	match e.form:
		"bolt":
			core = _core(e, SpellMeshes.spindle(v.spikes, v.twist, v.shape), Vector3(r * 2.0, r * 2.0, r * 2.6 * v.stretch))
			if e.get("spiral_wisp"):
				core.scale *= 0.6
		"orb":
			core = _core(e, SpellMeshes.sphere(14), Vector3.ONE * r)
		"chakram":
			core = _core(e, SpellMeshes.chakram(3 + v.spikes % 3), Vector3.ONE * r * 1.35)
		"wave":
			core = _core(e, SpellMeshes.crescent(120.0 + 20.0 * v.shape), Vector3.ONE * r)
			var wave_core := core
			var life := e.life
			root.add_child(FxDriver.make(func(_d: float, _a: float):
				if is_instance_valid(wave_core) and is_instance_valid(e):
					var k := clampf(e.age / maxf(life, 0.01), 0.0, 1.0)
					wave_core.scale = Vector3.ONE * e.radius * lerpf(0.7, 1.9, k)))
	root.add_child(core)
	if v.ghost:
		var ghost := _core(e, core.mesh, core.scale * 1.35)
		ghost.set_instance_shader_parameter(&"fade", 0.35)
		root.add_child(ghost)
	var tw := r * (2.2 if e.form == "orb" else 1.6) * v.trail_width * 2.0
	if e.form == "wave":
		tw = r * 1.4
	_trail(e, core, tw, v.trail_time * (1.4 if e.form == "orb" else 1.0))
	if e.form == "chakram":
		var tip := Node3D.new()
		tip.position = Vector3(r * 1.3, 0, 0)
		root.add_child(tip)
		_trail(e, tip, r * 0.5, 0.18)
	_motes(e, root, 22 if e.form != "orb" else 34)
	_light(root, v.main, 1.4 if e.form != "orb" else 2.2, 2.4 + r * 3.0)
	if not e.secondary:
		Fx.burst(e.global_position, "glow", v.core, v.main, 6, 0.6)
		Audio.play("cast_light" if e.form != "orb" else "cast_heavy", e.global_position, -6.0, 1.0 + (v.seed % 7) * 0.03)


static func _serpent(e: SpellEntity, root: Node3D) -> void:
	var v := e.vis
	var head := _core(e, SpellMeshes.spindle(2, v.twist, v.shape), Vector3(0.9, 0.7, 1.4) * e.radius * 1.4)
	root.add_child(head)
	var segs: Array[MeshInstance3D] = []
	var n: int = e.get("segments").size()
	for i in n:
		var s := _core(e, SpellMeshes.sphere(8), Vector3.ONE * e.radius * lerpf(0.9, 0.45, float(i) / maxf(n, 1)))
		s.top_level = true
		root.add_child(s)
		segs.append(s)
	root.add_child(FxDriver.make(func(_d: float, _a: float):
		if not is_instance_valid(e):
			return
		var arr: Array = e.get("segments")
		for i in mini(arr.size(), segs.size()):
			if is_instance_valid(segs[i]):
				segs[i].global_position = arr[i]))
	_trail(e, head, e.radius * 1.2, 0.35)
	_motes(e, root, 18)
	_light(root, v.main, 1.3, 3.0)
	Audio.play("cast_light", e.global_position, -6.0, 0.8)


static func _nova(e: SpellEntity, root: Node3D) -> void:
	var v := e.vis
	var p := e.global_position
	var R := e.radius
	Fx.ring(p, R, v.main, v.core, 0.38, 0.16)
	Fx.ring(p, R * 0.7, v.rim, v.core, 0.28, 0.08, 2.0)
	var dome := _core(e, SpellMeshes.sphere(16), Vector3.ONE * R * 0.3)
	dome.position = Vector3.ZERO
	root.add_child(dome)
	var t := dome.create_tween()
	t.set_parallel(true)
	t.tween_property(dome, "scale", Vector3(R, R * 0.45, R), 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	t.tween_method(func(f: float): dome.set_instance_shader_parameter(&"fade", f), 0.9, 0.0, 0.26)
	for i in v.motes.size():
		Fx.burst(p + Vector3.UP * 0.4, mote_kind(v.motes[i]), v.main.lerp(v.core, 0.3), v.dark, int(18 + R * 4), 1.0 + R * 0.12)
	Fx.splat(p, R * (0.55 if not e.secondary else 0.35), v.dark.lerp(Pal.INK, 0.55))
	Fx.light_flash(p, v.main, 6.0, R * 2.4, 0.25)
	Audio.play("boom_small" if e.secondary else "nova", p, -2.0 if not e.secondary else -6.0)


static func _lance(e: SpellEntity, root: Node3D) -> void:
	var v := e.vis
	var a := Vector3(e.origin.x, 0.9, e.origin.z)
	var b: Vector3 = e.get("end_point")
	b.y = 0.9
	var len := a.distance_to(b)
	for vertical in [false, true]:
		var mi := MeshInstance3D.new()
		mi.mesh = SpellMeshes.beam_strip()
		mi.material_override = beam_material(v)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.top_level = true
		root.add_child(mi)
		mi.global_position = a
		mi.look_at(b, Vector3.UP)
		if vertical:
			mi.rotate_object_local(Vector3.FORWARD, PI * 0.5)
		var w := e.radius * 2.6
		mi.scale = Vector3(w, 1.0, len)
		var t := mi.create_tween()
		t.set_parallel(true)
		t.tween_property(mi, "scale:x", w * 0.15, 0.22).set_ease(Tween.EASE_IN)
		t.tween_method(func(f: float): mi.set_instance_shader_parameter(&"fade", f), 1.0, 0.0, 0.22)


static func lance_fired(e: SpellEntity) -> void:
	var v := e.vis
	var a := Vector3(e.origin.x, 0.9, e.origin.z)
	var b: Vector3 = e.get("end_point")
	var n := int(clampf(a.distance_to(b) / 2.0, 2, 7))
	for i in n:
		var p := a.lerp(Vector3(b.x, 0.9, b.z), (i + 0.5) / n)
		Fx.burst(p, mote_kind(v.motes[0]), v.main, v.dark, 5, 0.8)
	Fx.light_flash(a.lerp(b, 0.5), v.main, 5.0, 6.0, 0.2)
	Fx.ring(b, 1.1, v.main, v.core, 0.25, 0.2)
	Audio.play("lance", a, -3.0)


static func _rain_area(e: SpellEntity, root: Node3D) -> void:
	var v := e.vis
	var mi := MeshInstance3D.new()
	mi.mesh = SpellMeshes.flat_quad()
	mi.material_override = zone_material(v, 0.5)
	mi.position = Vector3(0, 0.03, 0)
	mi.scale = Vector3.ONE * e.radius * 1.1
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	mi.set_instance_shader_parameter(&"fade", 0.0)
	var t := mi.create_tween()
	t.tween_method(func(f: float): mi.set_instance_shader_parameter(&"fade", f), 0.0, 0.5, 0.2)
	Audio.play("cast_heavy", e.global_position, -8.0, 1.2)


static func rain_drop(e: SpellEntity, p: Vector3, fall_time: float) -> Node3D:
	var v := e.vis
	var holder := Node3D.new()
	Level.current.add_fx(holder)
	var start := p + Vector3(-1.2, 7.5, 1.4)
	holder.global_position = start
	var core := MeshInstance3D.new()
	core.mesh = SpellMeshes.spindle(2, 0.0, 0)
	core.material_override = v.energy_material()
	core.scale = Vector3(0.28, 0.28, 0.9) * v.size_mult
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(core)
	holder.look_at(p, Vector3.UP)
	var tr := Trail3D.new()
	tr.target = holder
	tr.width = 0.22 * v.size_mult
	tr.lifetime = 0.12
	tr.material_override = trail_material(v)
	holder.add_child(tr)
	var t := holder.create_tween()
	t.tween_property(holder, "global_position", p + Vector3.UP * 0.1, fall_time).set_ease(Tween.EASE_IN)
	t.tween_callback(func():
		tr.detach()
		holder.queue_free())
	return holder


static func drop_impact(e: SpellEntity, p: Vector3) -> void:
	var v := e.vis
	Fx.ring(p, 1.2 * v.size_mult, v.main, v.core, 0.25, 0.2)
	Fx.burst(p + Vector3.UP * 0.2, mote_kind(v.motes[0]), v.main, v.dark, 7, 0.7)
	Fx.splat(p, 0.35 * v.size_mult, v.dark.lerp(Pal.INK, 0.6))
	Audio.play("hit_soft", p, -8.0, 1.3, 0.15, 45)


static func _orbit(e: SpellEntity, root: Node3D) -> void:
	var v := e.vis
	var sats: Array[MeshInstance3D] = []
	var n: int = e.orbit_count
	for i in n:
		var s := _core(e, SpellMeshes.sphere(10), Vector3.ONE * 0.36 * v.size_mult)
		s.top_level = true
		root.add_child(s)
		sats.append(s)
		var tr := Trail3D.new()
		tr.target = s
		tr.width = 0.4 * v.size_mult
		tr.lifetime = 0.25
		tr.material_override = trail_material(v)
		root.add_child(tr)
	root.add_child(FxDriver.make(func(_d: float, _a: float):
		if not is_instance_valid(e):
			return
		var pos: Array = e.get("sat_positions")
		for i in mini(pos.size(), sats.size()):
			if pos[i] != null and is_instance_valid(sats[i]):
				sats[i].global_position = pos[i]))
	_light(root, v.main, 1.6, 4.0)
	Audio.play("cast_heavy", e.global_position, -6.0, 1.3)


static func _mine(e: SpellEntity, root: Node3D) -> void:
	var v := e.vis
	var mi := MeshInstance3D.new()
	mi.mesh = SpellMeshes.flat_quad()
	var tex := Fx.sigils.for_clause(e.clause)
	mi.material_override = sigil_material(tex, v.main, v.core, 0.4)
	mi.scale = Vector3.ONE * 1.25 * v.size_mult
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	mi.set_instance_shader_parameter(&"reveal", 0.0)
	var t := mi.create_tween()
	t.tween_method(func(f: float): mi.set_instance_shader_parameter(&"reveal", f), 0.0, 1.0, 0.3)
	e.set_meta("sigil", mi)
	Fx.splat(e.global_position, 0.5, v.dark.lerp(Pal.INK, 0.7))
	Audio.play("rune", e.global_position, -6.0)


static func mine_armed(e: SpellEntity) -> void:
	var mi: MeshInstance3D = e.get_meta("sigil", null)
	if mi == null or not is_instance_valid(mi):
		return
	var t := mi.create_tween().set_loops(0)
	t.tween_property(mi, "scale", mi.scale * 1.12, 0.35).set_trans(Tween.TRANS_SINE)
	t.tween_property(mi, "scale", mi.scale, 0.35).set_trans(Tween.TRANS_SINE)


static func _meteor(e: SpellEntity, root: Node3D) -> void:
	var v := e.vis
	var delay: float = e.get("delay")
	var p := e.global_position
	Fx.telegraph(p, 0, Vector2.ONE * e.radius, delay, Vector3.FORWARD, 0.6, v.main.lerp(Pal.TELEGRAPH, 0.35))
	var rock := MeshInstance3D.new()
	rock.mesh = SpellMeshes.rock(v.seed)
	rock.material_override = v.energy_material()
	rock.scale = Vector3.ONE * 0.9 * v.size_mult
	rock.top_level = true
	rock.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(rock)
	var start := p + Vector3(-4.0, 16.0, 5.0)
	rock.global_position = start
	var tr := Trail3D.new()
	tr.target = rock
	tr.width = 1.5 * v.size_mult
	tr.lifetime = 0.4
	tr.material_override = trail_material(v)
	root.add_child(tr)
	Fx.emitter(rock, mote_kind(v.motes[0]), v.main, v.dark, 30, 0.8)
	var t := rock.create_tween()
	t.set_parallel(true)
	t.tween_property(rock, "global_position", p + Vector3.UP * 0.3, delay).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	t.tween_property(rock, "rotation", Vector3(TAU * 1.3, TAU * 0.7, 0), delay)
	Audio.play("meteor_fall", p, -4.0)


static func big_impact(e: SpellEntity, p: Vector3, R: float) -> void:
	var v := e.vis
	Fx.ring(p, R * 1.1, v.main, v.core, 0.42, 0.2, 3.5)
	Fx.ring(p, R * 0.6, v.rim, v.core, 0.3, 0.1, 2.0)
	for m in v.motes:
		Fx.burst(p + Vector3.UP * 0.3, mote_kind(m), v.main.lerp(v.core, 0.25), v.dark, int(24 + R * 6), 1.2 + R * 0.1)
	Fx.burst(p, "dust", Pal.PAPER_DARK, Color(Pal.PAPER_SHADOW, 0.0), 10, 1.6)
	Fx.burst(p + Vector3.UP * 0.3, "paper", Pal.PAPER, Pal.PAPER_DARK, 8, 1.0)
	Fx.splat(p, R * 0.75, v.dark.lerp(Pal.INK, 0.5))
	Fx.light_flash(p, v.main, 8.0, R * 3.0, 0.3)
	Audio.play("boom_big", p, 0.0)


static func _vortex(e: SpellEntity, root: Node3D) -> void:
	var v := e.vis
	var mi := MeshInstance3D.new()
	mi.mesh = SpellMeshes.flat_quad()
	mi.material_override = zone_material(v, 2.5)
	mi.scale = Vector3.ONE * e.radius
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	var eye := _core(e, SpellMeshes.sphere(14), Vector3.ONE * 0.55 * v.size_mult)
	eye.position = Vector3.UP * 0.9
	root.add_child(eye)
	var implode := Fx.emitter(root, "implode", v.main, v.core, 40, 1.0)
	implode.position = Vector3.UP * 0.4
	_light(root, v.main, 2.2, e.radius * 1.4)
	root.add_child(FxDriver.make(func(d: float, _a: float):
		if is_instance_valid(mi):
			mi.rotate_y(-d * 2.5)))
	Audio.play("vortex", e.global_position, -4.0)


static func _totem(e: SpellEntity, root: Node3D) -> void:
	var v := e.vis
	var ob := _core(e, SpellMeshes.obelisk(), Vector3.ONE)
	ob.position = Vector3.UP * 1.15
	root.add_child(ob)
	var ring := MeshInstance3D.new()
	ring.mesh = SpellMeshes.flat_quad()
	ring.material_override = sigil_material(Fx.sigils.for_clause(e.clause), v.main, v.core, 1.2)
	ring.position = Vector3.UP * 0.05
	ring.scale = Vector3.ONE * 1.3
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ring)
	_light(root, v.main, 1.6, 4.0)
	ob.scale = Vector3(1, 0.01, 1)
	var t := ob.create_tween()
	t.tween_property(ob, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Fx.burst(e.global_position, "paper", Pal.PAPER, Pal.PAPER_DARK, 8, 1.0)
	Audio.play("totem", e.global_position, -4.0)


static func totem_shot(e: SpellEntity) -> void:
	Fx.light_flash(e.global_position + Vector3.UP * 1.6, e.vis.main, 3.0, 3.0, 0.12)


static func _zone(e: SpellEntity, root: Node3D) -> void:
	var v := e.vis
	var mi := MeshInstance3D.new()
	mi.mesh = SpellMeshes.flat_quad()
	var col_v := v
	mi.material_override = zone_material(col_v, 0.6 if e.get("zone_kind") != "sap" else 1.2)
	mi.scale = Vector3.ONE * e.radius
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	mi.set_instance_shader_parameter(&"seed", float(v.seed % 100))
	var life := e.life
	var t := mi.create_tween()
	t.tween_method(func(f: float): mi.set_instance_shader_parameter(&"fade", f), 0.0, 1.0, 0.2)
	t.tween_interval(maxf(0.0, life - 0.5))
	t.tween_method(func(f: float): mi.set_instance_shader_parameter(&"fade", f), 1.0, 0.0, 0.3)
	var kind := "bubble"
	match e.get("zone_kind"):
		"steam":
			kind = "dust"
		"sap":
			kind = "twinkle"
		"linger":
			kind = mote_kind(v.motes[0])
	var em := Fx.emitter(root, kind, v.main if kind != "dust" else Color(1, 1, 1, 0.7), v.dark, int(12 * e.radius), 1.4)
	em.position = Vector3.UP * 0.2


static func blink_trail(e: SpellEntity, from: Vector3, to: Vector3) -> void:
	var v := e.vis
	var a := from + Vector3.UP * 0.9
	var b := to + Vector3.UP * 0.9
	var mi := MeshInstance3D.new()
	mi.mesh = SpellMeshes.beam_strip()
	mi.material_override = beam_material(v)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Level.current.add_fx(mi)
	mi.global_position = a
	if a.distance_to(b) > 0.1:
		mi.look_at(b, Vector3.UP)
	mi.scale = Vector3(0.9, 1.0, a.distance_to(b))
	var t := mi.create_tween()
	t.tween_method(func(f: float): mi.set_instance_shader_parameter(&"fade", f), 1.0, 0.0, 0.3)
	t.tween_callback(mi.queue_free)
	Fx.burst(a, "glow", v.main, v.dark, 12, 1.0)
	Fx.burst(b, mote_kind(v.motes[0]), v.main, v.dark, 16, 1.0)
	Fx.ring(to, e.radius, v.main, v.core, 0.3, 0.18)
	Audio.play("blink", to, -3.0)


# --- events ---------------------------------------------------------------------------
static func impact(e: SpellEntity, h: Hit, t: Node3D) -> void:
	var v := e.vis
	var p := Vector3(t.global_position.x, 0.9, t.global_position.z)
	Fx.burst(p, mote_kind(v.motes[0]), v.main.lerp(v.core, 0.3), v.dark, 8 if not h.crit else 16, 0.8)
	Fx.burst(p, "ink", Pal.INK, Pal.INK_SOFT, 5, 0.6)
	if h.crit:
		Fx.ring(p, 1.4, Pal.GOLD_BRIGHT, Color.WHITE, 0.25, 0.12)
	Fx.damage_number(p + Vector3.UP * 0.9, h.dealt, v.main, h.crit)
	if randf() < 0.45:
		Fx.splat(t.global_position + Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4)), randf_range(0.2, 0.4), v.dark.lerp(Pal.INK, 0.7))
	Audio.play("hit_hard" if h.crit or h.dealt > 18.0 else "hit_soft", p, -3.0)
	Audio.play("el_%s" % _sound_element(v.element), p, -9.0, 1.0, 0.1, 60)


static func _sound_element(key: String) -> String:
	var parts := Elem.parts_of(key)
	return parts[0] if not parts.is_empty() else "arcane"


static func on_finish(e: SpellEntity, p: Vector3) -> void:
	var v := e.vis
	match e.form:
		"bolt", "orb", "chakram", "wave", "serpent":
			Fx.burst(p + Vector3.UP * 0.9, mote_kind(v.motes[0]), v.main, v.dark, 10, 0.8)
			Fx.ring(p, 0.9 * v.size_mult, v.main, v.core, 0.22, 0.2)
	var fx: Node3D = e.get_node_or_null("Fx")
	if fx:
		detach_trails(fx)
	for c in e.get_children():
		if c is Trail3D:
			c.detach()


static func detach_trails(root: Node) -> void:
	for c in root.get_children():
		if c is Trail3D:
			c.detach()
		elif c is GPUParticles3D:
			Fx.stop_emitter(c)
		elif c is Node3D and c.get_child_count() > 0:
			detach_trails(c)


static func charging(e: SpellEntity, hold_left: float) -> void:
	var fx: Node3D = e.get_node_or_null("Fx")
	if fx == null:
		return
	var core: MeshInstance3D = fx.get_node_or_null("Core")
	if core:
		core.set_instance_shader_parameter(&"charge", clampf(1.0 - hold_left * 2.0, 0.0, 1.0))


static func ricochet(e: SpellEntity, p: Vector3) -> void:
	Fx.burst(p, "spark", e.vis.core, e.vis.main, 8, 0.7)
	Audio.play("ricochet", p, -6.0)


static func payload_sigil(p: Vector3, c: SpellClause) -> void:
	if Level.current == null:
		return
	var v := SpellVisual.for_clause(c, c.dominant_form())
	var mi := MeshInstance3D.new()
	mi.mesh = SpellMeshes.flat_quad()
	mi.material_override = sigil_material(Fx.sigils.for_clause(c), v.main, v.core, 2.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Level.current.add_fx(mi)
	mi.global_position = Vector3(p.x, 0.05, p.z)
	mi.scale = Vector3.ONE * 0.4
	var t := mi.create_tween()
	t.set_parallel(true)
	t.tween_property(mi, "scale", Vector3.ONE * 1.1, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_method(func(f: float): mi.set_instance_shader_parameter(&"fade", f), 1.0, 0.0, 0.45).set_delay(0.1)
	t.chain().tween_callback(mi.queue_free)


static func echo_ripple(p: Vector3, c: SpellClause) -> void:
	var v := SpellVisual.for_clause(c, c.dominant_form())
	Fx.ring(p, 1.4, v.rim, v.core, 0.3, 0.08, 1.6)
	Audio.play("echo", p, -8.0)


static func ward_flash(p: Vector3, c: SpellClause) -> void:
	var v := SpellVisual.for_clause(c, c.dominant_form())
	Fx.ring(p, 3.5, Pal.GOLD_BRIGHT, v.core, 0.4, 0.1, 2.5)
	Fx.burst(p + Vector3.UP, "twinkle", Pal.GOLD_BRIGHT, v.main, 14, 1.2)
	Audio.play("ward", p, -4.0)


static func freeze_burst(t: Node3D) -> void:
	var p := t.global_position + Vector3.UP * 0.8
	Fx.burst(p, "shard", Color("dff9ff"), Color("5aa9ff"), 14, 1.0)
	Fx.ring(t.global_position, 1.3, Color("9fe8ff"), Color.WHITE, 0.3, 0.1)
	Fx.text_pop(p + Vector3.UP * 1.0, TranslationServer.translate("FX_FROZEN"), Color("bdf3ff"), 34)
	Audio.play("freeze", p, -4.0)


static func shatter(p: Vector3) -> void:
	Fx.burst(p + Vector3.UP * 0.8, "shard", Color.WHITE, Color("8fa8ff"), 26, 1.4)
	Fx.ring(p, 2.2, Color("c8bbff"), Color.WHITE, 0.3, 0.14)
	Audio.play("shatter", p, -2.0)
	Juice.shake(0.25)


static func pop(p: Vector3, key: String, R: float) -> void:
	var pal := Elem.palette(key)
	Fx.ring(p, R, pal.main, pal.core, 0.26, 0.18)
	for m in Elem.motes(key):
		Fx.burst(p + Vector3.UP * 0.6, mote_kind(m), pal.main, pal.dark, 10, 0.9)
	Audio.play("boom_small", p, -8.0, 1.2)


static func sky_strike(p: Vector3, key: String) -> void:
	var pal := Elem.palette(key)
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.25
	c.bottom_radius = 0.45
	c.height = 14.0
	c.radial_segments = 6
	mi.mesh = c
	var m := ShaderMaterial.new()
	m.shader = BEAM_SHADER
	m.set_shader_parameter("core", pal.core)
	m.set_shader_parameter("color", pal.main)
	m.set_shader_parameter("jagged", 1.0)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Level.current.add_fx(mi)
	mi.global_position = Vector3(p.x, 7.0, p.z)
	var t := mi.create_tween()
	t.tween_method(func(f: float): mi.set_instance_shader_parameter(&"fade", f), 1.0, 0.0, 0.3)
	t.tween_callback(mi.queue_free)
	Fx.ring(p, 1.6, pal.main, pal.core, 0.3, 0.2)
	Fx.light_flash(p, pal.main, 6.0, 6.0, 0.2)
	Audio.play("zap", p, -2.0)
	Juice.shake(0.15)


## Lightning / links between two points. style: storm, chain, ray, shard, flame.
static func arc(a: Vector3, b: Vector3, key: String, style: String) -> void:
	if Level.current == null:
		return
	var pal := Elem.palette(key)
	var mi := MeshInstance3D.new()
	var im := ImmediateMesh.new()
	mi.mesh = im
	var m := ShaderMaterial.new()
	m.shader = BEAM_SHADER
	m.set_shader_parameter("core", pal.core)
	m.set_shader_parameter("color", pal.main if style != "chain" else Pal.INK_SOFT)
	m.set_shader_parameter("glow", 3.0 if style != "chain" else 1.0)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Level.current.add_fx(mi)
	var A := a + Vector3.UP * 1.0
	var B := b + Vector3.UP * 1.0
	var jag := 0.0
	match style:
		"storm":
			jag = 0.55
		"flame":
			jag = 0.3
		"chain":
			jag = 0.12
	var build := func():
		im.clear_surfaces()
		var cam := mi.get_viewport().get_camera_3d()
		var to_cam := Vector3.UP if cam == null else (cam.global_position - A).normalized()
		var dir := (B - A)
		var side := dir.cross(to_cam).normalized()
		var n := 10
		im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
		for i in n + 1:
			var t := float(i) / n
			var p := A.lerp(B, t)
			if i > 0 and i < n:
				p += side * randf_range(-jag, jag) + Vector3.UP * randf_range(-jag, jag) * 0.5
			var w := 0.16 if style != "ray" else 0.22
			im.surface_set_uv(Vector2(0, t))
			im.surface_add_vertex(p + side * w)
			im.surface_set_uv(Vector2(1, t))
			im.surface_add_vertex(p - side * w)
		im.surface_end()
	build.call()
	var tw := mi.create_tween()
	tw.tween_interval(0.05)
	tw.tween_callback(build)
	tw.tween_interval(0.05)
	tw.tween_callback(build)
	tw.tween_method(func(f: float): mi.set_instance_shader_parameter(&"fade", f), 1.0, 0.0, 0.1)
	tw.tween_callback(mi.queue_free)
	if style == "storm":
		Audio.play("zap", b, -8.0, 1.2, 0.15, 50)

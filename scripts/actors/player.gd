class_name Player
extends Actor
## A Wick Knight. Reads its own PlayerInput (local co-op), moves with snappy
## acceleration, dashes with i-frames (perfect dodges slow time and grant
## "Living Ink"), swings a three-hit quill combo that refunds spell cooldowns,
## and casts the three pages of its grimoire. The helm's candle flame is the
## health bar: it shrinks as the knight weakens and goes out when downed.

signal cast_started(page: int)

const MODEL := "res://assets/models/knight.glb"
const BOOK_MODEL := "res://assets/models/grimoire.glb"
const RING_SHADER := preload("res://shaders/fx/player_ring.gdshader")

const MOVE_SPEED := 7.2
const ACCEL := 70.0
const DECEL := 55.0
const DASH_SPEED := 23.0
const DASH_TIME := 0.16
const DASH_IFRAMES := 0.24
const PERFECT_WINDOW := 0.13
const HIT_IFRAMES := 0.7
const REVIVE_TIME := 1.6
const REVIVE_RADIUS := 1.7

## Quill combo: [anim, hit_time, lock, radius, arc_deg, damage, knockback]
const COMBO := [
	["attack_1", 0.06, 0.26, 2.3, 120.0, 8.0, 3.5],
	["attack_2", 0.06, 0.26, 2.3, 120.0, 9.0, 3.5],
	["attack_3", 0.17, 0.42, 2.7, 150.0, 15.0, 7.5],
]

var profile: PlayerProfile
var input: PlayerInput
var downed := false
var height := 1.55
var facing := Vector3(0, 0, 1)
var aim_dir := Vector3(0, 0, 1)
var aim_point := Vector3.ZERO
var move_vel := Vector3.ZERO
var _rig: ProceduralRig
var cooldowns: Array[float] = [0.0, 0.0, 0.0]
var cooldown_max: Array[float] = [1.0, 1.0, 1.0]
var dash_charges := 2
var iframes := 0.0
var frozen_input := false
var living_ink := 0.0
var revive_progress := 0.0
var auto_revive_timer := 0.0

var _model: Node3D
var _anim: AnimationPlayer
var _book: Node3D
var _book_anim: AnimationPlayer
var _flame: GPUParticles3D
var _flame_light: OmniLight3D
var _ring: MeshInstance3D
var _tag: Label3D
var _dash_timer := 0.0
var _dash_age := 99.0
var _dash_dir := Vector3.ZERO
var _dash_recharge := 0.0
var _action_lock := 0.0
var _move_slow := 1.0
var _combo_step := 0
var _combo_window := 0.0
var _swing_pending := -1.0
var _swing_data: Array = []
var _cast_pending := -1.0
var _cast_page := -1
var _cast_aim := {}
var _anim_current := ""
var _anim_lock := 0.0
var _shield_time := 0.0
var _shield_node: MeshInstance3D
var _footstep_t := 0.0
var _interact_target: Node = null
var _prompt: Label3D
var _book_pos := Vector3.ZERO
var _book_rot := Quaternion.IDENTITY


func setup(p: PlayerProfile) -> void:
	profile = p
	input = p.input
	p.actor = self


func _ready() -> void:
	super._ready()
	radius = 0.42
	weight = 1.0
	max_hp = profile.stat("max_hp")
	hp = profile.hp
	collision_layer = Combat.LAYER_PLAYERS
	collision_mask = Combat.LAYER_WORLD
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.36
	cap.height = 1.3
	shape.shape = cap
	shape.position = Vector3(0, 0.66, 0)
	add_child(shape)
	_build_visuals()
	collect_geometry()
	_book_pos = global_position + Vector3(0.7, 1.45, 0.0)
	dash_charges = int(profile.stat("dash_charges"))
	Combat.register_player(self)
	for i in 3:
		cooldowns[i] = 0.0
	_play("idle", 0.0)


func _exit_tree() -> void:
	Combat.unregister_player(self)
	if profile and profile.actor == self:
		profile.actor = null


# --- visuals -------------------------------------------------------------------------
func _build_visuals() -> void:
	var cloth := profile.cloth_color()
	_model = Toon.spawn(MODEL, {"Cloth": cloth, "ClothDark": cloth.darkened(0.45)})
	pivot.add_child(_model)
	_anim = Toon.find_anim_player(_model)
	for loop_name in ["idle", "run", "dash"]:
		if _anim and _anim.has_animation(loop_name):
			_anim.get_animation(loop_name).loop_mode = Animation.LOOP_LINEAR if loop_name != "dash" else Animation.LOOP_NONE
	var skel := Toon.find_skeleton(_model)
	if skel:
		_rig = ProceduralRig.new()
		skel.add_child(_rig)
		var att := BoneAttachment3D.new()
		att.bone_name = "flame"
		skel.add_child(att)
		_flame = Fx.emitter(att, "flame", profile.flame_color().lerp(Pal.EMBER_HOT, 0.5), profile.flame_color(), 18, 0.9)
		var pm := _flame.process_material as ParticleProcessMaterial
		_flame.process_material = pm.duplicate()
		(_flame.process_material as ParticleProcessMaterial).emission_sphere_radius = 0.04
		(_flame.process_material as ParticleProcessMaterial).spread = 18.0
		_flame_light = OmniLight3D.new()
		_flame_light.light_color = profile.flame_color().lerp(Color("ffd6a0"), 0.5)
		_flame_light.light_energy = 1.4
		_flame_light.omni_range = 4.5
		_flame_light.shadow_enabled = false
		att.add_child(_flame_light)
	_book = Toon.spawn(BOOK_MODEL, {"Cover": cloth.darkened(0.25)})
	_book.top_level = true
	_book.scale = Vector3.ONE * 0.9
	add_child(_book)
	_book_anim = Toon.find_anim_player(_book)
	if _book_anim:
		_book_anim.get_animation("open_idle").loop_mode = Animation.LOOP_LINEAR
		_book_anim.play("open_idle")
	_ring = MeshInstance3D.new()
	_ring.mesh = SpellMeshes.flat_quad()
	var rm := ShaderMaterial.new()
	rm.shader = RING_SHADER
	rm.set_shader_parameter("color", profile.flame_color())
	_ring.material_override = rm
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.position = Vector3(0, 0.03, 0)
	_ring.scale = Vector3.ONE * 0.95
	add_child(_ring)
	_tag = Label3D.new()
	_tag.text = ["I", "II", "III", "IV"][profile.index]
	_tag.font = UiFonts.display(700)
	_tag.font_size = 64
	_tag.outline_size = 16
	_tag.modulate = profile.flame_color()
	_tag.outline_modulate = Pal.INK
	_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_tag.no_depth_test = true
	_tag.fixed_size = true
	_tag.pixel_size = 0.0005
	_tag.position = Vector3(0, 2.25, 0)
	add_child(_tag)
	_prompt = Label3D.new()
	_prompt.font = UiFonts.label(700)
	_prompt.font_size = 44
	_prompt.outline_size = 12
	_prompt.outline_modulate = Pal.INK
	_prompt.modulate = Pal.PAPER_LIGHT
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.no_depth_test = true
	_prompt.fixed_size = true
	_prompt.pixel_size = 0.0005
	_prompt.position = Vector3(0, 2.7, 0)
	_prompt.visible = false
	add_child(_prompt)


func _play(anim: String, blend := 0.12, speed := 1.0) -> void:
	if _anim == null or not _anim.has_animation(anim):
		return
	if _anim_current == anim and _anim.is_playing() and anim in ["idle", "run"]:
		return
	_anim_current = anim
	_anim.play(anim, blend, speed)


# --- per frame ------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if dead:
		return
	tick_actor(delta)
	if hp <= 0.0 and not downed:
		_go_down()
	_update_timers(delta)
	if downed:
		_downed_process(delta)
		_update_book(delta)
		return
	_update_aim()
	if not frozen_input:
		_handle_actions()
	_update_swing(delta)
	_update_cast(delta)
	_move(delta)
	_update_interact()
	_update_visuals(delta)
	_update_book(delta)


func _update_timers(delta: float) -> void:
	for i in 3:
		cooldowns[i] = maxf(0.0, cooldowns[i] - delta)
	iframes = maxf(0.0, iframes - delta)
	_dash_timer = maxf(0.0, _dash_timer - delta)
	_dash_age += delta
	_action_lock = maxf(0.0, _action_lock - delta)
	_anim_lock = maxf(0.0, _anim_lock - delta)
	_combo_window = maxf(0.0, _combo_window - delta)
	living_ink = maxf(0.0, living_ink - delta)
	if _shield_time > 0.0:
		_shield_time -= delta
		if _shield_time <= 0.0:
			_set_shield(0.0)
	if dash_charges < int(profile.stat("dash_charges")):
		_dash_recharge += delta
		if _dash_recharge >= profile.stat("dash_cd"):
			_dash_recharge = 0.0
			dash_charges += 1


func _update_aim() -> void:
	var level := Level.current
	if input.uses_mouse() and level and level.camera_rig:
		var gp := level.camera_rig.mouse_ground(input.mouse_screen, 0.0)
		var to := Combat.flat(gp - global_position)
		if to.length() > 0.2:
			aim_dir = to.normalized()
		aim_point = gp
		return
	var stick := Vector3(input.stick_aim.x, 0.0, input.stick_aim.y)
	var base := aim_dir
	if stick.length() > 0.3:
		base = stick.normalized()
	elif input.move.length() > 0.2:
		base = Vector3(input.move.x, 0.0, input.move.y).normalized()
	# Aim assist: gently snap toward a target inside a 35 degree cone.
	var t := Combat.enemy_in_cone(global_position, base, 13.0, cos(deg_to_rad(35.0)))
	if t:
		var to_t := Combat.flat(t.global_position - global_position).normalized()
		aim_dir = base.slerp(to_t, 0.75).normalized()
		aim_point = t.global_position
	else:
		aim_dir = base
		aim_point = global_position + aim_dir * 6.5


## Used by echoes and "And Then" links to recast from where the knight is now.
func aim_state() -> Dictionary:
	return {"origin": global_position, "dir": aim_dir, "point": aim_point}


func _handle_actions() -> void:
	if input.consume("dash"):
		_try_dash()
	if _dash_timer > 0.0:
		return
	for i in 3:
		if input.consume("spell_%d" % i, 180):
			if _try_cast(i):
				return
	if input.consume("attack", 160):
		_try_attack()
	if input.consume("interact") and _interact_target and is_instance_valid(_interact_target):
		_interact_target.interact(self)
	if input.consume("grimoire"):
		var level := Level.current
		if level and level.has_method("open_grimoire"):
			level.open_grimoire(self)


func _move(delta: float) -> void:
	var want := Vector3(input.move.x, 0.0, input.move.y) if not frozen_input else Vector3.ZERO
	var spd := MOVE_SPEED * profile.stat("speed") * status.speed_mult()
	if _action_lock > 0.0:
		spd *= _move_slow
	if stunned():
		want = Vector3.ZERO
	var target := want * spd
	if _dash_timer > 0.0:
		move_vel = _dash_dir * DASH_SPEED
	else:
		var rate := ACCEL if want.length() > 0.05 else DECEL
		move_vel = move_vel.move_toward(target, rate * delta)
	velocity = move_vel + knock
	velocity.y = 0.0
	move_and_slide()
	global_position.y = 0.0
	_apply_leash()
	var moving := move_vel.length() > 0.6
	# Facing: aim while acting, movement otherwise.
	var want_face := facing
	if _action_lock > 0.0 or _anim_lock > 0.0:
		want_face = aim_dir
	elif moving:
		want_face = Combat.flat(move_vel).normalized()
	facing = facing.slerp(want_face, 1.0 - exp(-delta * 18.0)).normalized()
	pivot.rotation.y = atan2(facing.x, facing.z)
	if _rig:
		_rig.velocity = Combat.flat(velocity)
		_rig.facing_yaw = pivot.rotation.y
		_rig.want_yaw = atan2(want_face.x, want_face.z)
		_rig.amount = 0.0 if downed else 1.0
	if _anim_lock <= 0.0 and _dash_timer <= 0.0:
		if moving:
			_play("run", 0.12, clampf(move_vel.length() / MOVE_SPEED, 0.6, 1.3))
			_footstep_t -= delta * move_vel.length()
			if _footstep_t <= 0.0:
				_footstep_t = 2.1
				Audio.play("step", global_position, -18.0, 1.0, 0.15, 60)
				if randf() < 0.35:
					Fx.burst(global_position + Vector3.UP * 0.1, "dust", Pal.PAPER_DARK, Color(Pal.PAPER_SHADOW, 0.0), 2, 0.6)
		else:
			_play("idle", 0.2)


func _apply_leash() -> void:
	var level := Level.current
	if level == null or level.camera_rig == null or Combat.players.size() < 2:
		return
	var r := level.camera_rig.leash_rect(1.4)
	var p := global_position
	p.x = clampf(p.x, r.position.x, r.end.x)
	p.z = clampf(p.z, r.position.y, r.end.y)
	if not p.is_equal_approx(global_position):
		global_position = p


# --- dash -----------------------------------------------------------------------------
func _try_dash() -> void:
	if dash_charges <= 0 or stunned():
		return
	dash_charges -= 1
	var d := Vector3(input.move.x, 0.0, input.move.y)
	_dash_dir = d.normalized() if d.length() > 0.2 else facing
	_dash_timer = DASH_TIME
	_dash_age = 0.0
	iframes = maxf(iframes, DASH_IFRAMES)
	_swing_pending = -1.0
	_cast_pending = -1.0
	_action_lock = 0.0
	_anim_lock = DASH_TIME
	facing = _dash_dir
	_play("dash", 0.04)
	stretch(0.22, 0.25)
	Fx.burst(global_position + Vector3.UP * 0.4, "dust", Pal.PAPER_DARK, Color(Pal.PAPER_SHADOW, 0.0), 6, 1.0, -_dash_dir)
	Fx.burst(global_position + Vector3.UP * 0.8, "ink", Pal.INK, Pal.INK_SOFT, 4, 0.5, -_dash_dir)
	Audio.play("dash", global_position, -6.0, 1.0, 0.1)
	Events.dashed.emit(self)


func _perfect_dodge() -> void:
	profile.perfect_dodges += 1
	living_ink = 2.5
	Juice.slowmo(0.45, 0.28, 0.35)
	Juice.pulse(&"perfect", 1.0)
	Fx.text_pop(global_position + Vector3.UP * 2.3, tr("FX_PERFECT"), profile.flame_color().lerp(Color.WHITE, 0.4), 50)
	Fx.ring(global_position, 2.6, profile.flame_color(), Color.WHITE, 0.45, 0.1, 2.5)
	Fx.burst(global_position + Vector3.UP, "twinkle", Pal.GOLD_BRIGHT, profile.flame_color(), 16, 1.2)
	Audio.play("perfect", global_position, -2.0, 1.0, 0.0, 0)
	input.rumble(0.2, 0.5, 0.15)
	Events.perfect_dodge.emit(self)


# --- quill combo ----------------------------------------------------------------------
func _try_attack() -> void:
	if _cast_pending >= 0.0 or stunned():
		return
	if _swing_pending >= 0.0:
		return
	if _action_lock > 0.08 and _combo_window <= 0.0:
		return
	if _combo_window <= 0.0:
		_combo_step = 0
	var step: Array = COMBO[_combo_step]
	_swing_data = step
	_swing_pending = float(step[1])
	_action_lock = float(step[2])
	_anim_lock = float(step[2])
	_move_slow = 0.3
	facing = aim_dir
	_play(step[0], 0.03, 1.0)
	move_vel += aim_dir * (4.0 if _combo_step < 2 else 6.0)
	Audio.play("swing", global_position, -6.0, 1.0 + 0.08 * _combo_step, 0.08)
	_combo_step = (_combo_step + 1) % COMBO.size()
	_combo_window = float(step[2]) + 0.32 if _combo_step != 0 else 0.0


func _update_swing(delta: float) -> void:
	if _swing_pending < 0.0:
		return
	_swing_pending -= delta
	if _swing_pending > 0.0:
		return
	_swing_pending = -1.0
	var step := _swing_data
	var r: float = step[3]
	var half := deg_to_rad(float(step[4]) * 0.5)
	var is_finisher: bool = step[0] == "attack_3"
	SwingFx.slash(self, aim_dir, r, float(step[4]), is_finisher)
	var hits := 0
	for e in Combat.enemies_near(global_position, r):
		var to := Combat.flat(e.global_position - global_position)
		if to.length() > 0.3 and aim_dir.angle_to(to.normalized()) > half:
			continue
		var h := Hit.make(float(step[5]) * profile.stat("might") * Relics.damage_mult(profile, e), self, e.global_position, "melee")
		h.profile = profile
		if randf() < profile.stat("crit"):
			h.crit = true
			h.amount *= profile.stat("crit_mult")
		h.knockback = (to.normalized() if to.length() > 0.1 else aim_dir) * float(step[6])
		h.stagger = 0.15 if not is_finisher else 0.4
		e.take_hit(h)
		profile.damage_dealt += h.dealt
		if h.killed:
			profile.kills += 1
		hits += 1
		Fx.damage_number(e.global_position + Vector3.UP * 1.6, h.dealt, Pal.PAPER_LIGHT, h.crit)
		Fx.burst(e.global_position + Vector3.UP * 0.9, "ink", Pal.INK, Pal.INK_SOFT, 7, 0.8, to)
		Fx.splat(e.global_position + to.normalized() * 0.6, randf_range(0.25, 0.45), Pal.INK)
		Events.melee_hit.emit(self, e, h)
		if hits <= 3:
			_ink_flow()
	if hits > 0:
		Juice.hitstop(0.04 if not is_finisher else 0.07)
		Juice.shake(0.08 + 0.05 * hits if not is_finisher else 0.3)
		Audio.play("hit_melee", global_position, -3.0, 1.0, 0.1)
		input.rumble(0.3, 0.15 if not is_finisher else 0.4, 0.08)
	if is_finisher:
		# The third stroke flings an ink crescent.
		var c := SpellCast.make(self, profile, _finisher_program(), aim_point)
		c.power_mult = 0.55
		SpellRunner.cast(c, global_position + aim_dir * 0.8, aim_dir)
		Juice.shake(0.18)


static var _finisher: SpellProgram


static func _finisher_program() -> SpellProgram:
	if _finisher == null:
		_finisher = SpellProgram.compile(["wave"])
	return _finisher


## Quill hits refill the ink: every hit shortens spell cooldowns.
func _ink_flow() -> void:
	var amount := profile.stat("ink_flow")
	for i in 3:
		cooldowns[i] = maxf(0.0, cooldowns[i] - amount)


# --- casting --------------------------------------------------------------------------
func _try_cast(page: int) -> bool:
	var prog := profile.grimoire.program(page)
	if prog == null or prog.empty:
		Audio.ui("fizzle", -6.0)
		return false
	if cooldowns[page] > 0.0 or stunned() or _cast_pending >= 0.0:
		return false
	var form := prog.dominant_form()
	var anim: String = GlyphDB.FORMS[form].anim
	var windup: float = {"cast_thrust": 0.08, "cast_slam": 0.16, "cast_raise": 0.12, "cast_sweep": 0.09, "cast_spin": 0.1, "cast_blink": 0.08}.get(anim, 0.1)
	_cast_page = page
	_cast_pending = windup
	_cast_aim = {"dir": aim_dir, "point": aim_point}
	_action_lock = windup + 0.18
	_anim_lock = windup + 0.25
	_move_slow = 0.45
	_swing_pending = -1.0
	facing = aim_dir
	_play(anim, 0.04, 1.0)
	CastCircle.spawn(self, prog, windup + 0.25)
	if _book_anim:
		_book_anim.play("flip", 0.05)
		_book_anim.queue("open_idle")
	cast_started.emit(page)
	return true


func _update_cast(delta: float) -> void:
	if _cast_pending < 0.0:
		return
	_cast_pending -= delta
	if _cast_pending > 0.0:
		return
	_cast_pending = -1.0
	var page := _cast_page
	var prog := profile.grimoire.program(page)
	if prog == null or prog.empty:
		return
	var c := SpellCast.make(self, profile, prog, _cast_aim.point)
	var free_cast := living_ink > 0.0
	if free_cast:
		c.power_mult *= 1.3
		living_ink = 0.0
		Fx.text_pop(global_position + Vector3.UP * 2.4, tr("FX_LIVING_INK"), Pal.GOLD_BRIGHT, 38)
	SpellRunner.cast(c, global_position + Vector3(_cast_aim.dir) * 0.6, _cast_aim.dir)
	profile.casts += 1
	cooldown_max[page] = prog.cooldown * profile.stat("haste")
	cooldowns[page] = 0.0 if free_cast else cooldown_max[page]
	Juice.shake(0.06)
	input.rumble(0.15, 0.0, 0.06)
	Events.spell_cast.emit(self, prog, page)


# --- damage, healing, shields ---------------------------------------------------------
func targetable() -> bool:
	return not dead and not downed


func take_hit(hit: Hit) -> void:
	if dead or downed:
		return
	if iframes > 0.0:
		if _dash_age < PERFECT_WINDOW + DASH_TIME and hit.kind != "dot":
			_perfect_dodge()
			_dash_age = 99.0
		return
	var amount := maxf(0.0, hit.amount - profile.stat("armor"))
	if _shield_time > 0.0 and profile.shield > 0.0:
		var absorbed := minf(profile.shield, amount)
		profile.shield -= absorbed
		amount -= absorbed
		Fx.burst(global_position + Vector3.UP, "twinkle", Pal.GOLD_BRIGHT, Pal.GOLD, 8, 0.8)
		if profile.shield <= 0.0:
			_set_shield(0.0)
		if amount <= 0.0:
			Audio.play("ward", global_position, -8.0)
			return
	hit.amount = amount
	super.take_hit(hit)
	profile.hp = hp
	if hit.kind != "dot":
		iframes = HIT_IFRAMES
		_anim_lock = 0.18
		_play("hit", 0.04)
		Juice.hitstop(0.07)
		Juice.shake(0.4, hit.knockback)
		Juice.pulse(&"hurt", clampf(hit.dealt / 15.0, 0.4, 1.0))
		Audio.play("hurt", global_position, -2.0)
		input.rumble(0.6, 0.8, 0.2)
		Fx.burst(global_position + Vector3.UP * 0.9, "flame", profile.flame_color(), Pal.EMBER, 10, 0.9)
	Events.player_damaged.emit(self, hit)


func die(hit: Hit) -> void:
	# Knights never die outright: they go down and can be rekindled.
	hp = 0.0
	profile.hp = 0.0
	if not downed:
		_go_down()


func heal(amount: float) -> float:
	if downed or dead:
		return 0.0
	var healed := profile.heal(amount)
	hp = profile.hp
	if healed > 0.5:
		Fx.burst(global_position + Vector3.UP, "twinkle", Pal.HEAL, Color("3aa04a"), 6, 0.8)
	return healed


func add_shield(amount: float, duration: float) -> void:
	profile.shield = maxf(profile.shield, amount)
	_shield_time = maxf(_shield_time, duration)
	_set_shield(1.0)


func _set_shield(v: float) -> void:
	if v > 0.0 and _shield_node == null:
		_shield_node = MeshInstance3D.new()
		_shield_node.mesh = SpellMeshes.sphere(18)
		var pal := Elem.palette("radiant")
		var m := ShaderMaterial.new()
		m.shader = preload("res://shaders/fx/energy.gdshader")
		m.set_shader_parameter("core_color", Color(1, 1, 1, 1))
		m.set_shader_parameter("main_color", Pal.GOLD_BRIGHT)
		m.set_shader_parameter("dark_color", pal.dark)
		m.set_shader_parameter("rim_color", Pal.GOLD_BRIGHT)
		m.set_shader_parameter("glow", 0.9)
		m.set_shader_parameter("dark_core", 1.0)
		_shield_node.material_override = m
		_shield_node.position = Vector3.UP * 0.8
		_shield_node.scale = Vector3.ONE * 1.05
		_shield_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_shield_node)
		_shield_node.set_instance_shader_parameter(&"fade", 0.3)
	elif v <= 0.0 and _shield_node:
		Fx.burst(global_position + Vector3.UP, "twinkle", Pal.GOLD_BRIGHT, Pal.GOLD, 10, 1.0)
		_shield_node.queue_free()
		_shield_node = null
		profile.shield = 0.0


func teleport_to(p: Vector3, invuln := 0.25) -> void:
	var to := Combat.flat(p)
	global_position = to
	iframes = maxf(iframes, invuln)
	squash(0.25, 0.25)


# --- downed / revive ------------------------------------------------------------------
func _go_down() -> void:
	downed = true
	hp = 0.0
	profile.hp = 0.0
	_cast_pending = -1.0
	_swing_pending = -1.0
	move_vel = Vector3.ZERO
	revive_progress = 0.0
	auto_revive_timer = 4.0
	_play("downed", 0.1)
	status.clear()
	if _flame:
		_flame.emitting = false
	if _flame_light:
		_flame_light.light_energy = 0.0
	Fx.burst(global_position + Vector3.UP * 1.6, "dust", Color(0.25, 0.22, 0.22, 0.8), Color(0.1, 0.1, 0.1, 0.0), 12, 1.2)
	Juice.shake(0.5)
	Juice.slowmo(0.4, 0.4, 0.3)
	Audio.play("downed", global_position, 0.0)
	input.rumble(0.8, 1.0, 0.4)
	Events.player_downed.emit(self)


func _downed_process(delta: float) -> void:
	velocity = knock
	move_and_slide()
	global_position.y = 0.0
	var reviver: Player = null
	for p in Combat.players:
		if p != self and not p.downed and Combat.flat_dist(p.global_position, global_position) <= REVIVE_RADIUS and p.input.is_held("interact"):
			reviver = p
			break
	if reviver:
		revive_progress += delta / REVIVE_TIME
		if Engine.get_physics_frames() % 6 == 0:
			Fx.burst(global_position + Vector3.UP * 1.4, "flame", reviver.profile.flame_color(), Pal.EMBER, 3, 0.6)
		if revive_progress >= 1.0:
			reviver.profile.revives_given += 1
			revive(0.4)
	else:
		revive_progress = maxf(0.0, revive_progress - delta * 0.5)
	if Game.run and Game.run.revive_stock > 0:
		auto_revive_timer -= delta
		if auto_revive_timer <= 0.0:
			Game.run.revive_stock -= 1
			revive(0.5)
	_ring.set_instance_shader_parameter(&"revive", revive_progress)


func revive(frac: float) -> void:
	if not downed:
		return
	downed = false
	hp = maxf(1.0, profile.stat("max_hp") * frac)
	profile.hp = hp
	iframes = 1.5
	revive_progress = 0.0
	_ring.set_instance_shader_parameter(&"revive", 0.0)
	_anim_lock = 0.6
	_play("revive", 0.05)
	if _flame:
		_flame.emitting = true
	Fx.ring(global_position, 3.0, profile.flame_color(), Pal.EMBER_HOT, 0.5, 0.12, 3.0)
	Fx.burst(global_position + Vector3.UP * 1.5, "flame", Pal.EMBER_HOT, profile.flame_color(), 24, 1.4)
	Fx.text_pop(global_position + Vector3.UP * 2.4, tr("FX_REKINDLED"), profile.flame_color().lerp(Color.WHITE, 0.3), 44)
	Audio.play("revive", global_position, 0.0)
	Events.player_revived.emit(self)


# --- interaction ----------------------------------------------------------------------
func _update_interact() -> void:
	var best: Node = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group("interactable"):
		if not is_instance_valid(n) or not n.can_interact(self):
			continue
		var d := Combat.flat_dist(n.global_position, global_position)
		if d <= float(n.get("interact_radius")) and d < best_d:
			best = n
			best_d = d
	_interact_target = best
	if best:
		_prompt.visible = true
		_prompt.text = "%s  %s" % [InputGlyphs.label(input, "interact"), best.interact_prompt()]
	else:
		_prompt.visible = false


# --- visual upkeep --------------------------------------------------------------------
func _update_visuals(delta: float) -> void:
	max_hp = profile.stat("max_hp")
	var r := hp_ratio()
	if _flame:
		_flame.speed_scale = lerpf(0.6, 1.1, r)
		_flame.amount_ratio = lerpf(0.35, 1.0, r)
		var flicker := 1.0 + sin(Time.get_ticks_msec() * 0.021) * 0.08 + sin(Time.get_ticks_msec() * 0.047) * 0.06
		_flame_light.light_energy = lerpf(0.5, 1.5, r) * flicker * (1.6 if living_ink > 0.0 else 1.0)
	var aim_ang := atan2(aim_dir.z, aim_dir.x)
	_ring.set_instance_shader_parameter(&"aim_angle", aim_ang)
	_ring.set_instance_shader_parameter(&"strength", 1.0 if Combat.players.size() > 1 or input.uses_mouse() else 0.7)
	_tag.visible = Combat.players.size() > 1
	# Hurt blink while invulnerable after a hit.
	if iframes > 0.0 and _dash_timer <= 0.0 and _dash_age > DASH_IFRAMES:
		pivot.visible = int(Time.get_ticks_msec() / 70.0) % 2 == 0
	else:
		pivot.visible = true


func _update_book(delta: float) -> void:
	if _book == null:
		return
	var side := Vector3(-facing.z, 0.0, facing.x)
	var t := Time.get_ticks_msec() / 1000.0
	var target := global_position + side * 0.75 - facing * 0.25 + Vector3.UP * (1.45 + sin(t * 2.2 + profile.index) * 0.08)
	if _cast_pending >= 0.0 or _anim_lock > 0.0 and _anim_current.begins_with("cast"):
		target = global_position + aim_dir * 0.9 + Vector3.UP * 1.3
	if downed:
		target = global_position + Vector3.UP * 0.35 + side * 0.5
	_book_pos = _book_pos.lerp(target, 1.0 - exp(-delta * 9.0))
	# Spine follows the knight's facing; the open pages tilt toward the camera.
	var yaw := atan2(facing.x, facing.z)
	var tilt := deg_to_rad(32.0 if not downed else 5.0)
	var want := Quaternion(Vector3.UP, yaw) * Quaternion(Vector3.RIGHT, tilt)
	_book_rot = _book_rot.slerp(want, 1.0 - exp(-delta * 8.0))
	_book.global_transform = Transform3D(Basis(_book_rot).scaled(Vector3.ONE * 0.9), _book_pos)

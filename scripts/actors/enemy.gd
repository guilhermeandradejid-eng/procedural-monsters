class_name Enemy
extends Actor
## Base for every erratum. Handles spawning out of an ink puddle, steering
## (seek + separation + wall feelers), animation, telegraphed attacks,
## hit reactions, dissolving death and loot. Subclasses implement _think().

const KINDS := {
	"blot": {"model": "res://assets/models/blot.glb", "hp": 22.0, "speed": 4.4, "radius": 0.45, "weight": 0.8, "damage": 7.0, "height": 0.8, "gold": [1, 3], "embers": 1, "cost": 1.0},
	"scribbler": {"model": "res://assets/models/scribbler.glb", "hp": 30.0, "speed": 3.4, "radius": 0.4, "weight": 0.9, "damage": 8.0, "height": 1.45, "gold": [2, 4], "embers": 2, "cost": 2.0},
	"brute": {"model": "res://assets/models/brute.glb", "hp": 105.0, "speed": 2.3, "radius": 0.8, "weight": 3.5, "damage": 16.0, "height": 2.0, "gold": [4, 7], "embers": 4, "cost": 4.0},
	"moth": {"model": "res://assets/models/moth.glb", "hp": 16.0, "speed": 5.8, "radius": 0.45, "weight": 0.5, "damage": 7.0, "height": 1.3, "gold": [1, 2], "embers": 1, "cost": 1.5},
	"inkpot": {"model": "res://assets/models/inkpot.glb", "hp": 42.0, "speed": 0.0, "radius": 0.5, "weight": 99.0, "damage": 10.0, "height": 1.0, "gold": [2, 5], "embers": 2, "cost": 2.5},
	"binder": {"model": "res://assets/models/binder.glb", "hp": 1400.0, "speed": 2.0, "radius": 1.5, "weight": 50.0, "damage": 20.0, "height": 3.3, "gold": [60, 80], "embers": 40, "cost": 99.0},
}

const SCRIPTS := {
	"blot": preload("res://scripts/actors/enemies/blot.gd"),
	"scribbler": preload("res://scripts/actors/enemies/scribbler.gd"),
	"brute": preload("res://scripts/actors/enemies/brute.gd"),
	"moth": preload("res://scripts/actors/enemies/moth.gd"),
	"inkpot": preload("res://scripts/actors/enemies/inkpot.gd"),
	"binder": preload("res://scripts/actors/enemies/binder.gd"),
}

var kind := "blot"
var data: Dictionary = {}
var elite := false
var active := false
var damage := 7.0
var speed := 4.0
var height := 1.0
var target: Node3D = null
var desired := Vector3.ZERO
var face_dir := Vector3(0, 0, 1)
var model: Node3D
var anim: AnimationPlayer
var rig: ProceduralRig
var _anim_name := ""
var _anim_lock := 0.0
var _think_timer := 0.0
var _feel_timer := 0.0
var _wall_push := Vector3.ZERO


static func create(p_kind: String, p_elite := false) -> Enemy:
	var e: Enemy = SCRIPTS[p_kind].new()
	e.kind = p_kind
	e.elite = p_elite
	return e


func _ready() -> void:
	super._ready()
	data = KINDS[kind]
	var diff := Game.run.difficulty() if Game.run else 0.0
	var players := maxi(1, Combat.players.size())
	max_hp = float(data.hp) * (1.0 + diff * 1.3) * (1.0 + 0.4 * (players - 1)) * (2.2 if elite else 1.0)
	hp = max_hp
	damage = float(data.damage) * (1.0 + diff * 0.6) * (1.25 if elite else 1.0)
	speed = float(data.speed)
	radius = float(data.radius) * (1.15 if elite else 1.0)
	weight = float(data.weight) * (1.5 if elite else 1.0)
	height = float(data.height)
	is_boss = kind == "binder"
	collision_layer = Combat.LAYER_ENEMIES
	collision_mask = Combat.LAYER_WORLD
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius * 0.8
	cyl.height = height
	shape.shape = cyl
	shape.position = Vector3.UP * height * 0.5
	add_child(shape)
	model = Toon.spawn(data.model)
	pivot.add_child(model)
	if elite:
		pivot.scale = Vector3.ONE * 1.15
		_elite_aura()
	anim = Toon.find_anim_player(model)
	var skel := Toon.find_skeleton(model)
	if skel and kind in ["brute", "binder", "scribbler"]:
		rig = ProceduralRig.new()
		rig.lean_bone = "chest" if kind == "brute" else ("spine" if kind == "binder" else "body")
		skel.add_child(rig)
	for n in ["idle", "move"]:
		if anim and anim.has_animation(n):
			anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	collect_geometry()
	Combat.register_enemy(self)
	face_dir = Vector3(randf_range(-1, 1), 0, 1).normalized()
	pivot.rotation.y = atan2(face_dir.x, face_dir.z)
	_spawn_in()
	_setup()


## Override to initialise per-kind state.
func _setup() -> void:
	pass


func _exit_tree() -> void:
	Combat.unregister_enemy(self)


func _elite_aura() -> void:
	set_shader_instance(&"tint", Color(1.0, 0.8, 0.35, 0.18))
	var em := Fx.emitter(self, "twinkle", Pal.GOLD_BRIGHT, Pal.EMBER, 8, 1.0)
	em.position = Vector3.UP * height * 0.6


func _spawn_in() -> void:
	active = false
	Fx.splat(global_position, radius * 2.2, Pal.INK)
	Fx.burst(global_position + Vector3.UP * 0.2, "ink", Pal.INK, Pal.INK_SOFT, 12, 1.0)
	pivot.scale = Vector3(1.4, 0.05, 1.4) * (1.15 if elite else 1.0)
	var t := create_tween()
	t.tween_property(pivot, "scale", Vector3(0.8, 1.25, 0.8) * (1.15 if elite else 1.0), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(pivot, "scale", Vector3.ONE * (1.15 if elite else 1.0), 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	t.tween_callback(func(): active = true)
	play("idle")
	Audio.play("spawn", global_position, -10.0, randf_range(0.9, 1.1))
	Events.enemy_spawned.emit(self)


func targetable() -> bool:
	return not dead and active


func play(n: String, blend := 0.15, spd := 1.0) -> void:
	if anim == null or not anim.has_animation(n):
		return
	if _anim_name == n and anim.is_playing() and n in ["idle", "move"]:
		anim.speed_scale = spd
		return
	_anim_name = n
	anim.play(n, blend)
	anim.speed_scale = spd


func lock_anim(n: String, duration: float, blend := 0.1, spd := 1.0) -> void:
	play(n, blend, spd)
	_anim_lock = duration


func _physics_process(delta: float) -> void:
	if dead:
		return
	tick_actor(delta)
	if rig:
		rig.velocity = Combat.flat(velocity)
		rig.facing_yaw = pivot.rotation.y
	if dead or not active:
		return
	_anim_lock = maxf(0.0, _anim_lock - delta)
	if anim:
		anim.speed_scale = 0.0 if status.frozen() else (0.5 if status.chill_stacks > 0 else 1.0)
	if not is_instance_valid(target) or target.downed:
		target = Combat.nearest_player(global_position)
	desired = Vector3.ZERO
	if not stunned():
		_think(delta)
	_steer(delta)


## Override: set `desired` (velocity) and trigger attacks.
func _think(_delta: float) -> void:
	pass


func _steer(delta: float) -> void:
	var v := desired * status.speed_mult()
	# Separation from other errata.
	var sep := Vector3.ZERO
	for o in Combat.enemies:
		if o == self or not is_instance_valid(o):
			continue
		var to := Combat.flat(global_position - o.global_position)
		var d := to.length()
		var min_d: float = radius + o.radius
		if d < min_d and d > 0.001:
			sep += to / d * (min_d - d) * 6.0
	# Wall feelers every few frames.
	_feel_timer -= delta
	if _feel_timer <= 0.0 and v.length() > 0.1:
		_feel_timer = 0.15
		_wall_push = Vector3.ZERO
		var fwd := v.normalized()
		for a in [-0.6, 0.0, 0.6]:
			var d := fwd.rotated(Vector3.UP, a)
			var hit := Combat.ray(get_world_3d(), global_position + Vector3.UP * 0.5, global_position + Vector3.UP * 0.5 + d * (radius + 1.2))
			if not hit.is_empty():
				_wall_push += Combat.flat(hit.normal) * 2.5 - d * 1.5
	velocity = v + sep + _wall_push * v.length() * 0.4 + knock
	velocity.y = 0.0
	move_and_slide()
	global_position.y = 0.0
	if v.length() > 0.2:
		face(v.normalized(), delta)


func face(dir: Vector3, delta: float, rate := 10.0) -> void:
	var d := Combat.flat(dir)
	if d.length() < 0.01:
		return
	face_dir = face_dir.slerp(d.normalized(), 1.0 - exp(-delta * rate)).normalized()
	pivot.rotation.y = atan2(face_dir.x, face_dir.z)
	if rig:
		rig.want_yaw = atan2(d.x, d.z)


func dir_to_target() -> Vector3:
	if target == null:
		return face_dir
	var d := Combat.flat(target.global_position - global_position)
	return d.normalized() if d.length() > 0.01 else face_dir


func dist_to_target() -> float:
	return INF if target == null else Combat.flat_dist(target.global_position, global_position)


# --- attacks --------------------------------------------------------------------------
func _enemy_hit(amount: float, pos: Vector3, knock_dir: Vector3, knock_force: float) -> Hit:
	var h := Hit.make(amount, self, pos, "enemy")
	h.knockback = Combat.flat(knock_dir).normalized() * knock_force
	return h


func attack_circle(center: Vector3, r: float, amount: float, knock_force := 5.0) -> int:
	var n := 0
	for p in Combat.players_near(center, r):
		p.take_hit(_enemy_hit(amount, p.global_position, p.global_position - center, knock_force))
		n += 1
	return n


func attack_cone(origin: Vector3, dir: Vector3, r: float, half_angle: float, amount: float, knock_force := 5.0) -> int:
	var n := 0
	for p in Combat.players_near(origin, r):
		var to := Combat.flat(p.global_position - origin)
		if to.length() > 0.3 and dir.angle_to(to.normalized()) > half_angle:
			continue
		p.take_hit(_enemy_hit(amount, p.global_position, to, knock_force))
		n += 1
	return n


func attack_line(a: Vector3, b: Vector3, width: float, amount: float, knock_force := 5.0) -> int:
	var n := 0
	for p in Combat.players_on_segment(a, b, width):
		p.take_hit(_enemy_hit(amount, p.global_position, b - a, knock_force))
		n += 1
	return n


# --- damage and death -----------------------------------------------------------------
func _damage_taken_mult(hit: Hit) -> float:
	var m := 1.0
	if kind == "brute" and Elem.has_part(hit.element, "ember"):
		m *= 1.5
	return m


func _on_damaged(hit: Hit) -> void:
	if hit.kind == "dot":
		return
	if _anim_lock <= 0.0 and not is_boss and hit.dealt > max_hp * 0.08:
		lock_anim("hit", 0.18, 0.05)
	Audio.play("hurt_%s" % ("big" if weight > 2.0 else "small"), global_position, -8.0, randf_range(0.9, 1.15), 0.1, 40)


func _on_died(hit: Hit) -> void:
	active = false
	Combat.unregister_enemy(self)
	collision_layer = 0
	set_physics_process(false)
	Elements.on_death(self)
	Events.enemy_killed.emit(self, hit)
	if Game.run:
		Game.run.kills += 1
	play("death", 0.05)
	_drop_loot()
	var ink := Pal.INK
	Fx.splat(global_position, radius * 2.6 + 0.4, ink)
	Fx.burst(global_position + Vector3.UP * height * 0.5, "ink", ink, Pal.INK_SOFT, 18, 1.2)
	Fx.burst(global_position + Vector3.UP * height * 0.5, "paper", Pal.PAPER, Pal.PAPER_DARK, 6, 1.0)
	Audio.play("die_%s" % ("big" if weight > 2.0 else "small"), global_position, -3.0, randf_range(0.9, 1.1))
	Juice.shake(0.12 if not is_boss else 0.8)
	var t := create_tween()
	t.tween_interval(0.35)
	t.tween_method(func(v: float): set_shader_instance(&"dissolve", v), 0.0, 1.0, 0.7)
	t.tween_callback(queue_free)


func _drop_loot() -> void:
	var g: Array = data.gold
	var gold := randi_range(int(g[0]), int(g[1])) * (3 if elite else 1)
	var embers := int(data.embers) * (2 if elite else 1)
	Pickup.scatter(global_position, "gold", gold)
	if randf() < 0.55 or elite or is_boss:
		Pickup.scatter(global_position, "ember", embers)
	if randf() < 0.04 and not is_boss:
		Pickup.scatter(global_position, "heart", 1)


# --- shared helpers for telegraphed windups -------------------------------------------
func telegraph_circle(center: Vector3, r: float, t: float) -> void:
	Fx.telegraph(center, 0, Vector2(r, r), t)


func telegraph_cone(origin: Vector3, dir: Vector3, r: float, half_angle: float, t: float) -> void:
	Fx.telegraph(origin, 1, Vector2(r, r), t, dir, half_angle)


func telegraph_line(origin: Vector3, dir: Vector3, length: float, width: float, t: float) -> void:
	Fx.telegraph(origin, 2, Vector2(width, length * 0.5), t, dir)

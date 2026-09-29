class_name ProceduralRig
extends SkeletonModifier3D
## Runtime secondary motion layered over the baked clips. The clips already carry
## overlap and springs authored in Blender; this adds what only the game knows:
##  - follow-through: cape and helm flame swing against the knight's real
##    acceleration and turns (damped springs, so they overshoot and settle)
##  - weight: the torso leans into acceleration and banks into turns
##  - anticipation: the head turns toward the new heading before the body does
## Everything is computed in model space (the model faces +Z, +X is its left).

## Set by the owner every physics frame.
var velocity := Vector3.ZERO
## Current yaw of the model's pivot and the yaw it is turning toward (radians).
var facing_yaw := 0.0
var want_yaw := 0.0
## 0..1, scales everything (e.g. 0 while downed).
var amount := 1.0

@export var cape_bone := "cape"
@export var flame_bone := "flame"
@export var head_bone := "head"
@export var lean_bone := "spine"

var _idx := {}
var _prev_vel := Vector3.ZERO
var _prev_yaw := 0.0
var _yaw_rate := 0.0
var _acc := Vector3.ZERO
var _cape := Vector2.ZERO
var _cape_v := Vector2.ZERO
var _flame := Vector2.ZERO
var _flame_v := Vector2.ZERO
var _lean := Vector2.ZERO
var _head := 0.0


func _resolve(sk: Skeleton3D) -> void:
	for key in [cape_bone, flame_bone, head_bone, lean_bone]:
		_idx[key] = sk.find_bone(key)


static func _spring(x: Vector2, v: Vector2, target: Vector2, freq: float, zeta: float, dt: float) -> Array:
	var w := TAU * freq
	var steps := 2
	var h := dt / steps
	for i in steps:
		var a := (target - x) * w * w - v * 2.0 * zeta * w
		v += a * h
		x += v * h
	return [x, v]


func _process_modification_with_delta(delta: float) -> void:
	var sk := get_skeleton()
	if sk == null or delta <= 0.0:
		return
	if _idx.is_empty():
		_resolve(sk)
	var dt := minf(delta, 0.05)
	# Smoothed acceleration and turn rate (raw finite differences are noisy).
	var raw_acc := (velocity - _prev_vel) / dt
	_prev_vel = velocity
	_acc = _acc.lerp(raw_acc, 1.0 - exp(-dt * 18.0))
	var raw_rate := wrapf(facing_yaw - _prev_yaw, -PI, PI) / dt
	_prev_yaw = facing_yaw
	_yaw_rate = lerpf(_yaw_rate, raw_rate, 1.0 - exp(-dt * 14.0))
	var to_local := Basis(Vector3.UP, facing_yaw).inverse()
	var lacc := to_local * _acc
	var lvel := to_local * velocity
	var speed := Vector2(lvel.x, lvel.z).length()

	# Lean into acceleration (pitch) and bank into turns (roll), degrees.
	var lean_target := Vector2(
		clampf(lacc.z * 0.55 + speed * 0.6, -8.0, 12.0),
		clampf(-_yaw_rate * 2.2 - lacc.x * 0.35, -10.0, 10.0))
	_lean = _lean.lerp(lean_target * amount, 1.0 - exp(-dt * 10.0))
	# Cape: dragged back by speed and acceleration, flung outward on turns.
	var cape_target := Vector2(
		clampf(speed * 2.6 + lacc.z * 0.9, -20.0, 55.0),
		clampf(-_yaw_rate * 9.0 + lacc.x * 0.8, -40.0, 40.0)) * amount
	var r := _spring(_cape, _cape_v, cape_target, 2.4, 0.32, dt)
	_cape = r[0]
	_cape_v = r[1]
	# Flame: a light, lively trail (higher frequency, less damping).
	var flame_target := Vector2(
		clampf(-(speed * 3.2 + lacc.z * 1.1), -50.0, 20.0),
		clampf(_yaw_rate * 10.0 - lacc.x * 1.0, -45.0, 45.0)) * amount
	r = _spring(_flame, _flame_v, flame_target, 3.4, 0.22, dt)
	_flame = r[0]
	_flame_v = r[1]
	# Eyes lead the turn.
	var head_target := clampf(wrapf(want_yaw - facing_yaw, -PI, PI), -0.6, 0.6) * 0.75 * amount
	_head = lerpf(_head, head_target, 1.0 - exp(-dt * 20.0))

	_rotate_global(sk, lean_bone, Basis(Vector3.RIGHT, deg_to_rad(_lean.x)) * Basis(Vector3.BACK, deg_to_rad(_lean.y)))
	_rotate_global(sk, head_bone, Basis(Vector3.UP, _head))
	_rotate_global(sk, cape_bone, Basis(Vector3.BACK, deg_to_rad(_cape.y)) * Basis(Vector3.RIGHT, deg_to_rad(_cape.x)))
	_rotate_global(sk, flame_bone, Basis(Vector3.BACK, deg_to_rad(_flame.y)) * Basis(Vector3.RIGHT, deg_to_rad(_flame.x)))


## Rotates a bone about its own head by a model-space rotation.
func _rotate_global(sk: Skeleton3D, bone: String, rot: Basis) -> void:
	var i: int = _idx.get(bone, -1)
	if i < 0:
		return
	var g := sk.get_bone_global_pose(i)
	sk.set_bone_global_pose(i, Transform3D(rot * g.basis, g.origin))

class_name CameraRig
extends Node3D
## Shared co-op camera: frames every living knight, zooms out as they spread,
## shakes with trauma (Perlin noise, squared falloff) and punches the FOV.

@export var pitch_deg := 56.0
@export var fov := 32.0
@export var min_dist := 17.5
@export var max_dist := 33.0
@export var follow_speed := 4.5

var camera: Camera3D
var focus := Vector3.ZERO
var dist := 22.0
var trauma := 0.0
var shake_dir := Vector3.ZERO
var extra_targets: Array[Node3D] = []
## Optional world-space clamp for the focus point.
var focus_bounds := Rect2()
var _noise := FastNoiseLite.new()
var _noise_t := 0.0
var _punch := 0.0
var _punch_t := 0.0
var _punch_dur := 0.2


func _ready() -> void:
	camera = Camera3D.new()
	camera.fov = fov
	camera.near = 0.5
	camera.far = 200.0
	add_child(camera)
	camera.make_current()
	_noise.seed = randi()
	_noise.frequency = 2.2
	Juice.trauma_added.connect(_on_trauma)
	Juice.zoom_punch.connect(_on_punch)
	snap()


func _on_trauma(amount: float, direction: Vector3) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)
	if direction != Vector3.ZERO:
		shake_dir = direction.normalized()


func _on_punch(amount: float, duration: float) -> void:
	_punch = maxf(_punch, amount)
	_punch_t = 0.0
	_punch_dur = duration


func _targets() -> Array[Node3D]:
	var out: Array[Node3D] = []
	for p in Combat.players:
		if is_instance_valid(p) and p.is_inside_tree() and not p.downed:
			out.append(p)
	if out.is_empty():
		for p in Combat.players:
			if is_instance_valid(p) and p.is_inside_tree():
				out.append(p)
	for t in extra_targets:
		if is_instance_valid(t):
			out.append(t)
	return out


func _desired() -> Array:
	var ts := _targets()
	if ts.is_empty():
		return [focus, dist]
	var mn := Vector2(INF, INF)
	var mx := Vector2(-INF, -INF)
	var c := Vector3.ZERO
	for t in ts:
		var p := t.global_position
		c += p
		mn = mn.min(Vector2(p.x, p.z))
		mx = mx.max(Vector2(p.x, p.z))
	c /= ts.size()
	c.y = 0.0
	var spread := mx - mn
	# Horizontal spread needs less distance than vertical because of the aspect ratio.
	var need := maxf(spread.x * 0.62, spread.y * 1.05) + min_dist * 0.72
	var d := clampf(need, min_dist, max_dist)
	var f := Vector3((mn.x + mx.x) * 0.5, 0.0, (mn.y + mx.y) * 0.5).lerp(c, 0.35)
	if focus_bounds.size != Vector2.ZERO:
		f.x = clampf(f.x, focus_bounds.position.x, focus_bounds.end.x)
		f.z = clampf(f.z, focus_bounds.position.y, focus_bounds.end.y)
	return [f, d]


func snap() -> void:
	var d := _desired()
	focus = d[0]
	dist = d[1]
	_apply(0.0)


func _process(delta: float) -> void:
	var real_dt := delta / maxf(Engine.time_scale, 0.001)
	var d := _desired()
	focus = focus.lerp(d[0], 1.0 - exp(-real_dt * follow_speed))
	dist = lerpf(dist, d[1], 1.0 - exp(-real_dt * 2.5))
	trauma = maxf(0.0, trauma - real_dt * 1.5)
	_noise_t += real_dt
	_punch_t += real_dt
	_apply(real_dt)


func _apply(_dt: float) -> void:
	var pitch := deg_to_rad(pitch_deg)
	var offset := Vector3(0.0, sin(pitch), cos(pitch)) * dist
	var shake := trauma * trauma
	var jitter := Vector3(
		_noise.get_noise_2d(_noise_t * 60.0, 0.0),
		_noise.get_noise_2d(0.0, _noise_t * 60.0) * 0.6,
		_noise.get_noise_2d(_noise_t * 60.0, 100.0)) * shake * 0.9
	jitter += shake_dir * shake * 0.35 * sin(_noise_t * 70.0)
	var roll := _noise.get_noise_2d(200.0, _noise_t * 60.0) * shake * 0.035
	var eye := focus + offset + jitter
	camera.global_transform = Transform3D(Basis(), eye).looking_at(focus + jitter * 0.5, Vector3.UP)
	camera.rotate_object_local(Vector3.FORWARD, roll)
	var k := clampf(_punch_t / maxf(_punch_dur, 0.01), 0.0, 1.0)
	var punch_now := _punch * (1.0 - k) * (1.0 - k)
	camera.fov = fov * (1.0 - punch_now)
	if k >= 1.0:
		_punch = 0.0


## Ground-plane rectangle currently visible (for the co-op leash).
func visible_ground_rect(margin := 1.2) -> Rect2:
	var vp := get_viewport()
	if vp == null or camera == null:
		return Rect2(-100, -100, 200, 200)
	var size := vp.get_visible_rect().size
	var pts: Array[Vector2] = []
	for sp in [Vector2(0, 0), Vector2(size.x, 0), Vector2(0, size.y), Vector2(size.x, size.y)]:
		var o := camera.project_ray_origin(sp)
		var n := camera.project_ray_normal(sp)
		if absf(n.y) < 0.0001:
			continue
		var t := -o.y / n.y
		var p := o + n * t
		pts.append(Vector2(p.x, p.z))
	if pts.is_empty():
		return Rect2(-100, -100, 200, 200)
	var mn := pts[0]
	var mx := pts[0]
	for p in pts:
		mn = mn.min(p)
		mx = mx.max(p)
	# Top edge is farther (perspective); use the narrower bottom width for safety.
	return Rect2(mn + Vector2(margin, margin), (mx - mn) - Vector2(margin, margin) * 2.0)


## Where the camera WOULD see at maximum zoom-out around the current focus.
func leash_rect(margin := 1.0) -> Rect2:
	var pitch := deg_to_rad(pitch_deg)
	var half_v := max_dist * tan(deg_to_rad(fov) * 0.5) / sin(pitch)
	var aspect := 16.0 / 9.0
	var vp := get_viewport()
	if vp:
		var s := vp.get_visible_rect().size
		aspect = s.x / maxf(s.y, 1.0)
	var half_h := max_dist * tan(deg_to_rad(fov) * 0.5) * aspect
	return Rect2(focus.x - half_h + margin, focus.z - half_v + margin, (half_h - margin) * 2.0, (half_v - margin) * 2.0)


func mouse_ground(screen: Vector2, height := 0.0) -> Vector3:
	if camera == null:
		return Vector3.ZERO
	var o := camera.project_ray_origin(screen)
	var n := camera.project_ray_normal(screen)
	if absf(n.y) < 0.0001:
		return Vector3(o.x, height, o.z)
	var t := (height - o.y) / n.y
	return o + n * t

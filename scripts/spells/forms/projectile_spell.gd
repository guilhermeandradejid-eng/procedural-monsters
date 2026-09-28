extends SpellEntity
## Bolt, Orb, Wave and Chakram: things that fly.

const FLY_HEIGHT := 0.9

var velocity := Vector3.ZERO
var pierce_left := 0
var bounce_left := 0
var spiral_wisp := false
var _center := Vector3.ZERO
var _returning := false
var _travelled := 0.0
var _hit_cd := INF


func _on_spawn() -> void:
	position = Vector3(origin.x, FLY_HEIGHT, origin.z)
	_center = position
	match form:
		"bolt":
			pierce_left = 0
		"orb":
			pierce_left = 9999
			_hit_cd = 0.3
		"wave":
			pierce_left = 9999
		"chakram":
			pierce_left = 9999
			_hit_cd = 0.3
			life = 2.6
	pierce_left += 2 * clause.mod("pierce")
	bounce_left = 2 * clause.mod("bounce")
	if spiral_wisp:
		life = 0.7
	velocity = dir * speed()
	_face(dir)


func _face(d: Vector3) -> void:
	if d.length() > 0.01:
		look_at(global_position + d, Vector3.UP)


func _tick(delta: float) -> void:
	if form == "chakram":
		_chakram_motion(delta)
	else:
		_steer(delta)
	var from := _center
	_center += velocity * delta
	_travelled += velocity.length() * delta
	var pos := _center
	if clause.has_mod("spiral") and not spiral_wisp:
		var side := Vector3(-dir.z, 0.0, dir.x)
		var s := age * 11.0
		pos += side * sin(s) * 0.9 * clause.mod("spiral") + Vector3.UP * cos(s) * 0.35
	global_position = pos
	if velocity.length() > 0.1:
		_face(velocity.normalized())
	# Walls.
	var hit := Combat.ray(get_world_3d(), from, _center + velocity.normalized() * radius * 0.5)
	if not hit.is_empty():
		if bounce_left > 0:
			bounce_left -= 1
			var n: Vector3 = Combat.flat(hit.normal).normalized()
			velocity = velocity.bounce(n) if n.length() > 0.1 else -velocity
			dir = Combat.flat(velocity).normalized()
			_center = hit.position + n * 0.1
			_center.y = FLY_HEIGHT
			SpellFx.ricochet(self, hit.position)
		elif form != "chakram" or not _returning:
			finish(hit.position)
			return
	_hit_targets()
	if finished:
		return
	if form == "chakram":
		return
	if age >= life:
		finish()


func _steer(delta: float) -> void:
	if spiral_wisp:
		velocity = velocity.rotated(Vector3.UP, 3.2 * delta)
		dir = velocity.normalized()
		return
	var seeks := clause.mod("seek")
	if form == "serpent":
		seeks += 1
	if seeks <= 0:
		return
	var tgt := cast.target_in_cone(_center, dir, 10.0, 0.2, exclude)
	if tgt == null:
		return
	var want := Combat.flat(tgt.global_position - _center).normalized()
	var cur := Combat.flat(velocity).normalized()
	var ang := cur.signed_angle_to(want, Vector3.UP)
	var turn := clampf(ang, -3.6 * seeks * delta, 3.6 * seeks * delta)
	velocity = velocity.rotated(Vector3.UP, turn)
	dir = Combat.flat(velocity).normalized()


func _chakram_motion(delta: float) -> void:
	var max_range: float = float(fdef.get("range", 8.0)) * pow(1.2, clause.mod("grow"))
	var spd := speed()
	if not _returning:
		var t := clampf(_travelled / max_range, 0.0, 1.0)
		velocity = dir * spd * lerpf(1.0, 0.25, t * t)
		if _travelled >= max_range:
			_returning = true
	else:
		var home := _center
		if cast.caster_alive():
			home = cast.caster.global_position
		home.y = FLY_HEIGHT
		var to := home - _center
		if to.length() < 0.9 or age > life:
			finish()
			return
		velocity = velocity.lerp(to.normalized() * spd * 1.15, 1.0 - exp(-delta * 7.0))
	rotate_y(delta * 20.0)


func _hit_targets() -> void:
	var r := radius
	if form == "wave":
		r = radius * lerpf(0.7, 1.9, clampf(age / maxf(life, 0.01), 0.0, 1.0))
	var ground := Vector3(_center.x, 0.0, _center.z)
	for t in cast.targets_near(ground, r):
		if not can_hit(t, _hit_cd):
			continue
		var mult := 1.0
		var kd := Combat.flat(velocity).normalized()
		if form == "wave":
			# Waves only hit what is in front of their arc.
			var to := Combat.flat(t.global_position - ground)
			if to.length() > 0.3 and to.normalized().dot(kd) < -0.2:
				continue
		deal(t, mult, kd)
		if finished:
			return
		if pierce_left <= 0:
			if bounce_left > 0:
				bounce_left -= 1
				var nxt := cast.nearest_target(ground, 9.0, [t])
				if nxt:
					dir = Combat.flat(nxt.global_position - ground).normalized()
					velocity = dir * speed()
					exclude = [t]
					continue
			finish(Vector3(_center.x, 0.0, _center.z))
			return
		pierce_left -= 1

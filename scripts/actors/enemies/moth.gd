extends Enemy
## Paper Moth: circles its prey, then dives in a straight, telegraphed line.

const ORBIT := 4.6
const DIVE_SPEED := 15.0

var state := "orbit"
var timer := 0.0
var cooldown := 2.0
var spin := 1.0
var dive_dir := Vector3.ZERO
var _hit_done := false


func _setup() -> void:
	spin = 1.0 if randf() < 0.5 else -1.0
	cooldown = randf_range(1.5, 3.0)
	play("move")


func _think(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	match state:
		"orbit":
			if target == null:
				play("idle")
				return
			var to := Combat.flat(target.global_position - global_position)
			var d := to.length()
			var tangent := Vector3(-to.z, 0.0, to.x).normalized() * spin
			var radial := to.normalized() * clampf((d - ORBIT) * 0.8, -1.0, 1.0)
			desired = (tangent + radial).normalized() * speed * (0.8 + 0.2 * sin(Time.get_ticks_msec() * 0.004))
			play("move")
			if cooldown <= 0.0 and d < 9.0:
				state = "windup"
				timer = 0.7
				dive_dir = to.normalized()
				lock_anim("attack", 1.32, 0.08)
				telegraph_line(global_position, dive_dir, 9.5, 0.7, 0.7)
				Audio.play("moth_screech", global_position, -6.0, randf_range(0.95, 1.1))
		"windup":
			timer -= delta
			desired = -dive_dir * 1.2
			face(dive_dir, delta, 12.0)
			if timer <= 0.0:
				state = "dive"
				timer = 0.62
				_hit_done = false
		"dive":
			timer -= delta
			desired = dive_dir * DIVE_SPEED
			face(dive_dir, delta, 20.0)
			if not _hit_done and attack_circle(global_position, 0.75 + radius, damage, 5.0) > 0:
				_hit_done = true
			if Engine.get_physics_frames() % 3 == 0:
				Fx.burst(global_position + Vector3.UP * 1.1, "paper", Pal.PAPER, Pal.PAPER_DARK, 2, 0.6)
			if timer <= 0.0:
				state = "recover"
				timer = 0.7
		"recover":
			timer -= delta
			desired = Vector3.ZERO
			if timer <= 0.0:
				state = "orbit"
				cooldown = randf_range(2.6, 4.0) * (0.7 if elite else 1.0)
				spin = -spin if randf() < 0.5 else spin

extends Enemy
## Blot: an ink slime that hops toward knights and lunges with a bite.

const HOP := 0.46
const WINDUP := 0.4

var state := "chase"
var timer := 0.0
var hop_t := 0.0
var cooldown := 0.0
var lunge_dir := Vector3.ZERO
var _bit := false


func _setup() -> void:
	hop_t = randf() * HOP
	play("move")


func _think(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	match state:
		"chase":
			if target == null:
				play("idle")
				return
			hop_t += delta
			var phase := fmod(hop_t, HOP)
			var airborne := phase > 0.07 and phase < 0.4
			desired = dir_to_target() * speed * (1.7 if airborne else 0.12)
			play("move", 0.1)
			if dist_to_target() < 1.9 + radius and cooldown <= 0.0:
				state = "windup"
				timer = WINDUP
				lunge_dir = dir_to_target()
				lock_anim("attack", 0.8, 0.05)
				telegraph_cone(global_position, lunge_dir, 2.3, deg_to_rad(38.0), WINDUP)
		"windup":
			timer -= delta
			face(dir_to_target(), delta, 6.0)
			lunge_dir = face_dir
			if timer <= 0.0:
				state = "lunge"
				timer = 0.18
				_bit = false
				Audio.play("bite", global_position, -6.0, randf_range(0.9, 1.1))
		"lunge":
			timer -= delta
			desired = lunge_dir * 11.0
			if not _bit and timer < 0.12:
				_bit = true
				attack_cone(global_position, lunge_dir, 1.4 + radius, deg_to_rad(50.0), damage, 6.0)
			if timer <= 0.0:
				state = "recover"
				timer = 0.55
		"recover":
			timer -= delta
			desired = -lunge_dir * 0.6
			if timer <= 0.0:
				state = "chase"
				cooldown = 0.6

extends Enemy
## Wax Brute: a melting candle golem. Slow, heavy, and its slam hurts.
## Fire makes it melt (takes +50% damage from Ember).

const SLAM_AT := 0.8
const SLAM_RADIUS := 2.6

var state := "chase"
var timer := 0.0
var cooldown := 1.0
var slam_center := Vector3.ZERO
var _slammed := false
var _flame: GPUParticles3D


func _setup() -> void:
	play("move")
	var skel := Toon.find_skeleton(model)
	if skel:
		var att := BoneAttachment3D.new()
		att.bone_name = "flame"
		skel.add_child(att)
		_flame = Fx.emitter(att, "flame", Pal.EMBER_HOT, Pal.EMBER, 16, 1.0)
		var l := OmniLight3D.new()
		l.light_color = Pal.EMBER
		l.light_energy = 1.2
		l.omni_range = 4.0
		att.add_child(l)


func _think(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	match state:
		"chase":
			if target == null:
				play("idle")
				return
			desired = dir_to_target() * speed
			play("move", 0.2, 1.0)
			if dist_to_target() < 3.2 + radius and cooldown <= 0.0:
				state = "slam"
				timer = 0.0
				_slammed = false
				slam_center = global_position + dir_to_target() * 1.7
				lock_anim("slam", 1.45, 0.1)
				telegraph_circle(slam_center, SLAM_RADIUS, SLAM_AT)
				Audio.play("brute_windup", global_position, -4.0)
		"slam":
			timer += delta
			if timer < SLAM_AT * 0.7:
				face(Combat.flat(slam_center - global_position), delta, 4.0)
			if not _slammed and timer >= SLAM_AT:
				_slammed = true
				attack_circle(slam_center, SLAM_RADIUS, damage, 9.0)
				Fx.ring(slam_center, SLAM_RADIUS * 1.1, Pal.WAX_LIGHT, Pal.PAPER_LIGHT, 0.4, 0.2, 2.0)
				Fx.burst(slam_center, "dust", Pal.PAPER_DARK, Color(Pal.PAPER_SHADOW, 0.0), 14, 1.6)
				Fx.burst(slam_center + Vector3.UP * 0.3, "paper", Pal.PAPER, Pal.PAPER_DARK, 10, 1.2)
				Fx.splat(slam_center, 1.2, Color("c9a878"))
				Juice.shake(0.45)
				Audio.play("slam", slam_center, 0.0)
			if timer >= 1.45:
				state = "chase"
				cooldown = 1.3

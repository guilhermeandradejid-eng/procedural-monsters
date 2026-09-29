extends Enemy
## Inkpot: a rooted mortar that lobs ink bombs. The splash leaves puddles
## that slow knights down.

const FLIGHT := 1.05

var fire_timer := 2.0


func _setup() -> void:
	fire_timer = randf_range(1.0, 2.4)
	play("idle")


func _think(delta: float) -> void:
	desired = Vector3.ZERO
	if target == null:
		return
	face(dir_to_target(), delta, 4.0)
	fire_timer -= delta
	if fire_timer <= 0.0 and dist_to_target() < 16.0:
		fire_timer = randf_range(2.4, 3.2) * (0.7 if elite else 1.0)
		_fire(target.global_position + Combat.flat(target.velocity) * 0.35)
		if elite:
			var off := Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
			get_tree().create_timer(0.25, false).timeout.connect(func():
				if is_instance_valid(self) and not dead and target:
					_fire(target.global_position + off))


## The pot squashes down (anticipation) and the bomb leaves on the pop, 0.3 s in.
const POP := 0.3


func _fire(at: Vector3) -> void:
	lock_anim("attack", 0.7, 0.05)
	var landing := Combat.flat(at)
	telegraph_circle(landing, 1.7, FLIGHT + POP)
	get_tree().create_timer(POP, false).timeout.connect(func():
		if not is_instance_valid(self) or dead or Level.current == null:
			return
		var shot := EnemyShot.lob(self, global_position + Vector3.UP * 1.0, landing, FLIGHT, damage, 1.7)
		shot.on_land = func(p: Vector3):
			InkPuddle.spawn(p, 1.8, 4.0)
		Level.current.add_spell(shot)
		Audio.play("lob", global_position, -6.0))

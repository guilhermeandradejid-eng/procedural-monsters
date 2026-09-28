extends Enemy
## Scribbler: a paper wraith that keeps its distance and casts spells written
## with the very same grammar as the knights' grimoires.

const PROGRAMS := [
	["bolt", "venom"],
	["orb", "void"],
	["bolt", "split", "ember"],
	["rain", "ember"],
	["serpent", "venom"],
	["mine", "frost"],
	["wave", "storm"],
	["bolt", "on_end", "nova"],
]

var program: SpellProgram
var cast_timer := 2.0
var strafe := 1.0
var strafe_timer := 0.0
var casting := 0.0
var _released := false
var _cast_target := Vector3.ZERO


func _setup() -> void:
	var src: Array = PROGRAMS[randi() % PROGRAMS.size()].duplicate()
	if elite:
		src.append(["split", "echo", "seek"][randi() % 3])
	program = SpellProgram.compile(src)
	cast_timer = randf_range(1.2, 2.6)


func _think(delta: float) -> void:
	if target == null:
		play("idle")
		return
	if casting > 0.0:
		casting -= delta
		face(dir_to_target(), delta, 8.0)
		if not _released and casting <= 0.45:
			_released = true
			_release()
		if casting <= 0.0:
			cast_timer = randf_range(2.6, 3.8) * (0.75 if elite else 1.0)
		return
	var d := dist_to_target()
	var to := dir_to_target()
	strafe_timer -= delta
	if strafe_timer <= 0.0:
		strafe_timer = randf_range(1.2, 2.4)
		strafe = -strafe if randf() < 0.6 else strafe
	var side := Vector3(-to.z, 0.0, to.x) * strafe
	if d < 5.0:
		desired = (-to * 1.0 + side * 0.5).normalized() * speed
	elif d > 9.0:
		desired = (to + side * 0.3).normalized() * speed
	else:
		desired = side * speed * 0.6
	play("move" if desired.length() > 0.3 else "idle")
	cast_timer -= delta
	if cast_timer <= 0.0 and d < 13.0:
		_begin_cast()


func _begin_cast() -> void:
	casting = 0.95
	_released = false
	lock_anim("cast", 0.95, 0.08)
	_cast_target = target.global_position
	CastCircle.spawn(self, program, 0.55)
	var aim: int = GlyphDB.FORMS[program.dominant_form()].aim
	if aim == GlyphDB.Aim.POINT:
		var r: float = GlyphDB.FORMS[program.dominant_form()].get("radius", 2.0)
		telegraph_circle(_cast_target, r + 0.4, 0.5)
	Audio.play("enemy_cast", global_position, -6.0)


func _release() -> void:
	if target:
		_cast_target = _cast_target.lerp(target.global_position, 0.5)
	var c := SpellCast.make(self, null, program, _cast_target)
	c.side = "enemies"
	c.power_mult = 1.0 + (Game.run.difficulty() if Game.run else 0.0) * 0.8
	var dir := Combat.flat(_cast_target - global_position).normalized()
	SpellRunner.cast(c, global_position + dir * 0.6, dir)


func aim_state() -> Dictionary:
	var p := target.global_position if target else global_position + face_dir * 5.0
	return {"origin": global_position, "dir": dir_to_target(), "point": p}

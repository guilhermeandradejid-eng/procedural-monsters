extends Enemy
## The Binder: a golem of stacked tomes with chain arms. Three phases.
##  I   slam (book fists), volley (flying books), summon blots
##  II  + chain sweep, faster
##  III enraged: slams send shockwaves, bigger volleys

signal phase_changed(phase: int)

var phase := 1
var state := "intro"
var timer := 0.0
var attack := ""
var cooldown := 1.5
var _done := false
var _slam_center := Vector3.ZERO
var _sweep_dir := Vector3.ZERO
var _volley_dirs: Array[Vector3] = []
var _last_attack := ""


func _setup() -> void:
	state = "intro"
	timer = 1.4
	lock_anim("roar", 1.1, 0.1)
	Juice.shake(0.6)
	Audio.play("boss_roar", global_position, 2.0)


func display_name() -> String:
	return tr("BOSS_BINDER")


func _think(delta: float) -> void:
	var hp_r := hp_ratio()
	var want_phase := 1 if hp_r > 0.66 else (2 if hp_r > 0.33 else 3)
	if want_phase > phase and state != "roar":
		phase = want_phase
		state = "roar"
		timer = 1.2
		lock_anim("roar", 1.1, 0.1)
		Juice.shake(0.7)
		Juice.slowmo(0.35, 0.4)
		Audio.play("boss_roar", global_position, 2.0)
		Events.toast.emit(tr("BOSS_ENRAGE") if phase == 3 else tr("BOSS_PHASE2"), Pal.WAX_LIGHT)
		Events.boss_phase.emit(phase)
		phase_changed.emit(phase)
		for p in Combat.players_near(global_position, 5.5):
			p.take_hit(_enemy_hit(damage * 0.3, p.global_position, p.global_position - global_position, 12.0))
		return
	var tempo := 1.0 if phase == 1 else (1.2 if phase == 2 else 1.4)
	match state:
		"intro", "roar":
			timer -= delta
			if timer <= 0.0:
				state = "walk"
				cooldown = 0.6
		"walk":
			cooldown -= delta * tempo
			if target:
				var d := dist_to_target()
				desired = dir_to_target() * speed * (1.0 + 0.2 * (phase - 1)) if d > 3.5 else Vector3.ZERO
				play("move" if desired.length() > 0.1 else "idle", 0.25)
				if cooldown <= 0.0:
					_choose(d)
		"attack":
			timer += delta * tempo
			_attack_step(delta)


func _choose(d: float) -> void:
	var options: Array[String] = []
	if d < 5.5:
		options.append_array(["slam", "slam"])
		if phase >= 2:
			options.append_array(["sweep", "sweep"])
	else:
		options.append_array(["volley", "volley"])
	if Combat.enemies.size() < 4 + phase:
		options.append("summon")
	if options.size() > 1 and randf() < 0.6:
		var trimmed := options.filter(func(o): return o != _last_attack)
		if not trimmed.is_empty():
			options.assign(trimmed)
	attack = options[randi() % options.size()]
	_last_attack = attack
	state = "attack"
	timer = 0.0
	_done = false
	desired = Vector3.ZERO
	match attack:
		"slam":
			_slam_center = global_position + dir_to_target() * 2.6
			lock_anim("slam", 1.6, 0.12)
			telegraph_circle(_slam_center, 3.4, 0.88 / (1.0 + 0.2 * (phase - 1)))
		"sweep":
			_sweep_dir = dir_to_target()
			lock_anim("sweep", 1.5, 0.12)
			telegraph_cone(global_position, _sweep_dir, 6.2, deg_to_rad(78.0), 0.72 / (1.0 + 0.2 * (phase - 1)))
		"volley":
			lock_anim("volley", 1.0, 0.12)
			_volley_dirs.clear()
			var n := 5 if phase < 3 else 9
			var base := dir_to_target()
			var spread := deg_to_rad(60.0 if phase < 3 else 100.0)
			for i in n:
				var a := (float(i) / (n - 1) - 0.5) * spread
				var dd := base.rotated(Vector3.UP, a)
				_volley_dirs.append(dd)
				telegraph_line(global_position + dd * 1.5, dd, 12.0, 0.45, 0.55)
		"summon":
			lock_anim("summon", 1.3, 0.12)
			Audio.play("boss_summon", global_position, 0.0)


func _attack_step(delta: float) -> void:
	match attack:
		"slam":
			if timer < 0.5:
				face(Combat.flat(_slam_center - global_position), delta, 5.0)
			if not _done and timer >= 0.88:
				_done = true
				attack_circle(_slam_center, 3.4, damage, 10.0)
				Fx.ring(_slam_center, 3.8, Color("c9a15b"), Pal.PAPER_LIGHT, 0.45, 0.2, 2.5)
				Fx.burst(_slam_center, "paper", Pal.PAPER, Pal.PAPER_DARK, 24, 1.6)
				Fx.burst(_slam_center, "dust", Pal.PAPER_DARK, Color(Pal.PAPER_SHADOW, 0.0), 16, 2.0)
				Fx.splat(_slam_center, 1.6, Pal.INK)
				Juice.shake(0.7)
				Juice.punch(0.05)
				Audio.play("slam", _slam_center, 3.0, 0.8)
				if phase >= 3:
					Shockwave.spawn(self, _slam_center, 13.0, 7.5, damage * 0.6)
			if timer >= 1.6:
				_end_attack(1.4)
		"sweep":
			if not _done and timer >= 0.75:
				_done = true
				attack_cone(global_position, _sweep_dir, 6.2, deg_to_rad(78.0), damage * 0.9, 11.0)
				for i in 7:
					var a := (float(i) / 6.0 - 0.5) * deg_to_rad(150.0)
					Fx.burst(global_position + _sweep_dir.rotated(Vector3.UP, a) * 4.5 + Vector3.UP * 0.8, "spark", Color("c8ccd0"), Pal.GOLD, 5, 0.8)
				Juice.shake(0.45)
				Audio.play("chain_sweep", global_position, 2.0)
			if timer >= 1.5:
				_end_attack(1.2)
		"volley":
			if not _done and timer >= 0.55:
				_done = true
				for dd in _volley_dirs:
					var s := EnemyShot.straight(self, global_position + Vector3.UP * 1.6 + dd * 1.4, dd, 10.5, damage * 0.6, "book")
					Level.current.add_spell(s)
				Audio.play("volley", global_position, 0.0)
				Juice.shake(0.2)
			if timer >= 1.0:
				_end_attack(1.0)
		"summon":
			if not _done and timer >= 0.8:
				_done = true
				var n := 2 + phase
				for i in n:
					var a := TAU * i / n + randf() * 0.5
					var p := global_position + Vector3(cos(a), 0.0, sin(a)) * 4.0
					if Level.current.has_method("spawn_enemy"):
						Level.current.spawn_enemy("blot" if i % 3 != 2 else "moth", p, false)
				Juice.shake(0.3)
			if timer >= 1.3:
				_end_attack(1.6)


func _end_attack(cd: float) -> void:
	state = "walk"
	cooldown = cd * (1.0 if phase == 1 else (0.8 if phase == 2 else 0.6))


func _on_died(hit: Hit) -> void:
	Juice.slowmo(1.6, 0.2, 0.8)
	Juice.shake(1.0)
	Audio.play("boss_death", global_position, 3.0)
	for i in 6:
		var a := TAU * i / 6.0
		var p := global_position + Vector3(cos(a), 0, sin(a)) * randf_range(1.0, 3.0)
		Fx.splat(p, randf_range(1.0, 2.0), Pal.INK)
		Fx.burst(p + Vector3.UP * 1.5, "paper", Pal.PAPER, Pal.PAPER_DARK, 20, 2.0)
	super._on_died(hit)

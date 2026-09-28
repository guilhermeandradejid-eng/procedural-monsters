class_name EnemyShot
extends Node3D
## Hostile projectile: straight shots and lobbed bombs (Inkpot, Binder books).

var source: Node3D
var mode := "straight"
var velocity := Vector3.ZERO
var start := Vector3.ZERO
var end := Vector3.ZERO
var flight := 1.0
var arc_height := 4.0
var damage := 8.0
var radius := 0.4
var splash := 1.6
var life := 3.0
var age := 0.0
var visual := "ink"
var on_land: Callable
var _body: Node3D
var _trail: Trail3D
static var _ink_mat: ShaderMaterial


static func lob(p_source: Node3D, from: Vector3, to: Vector3, p_flight: float, p_damage: float, p_splash: float) -> EnemyShot:
	var s := EnemyShot.new()
	s.source = p_source
	s.mode = "lob"
	s.start = from
	s.end = to
	s.flight = p_flight
	s.damage = p_damage
	s.splash = p_splash
	return s


static func straight(p_source: Node3D, from: Vector3, dir: Vector3, spd: float, p_damage: float, p_visual := "ink") -> EnemyShot:
	var s := EnemyShot.new()
	s.source = p_source
	s.mode = "straight"
	s.start = from
	s.velocity = Combat.flat(dir).normalized() * spd
	s.damage = p_damage
	s.visual = p_visual
	return s


func _ready() -> void:
	global_position = start
	if visual == "book":
		_body = Toon.spawn("res://assets/models/grimoire.glb", {"Cover": [Color("7a1f1a"), Color("2d4a6b"), Color("3f5a2b")][randi() % 3]})
		_body.scale = Vector3.ONE * 1.4
		add_child(_body)
		var ap := Toon.find_anim_player(_body)
		if ap:
			ap.play("open")
		radius = 0.6
	else:
		if _ink_mat == null:
			_ink_mat = ShaderMaterial.new()
			_ink_mat.shader = preload("res://shaders/fx/energy.gdshader")
			_ink_mat.set_shader_parameter("core_color", Color("3a2a4a"))
			_ink_mat.set_shader_parameter("main_color", Color("1b1a2e"))
			_ink_mat.set_shader_parameter("dark_color", Color("0a0810"))
			_ink_mat.set_shader_parameter("rim_color", Color("ff5a36"))
			_ink_mat.set_shader_parameter("glow", 1.0)
			_ink_mat.set_shader_parameter("dark_core", 1.0)
		var mi := MeshInstance3D.new()
		mi.mesh = SpellMeshes.sphere(12)
		mi.material_override = _ink_mat
		mi.scale = Vector3.ONE * (0.35 if mode == "lob" else 0.28)
		add_child(mi)
		_body = mi
		_trail = Trail3D.new()
		_trail.target = mi
		_trail.width = 0.35
		_trail.lifetime = 0.25
		var tm := ShaderMaterial.new()
		tm.shader = preload("res://shaders/fx/trail.gdshader")
		tm.set_shader_parameter("head_color", Color("ff5a36"))
		tm.set_shader_parameter("tail_color", Color("1b1a2e"))
		tm.set_shader_parameter("glow", 1.2)
		_trail.material_override = tm
		add_child(_trail)


func _physics_process(delta: float) -> void:
	age += delta
	if mode == "lob":
		var t := clampf(age / flight, 0.0, 1.0)
		var p := start.lerp(end, t)
		p.y += arc_height * 4.0 * t * (1.0 - t)
		global_position = p
		if _body:
			_body.rotate_x(delta * 8.0)
		if t >= 1.0:
			_land(end)
		return
	var from := global_position
	global_position += velocity * delta
	if _body and visual == "book":
		_body.rotate_y(delta * 9.0)
	var hit := Combat.ray(get_world_3d(), from, global_position)
	if not hit.is_empty():
		_pop(hit.position)
		return
	for p in Combat.players_near(Combat.flat(global_position), radius):
		var h := Hit.make(damage, source, p.global_position, "enemy")
		h.knockback = velocity.normalized() * 4.0
		p.take_hit(h)
		_pop(global_position)
		return
	if age > life:
		_pop(global_position)


func _land(p: Vector3) -> void:
	for pl in Combat.players_near(p, splash):
		var h := Hit.make(damage, source, pl.global_position, "enemy")
		h.knockback = Combat.flat(pl.global_position - p).normalized() * 5.0
		pl.take_hit(h)
	Fx.ring(p, splash * 1.1, Color("3a2a4a"), Color("ff5a36"), 0.3, 0.2, 1.4)
	Fx.burst(p + Vector3.UP * 0.2, "ink", Pal.INK, Color("1b1a2e"), 16, 1.2)
	Fx.splat(p, splash * 0.8, Color("1b1a2e"))
	Audio.play("splash", p, -4.0)
	Juice.shake(0.12)
	if on_land.is_valid():
		on_land.call(p)
	_finish()


func _pop(p: Vector3) -> void:
	Fx.burst(p, "ink", Pal.INK, Color("1b1a2e"), 8, 0.8)
	if visual == "book":
		Fx.burst(p, "paper", Pal.PAPER, Pal.PAPER_DARK, 8, 1.0)
		Audio.play("book_thud", p, -6.0)
	_finish()


func _finish() -> void:
	if _trail:
		_trail.detach()
	queue_free()

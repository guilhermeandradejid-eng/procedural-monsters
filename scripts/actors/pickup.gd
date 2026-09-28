class_name Pickup
extends Node3D
## Gold coins, embers (meta currency) and ink hearts. They pop out, bounce,
## then fly into the nearest knight once they come close (magnetism).

var kind := "gold"
var amount := 1
var velocity := Vector3.ZERO
var age := 0.0
var _y_vel := 0.0
var _mesh: MeshInstance3D
var _grabbed: Node3D = null
static var _mats := {}


static func scatter(p: Vector3, p_kind: String, total: int) -> void:
	if Level.current == null or total <= 0:
		return
	var pieces := mini(total, 8) if p_kind != "heart" else 1
	var per := int(ceil(float(total) / pieces))
	var left := total
	for i in pieces:
		var pk := Pickup.new()
		pk.kind = p_kind
		pk.amount = mini(per, left)
		left -= pk.amount
		var a := randf() * TAU
		pk.velocity = Vector3(cos(a), 0.0, sin(a)) * randf_range(1.5, 4.0)
		pk._y_vel = randf_range(4.0, 7.0)
		Level.current.add_fx(pk)
		pk.global_position = p + Vector3.UP * 0.6
		if left <= 0:
			break


func _ready() -> void:
	_mesh = MeshInstance3D.new()
	var col: Color
	match kind:
		"gold":
			var c := CylinderMesh.new()
			c.top_radius = 0.16
			c.bottom_radius = 0.16
			c.height = 0.05
			c.radial_segments = 10
			_mesh.mesh = c
			col = Pal.GOLD_BRIGHT
		"ember":
			_mesh.mesh = SpellMeshes.spindle(3, 0.3, 0)
			col = Pal.EMBER
			_mesh.scale = Vector3.ONE * 0.28
		_:
			_mesh.mesh = SpellMeshes.sphere(10)
			col = Pal.HEAL
			_mesh.scale = Vector3.ONE * 0.26
	if not _mats.has(kind):
		var m := ShaderMaterial.new()
		m.shader = preload("res://shaders/fx/energy.gdshader")
		m.set_shader_parameter("core_color", Color.WHITE)
		m.set_shader_parameter("main_color", col)
		m.set_shader_parameter("dark_color", col.darkened(0.5))
		m.set_shader_parameter("rim_color", Color.WHITE)
		m.set_shader_parameter("glow", 1.6 if kind != "gold" else 1.1)
		_mats[kind] = m
	_mesh.material_override = _mats[kind]
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)


func _physics_process(delta: float) -> void:
	age += delta
	if _grabbed and is_instance_valid(_grabbed):
		var to := _grabbed.global_position + Vector3.UP * 0.9 - global_position
		global_position += to.normalized() * minf(to.length(), delta * (8.0 + age * 18.0))
		if to.length() < 0.4:
			_collect(_grabbed)
		return
	if global_position.y > 0.2 or _y_vel > 0.0:
		_y_vel -= 22.0 * delta
		global_position += Vector3(velocity.x, _y_vel, velocity.z) * delta
		if global_position.y <= 0.2:
			global_position.y = 0.2
			_y_vel = -_y_vel * 0.35 if absf(_y_vel) > 2.0 else 0.0
			velocity *= 0.5
	_mesh.rotation.y += delta * 3.0
	_mesh.rotation.x = 1.2 if kind == "gold" else 0.0
	_mesh.position.y = 0.1 + sin(age * 5.0) * 0.06
	if age < 0.35:
		return
	var p := Combat.nearest_player(global_position, 3.2)
	if p:
		_grabbed = p


func _collect(p: Node3D) -> void:
	match kind:
		"gold":
			if Game.run:
				Game.run.gold += int(round(amount * p.profile.stat("gold_mult")))
			Audio.play("coin", global_position, -8.0, randf_range(0.95, 1.2), 0.0, 25)
		"ember":
			if Game.run:
				Game.run.embers += amount
			Audio.play("ember", global_position, -8.0, randf_range(0.95, 1.15), 0.0, 25)
		"heart":
			p.heal(12.0)
			Audio.play("heal", global_position, -4.0)
	Events.pickup.emit(p, kind, amount)
	Fx.burst(global_position, "twinkle", Pal.GOLD_BRIGHT if kind == "gold" else Pal.EMBER, Pal.GOLD, 3, 0.5)
	queue_free()

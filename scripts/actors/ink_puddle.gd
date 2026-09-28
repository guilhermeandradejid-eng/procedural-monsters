class_name InkPuddle
extends Node3D
## Glossy ink left on the page: knights wading through it are slowed.

var radius := 1.8
var life := 4.0
var age := 0.0
var _mi: MeshInstance3D


static func spawn(p: Vector3, r: float, duration: float) -> void:
	if Level.current == null:
		return
	var pd := InkPuddle.new()
	pd.radius = r
	pd.life = duration
	Level.current.add_fx(pd)
	pd.global_position = Combat.flat(p)


func _ready() -> void:
	_mi = MeshInstance3D.new()
	_mi.mesh = SpellMeshes.flat_quad()
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/fx/zone.gdshader")
	m.set_shader_parameter("color", Color("2d2a4a"))
	m.set_shader_parameter("dark", Color("0a0810"))
	m.set_shader_parameter("glow", 1.0)
	m.set_shader_parameter("swirl", 0.3)
	_mi.material_override = m
	_mi.position = Vector3.UP * 0.025
	_mi.scale = Vector3.ONE * radius
	_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mi)
	Fx.splat(global_position, radius * 0.9, Color("141224"))


func _physics_process(delta: float) -> void:
	age += delta
	for p in Combat.players_near(global_position, radius * 0.9):
		p.status.add_slow(0.4, 0.25)
	var f := clampf(minf(age / 0.2, (life - age) / 0.5), 0.0, 1.0)
	_mi.set_instance_shader_parameter(&"fade", f)
	if age >= life:
		queue_free()

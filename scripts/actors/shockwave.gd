class_name Shockwave
extends Node3D
## Expanding ring of force. Knights must dash through it (i-frames) or be hit.

var source: Node3D
var max_radius := 12.0
var speed := 7.0
var damage := 10.0
var r := 0.5
var _hit: Array = []
var _mi: MeshInstance3D


static func spawn(p_source: Node3D, center: Vector3, p_max: float, p_speed: float, p_damage: float) -> void:
	if Level.current == null:
		return
	var s := Shockwave.new()
	s.source = p_source
	s.max_radius = p_max
	s.speed = p_speed
	s.damage = p_damage
	Level.current.add_spell(s)
	s.global_position = Combat.flat(center)


func _ready() -> void:
	_mi = MeshInstance3D.new()
	_mi.mesh = SpellMeshes.flat_quad()
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/fx/ring.gdshader")
	m.set_shader_parameter("color", Pal.TELEGRAPH)
	m.set_shader_parameter("core", Pal.PAPER_LIGHT)
	m.set_shader_parameter("glow", 2.4)
	_mi.material_override = m
	_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mi.position = Vector3.UP * 0.08
	add_child(_mi)
	_mi.set_instance_shader_parameter(&"thickness", 0.06)


func _physics_process(delta: float) -> void:
	r += speed * delta
	_mi.scale = Vector3.ONE * (r / 0.92)
	_mi.set_instance_shader_parameter(&"progress", 0.92)
	for p in Combat.players:
		if not is_instance_valid(p) or p.downed or _hit.has(p):
			continue
		var d := Combat.flat_dist(p.global_position, global_position)
		if absf(d - r) < 0.55:
			_hit.append(p)
			var h := Hit.make(damage, source, p.global_position, "enemy")
			h.knockback = Combat.flat(p.global_position - global_position).normalized() * 7.0
			p.take_hit(h)
	if r >= max_radius:
		queue_free()

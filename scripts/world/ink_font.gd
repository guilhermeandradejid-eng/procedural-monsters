class_name InkFont
extends Node3D
## Rest page: a basin of warm golden ink. Each knight drinks once: heals 40%
## of max HP; downed allies are rekindled when anyone drinks.

var interact_radius := 2.3
var used := {}
var _liquid: MeshInstance3D


func _ready() -> void:
	add_to_group("interactable")
	RoomBuilder.prop(self, "pedestal", Vector3.ZERO, 0.0, 1.6)
	_liquid = MeshInstance3D.new()
	_liquid.mesh = SpellMeshes.flat_quad()
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/fx/zone.gdshader")
	m.set_shader_parameter("color", Pal.GOLD_BRIGHT)
	m.set_shader_parameter("dark", Pal.EMBER)
	m.set_shader_parameter("glow", 1.8)
	m.set_shader_parameter("swirl", 1.5)
	_liquid.material_override = m
	_liquid.position = Vector3(0, 1.42, 0)
	_liquid.scale = Vector3.ONE * 0.62
	add_child(_liquid)
	var l := OmniLight3D.new()
	l.light_color = Pal.GOLD_BRIGHT
	l.light_energy = 2.0
	l.omni_range = 5.0
	l.position = Vector3.UP * 1.8
	add_child(l)
	Fx.emitter(self, "twinkle", Pal.GOLD_BRIGHT, Pal.EMBER, 10, 1.6).position = Vector3.UP * 1.5


func can_interact(p: Node3D) -> bool:
	return not used.has(p.profile.index)


func interact_prompt() -> String:
	return tr("FONT_DRINK")


func interact(p: Node3D) -> void:
	if used.has(p.profile.index):
		return
	used[p.profile.index] = true
	var healed: float = p.heal(p.profile.stat("max_hp") * 0.4)
	Fx.heal_number(p.global_position + Vector3.UP * 2.0, healed)
	Fx.ring(global_position, 3.5, Pal.GOLD_BRIGHT, Color.WHITE, 0.6, 0.1)
	Audio.play("heal", global_position, 0.0)
	for other in Combat.players:
		if other.downed:
			other.revive(0.4)
	if used.size() >= Game.profiles.size():
		var t := create_tween()
		t.tween_method(func(v: float): _liquid.set_instance_shader_parameter(&"fade", v), 1.0, 0.2, 1.0)

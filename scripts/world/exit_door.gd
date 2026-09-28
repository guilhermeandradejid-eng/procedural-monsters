class_name ExitDoor
extends Node3D
## An arch on the far edge of the page with a bookmark ribbon. It shows the
## reward of the page behind it and stays sealed with ink until the page is won.

signal chosen(door: ExitDoor)

var room := {"kind": "combat", "reward": "glyph"}
var open := false
var interact_radius := 2.4
var _arch: Node3D
var _icon: MeshInstance3D
var _seal: MeshInstance3D
var _t := 0.0


func _ready() -> void:
	add_to_group("interactable")
	_arch = RoomBuilder.prop(self, "arch", Vector3.ZERO)
	_icon = MeshInstance3D.new()
	_icon.mesh = SpellMeshes.flat_quad()
	var col := _reward_color()
	_icon.material_override = SpellFx.sigil_material(Fx.icons.for_icon("reward_" + String(room.reward)), col, Color.WHITE, 0.0)
	_icon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_icon)
	_icon.position = Vector3(0, 4.3, 0.2)
	_icon.rotation.x = PI * 0.5 - 0.5
	_icon.scale = Vector3.ONE * 0.75
	_icon.set_instance_shader_parameter(&"fade", 0.35)
	_seal = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.9, 2.6)
	_seal.mesh = q
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/fx/zone.gdshader")
	m.set_shader_parameter("color", Color("2d2a4a"))
	m.set_shader_parameter("dark", Color("0a0810"))
	m.set_shader_parameter("glow", 1.0)
	m.set_shader_parameter("swirl", 1.0)
	_seal.material_override = m
	_seal.position = Vector3(0, 1.3, 0)
	add_child(_seal)
	_seal.set_instance_shader_parameter(&"fade", 1.0)


func _reward_color() -> Color:
	match String(room.reward):
		"relic":
			return Color("c08cff")
		"gold":
			return Pal.GOLD_BRIGHT
		"heal":
			return Pal.HEAL
		"page":
			return Pal.PAPER_LIGHT
		"shop":
			return Color("7fe3ff")
		"boss":
			return Pal.WAX_LIGHT
	return Pal.EMBER


func unlock() -> void:
	if open:
		return
	open = true
	var t := create_tween()
	t.tween_method(func(v: float): _seal.set_instance_shader_parameter(&"fade", v), 1.0, 0.0, 0.8)
	t.parallel().tween_method(func(v: float): _icon.set_instance_shader_parameter(&"fade", v), 0.35, 1.0, 0.6)
	t.tween_callback(_seal.hide)
	Fx.burst(global_position + Vector3.UP * 1.3, "ink", Pal.INK, Pal.INK_SOFT, 16, 1.2)
	Audio.play("door_open", global_position, -4.0)


func _process(delta: float) -> void:
	_t += delta
	_icon.position.y = 4.3 + sin(_t * 2.0) * 0.12


func can_interact(_p: Node3D) -> bool:
	return open


func interact_prompt() -> String:
	return tr("DOOR_%s" % String(room.reward).to_upper())


func interact(_p: Node3D) -> void:
	if not open:
		return
	open = false
	Audio.play("page_turn", global_position, 0.0)
	chosen.emit(self)

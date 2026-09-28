class_name ScreenFx
extends ColorRect
## Full-screen post treatment driven by Juice.pulse() and team health.

var _hurt := 0.0
var _perfect := 0.0
var _time := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/ui/screen_fx.gdshader")
	material = m
	Juice.screen_pulse.connect(_on_pulse)


func _on_pulse(kind: StringName, strength: float) -> void:
	match kind:
		&"hurt":
			_hurt = maxf(_hurt, 0.8 * strength)
		&"perfect":
			_perfect = 1.0


func _process(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, 0.001)
	_time += real
	_hurt = maxf(0.0, _hurt - real * 2.2)
	_perfect = maxf(0.0, _perfect - real * 1.6)
	var low := 0.0
	for p in Game.profiles:
		if p.actor and is_instance_valid(p.actor) and not p.actor.downed:
			var r := p.hp / maxf(p.stat("max_hp"), 1.0)
			low = maxf(low, clampf((0.3 - r) / 0.3, 0.0, 1.0))
	var m := material as ShaderMaterial
	m.set_shader_parameter("hurt", _hurt)
	m.set_shader_parameter("perfect", _perfect)
	m.set_shader_parameter("low_hp", low)
	m.set_shader_parameter("time_s", _time)

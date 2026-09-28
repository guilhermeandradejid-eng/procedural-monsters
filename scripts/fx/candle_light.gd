class_name CandleLight
extends OmniLight3D
## Warm flickering candle light (two sines + noise, never in sync).

var base_energy := 0.85
var _t := 0.0


func _ready() -> void:
	light_color = Color("ffb870")
	omni_range = 4.5
	omni_attenuation = 2.0
	light_energy = base_energy
	shadow_enabled = false
	_t = randf() * 100.0


func _process(delta: float) -> void:
	_t += delta
	light_energy = base_energy * (0.86 + sin(_t * 9.1) * 0.06 + sin(_t * 23.7) * 0.04 + sin(_t * 3.3) * 0.05)

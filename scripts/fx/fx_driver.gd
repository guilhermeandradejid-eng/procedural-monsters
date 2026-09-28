class_name FxDriver
extends Node3D
## Tiny helper: runs a callable every frame (for effects that need animation
## without their own script), optionally freeing itself after `life` seconds.

var fn: Callable
var life := -1.0
var age := 0.0


static func make(p_fn: Callable, p_life := -1.0) -> FxDriver:
	var d := FxDriver.new()
	d.fn = p_fn
	d.life = p_life
	return d


func _process(delta: float) -> void:
	age += delta
	if fn.is_valid():
		fn.call(delta, age)
	if life >= 0.0 and age >= life:
		queue_free()

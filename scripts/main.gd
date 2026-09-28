extends Node
## Root of the game. Owns the 3D world slot, the UI layers and scene flow.
## Levels are swapped under `world`; profiles and settings live in Game.

var world: Node3D
var ui_layer: CanvasLayer
var fx_layer: CanvasLayer
var transition_layer: CanvasLayer
var current: Node = null


func _ready() -> void:
	Game.main = self
	world = Node3D.new()
	world.name = "World"
	add_child(world)
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UI"
	ui_layer.layer = 10
	add_child(ui_layer)
	fx_layer = CanvasLayer.new()
	fx_layer.name = "ScreenFx"
	fx_layer.layer = 50
	add_child(fx_layer)
	transition_layer = CanvasLayer.new()
	transition_layer.name = "Transition"
	transition_layer.layer = 100
	add_child(transition_layer)


func on_device_lost(_input: PlayerInput) -> void:
	pass

class_name Level
extends Node3D
## Base for every playable space (hub page, combat pages). Provides the
## containers gameplay code spawns into and a scene-time scheduler.

static var current: Level = null

var actors: Node3D
var spells: Node3D
var fx: Node3D
var decals: Node3D
var camera_rig: CameraRig
## Playable rectangle on XZ (used by the camera leash and spawners).
var bounds := Rect2(-12, -9, 24, 18)
var _timers: Array[Dictionary] = []
var time := 0.0


func _enter_tree() -> void:
	current = self
	for n in ["Actors", "Spells", "Fx", "Decals"]:
		if get_node_or_null(n) == null:
			var c := Node3D.new()
			c.name = n
			add_child(c)
	actors = $Actors
	spells = $Spells
	fx = $Fx
	decals = $Decals
	Fx.register_level(self)


func _exit_tree() -> void:
	if current == self:
		current = null


func add_actor(n: Node3D) -> void:
	actors.add_child(n)


func add_spell(n: Node3D) -> void:
	spells.add_child(n)


func add_fx(n: Node3D) -> void:
	fx.add_child(n)


## Runs `fn` after `delay` seconds of game time (respects pause and hitstop).
func after(delay: float, fn: Callable) -> void:
	_timers.append({"t": time + delay, "fn": fn})


func _physics_process(delta: float) -> void:
	time += delta
	if _timers.is_empty():
		return
	var due: Array[Dictionary] = []
	for i in range(_timers.size() - 1, -1, -1):
		if _timers[i].t <= time:
			due.append(_timers[i])
			_timers.remove_at(i)
	for i in range(due.size() - 1, -1, -1):
		var fn: Callable = due[i].fn
		if fn.is_valid():
			fn.call()


func clear_spells() -> void:
	for c in spells.get_children():
		c.queue_free()

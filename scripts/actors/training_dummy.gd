class_name TrainingDummy
extends Actor
## A straw dummy for testing spells in the hub. It never dies and reports
## damage per second above its head.

var active := true
var height := 1.6
var _dps_window: Array = []
var _label: Label3D
var _regen_t := 0.0


func _ready() -> void:
	super._ready()
	max_hp = 99999.0
	hp = max_hp
	radius = 0.5
	weight = 99.0
	collision_layer = Combat.LAYER_ENEMIES
	collision_mask = 0
	var model := Toon.spawn("res://assets/models/props/dummy.glb")
	pivot.add_child(model)
	collect_geometry()
	var body := StaticBody3D.new()
	body.collision_layer = Combat.LAYER_WORLD
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.35
	cyl.height = 1.6
	cs.shape = cyl
	cs.position = Vector3.UP * 0.8
	body.add_child(cs)
	add_child(body)
	_label = Label3D.new()
	_label.font = UiFonts.numbers()
	_label.font_size = 40
	_label.outline_size = 12
	_label.outline_modulate = Pal.INK
	_label.modulate = Pal.PAPER_LIGHT
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.fixed_size = true
	_label.pixel_size = 0.0005
	_label.position = Vector3(0, 2.3, 0)
	add_child(_label)
	Combat.register_enemy(self)


func _exit_tree() -> void:
	Combat.unregister_enemy(self)


func targetable() -> bool:
	return true


func _on_damaged(hit: Hit) -> void:
	_dps_window.append([Time.get_ticks_msec(), hit.dealt])
	_regen_t = 2.0
	if hit.kind != "dot":
		pivot.rotation.z = randf_range(-0.12, 0.12)


func die(_hit: Hit) -> void:
	hp = max_hp


func _physics_process(delta: float) -> void:
	tick_actor(delta)
	knock = Vector3.ZERO
	pivot.rotation.z = lerpf(pivot.rotation.z, 0.0, 1.0 - exp(-delta * 6.0))
	var now := Time.get_ticks_msec()
	while not _dps_window.is_empty() and now - int(_dps_window[0][0]) > 3000:
		_dps_window.pop_front()
	var total := 0.0
	for e in _dps_window:
		total += float(e[1])
	_label.text = "%d /s" % int(total / 3.0) if total > 0.0 else ""
	_regen_t -= delta
	if _regen_t <= 0.0:
		hp = max_hp
		status.clear()

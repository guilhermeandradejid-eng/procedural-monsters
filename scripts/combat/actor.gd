class_name Actor
extends CharacterBody3D
## Shared body for knights and errata: health, statuses, knockback, hit flash
## and squash & stretch. Gameplay happens on the XZ plane (y is locked).

signal died(actor: Actor, hit: Hit)
signal damaged(actor: Actor, hit: Hit)

var max_hp := 30.0
var hp := 30.0
var radius := 0.5
var weight := 1.0
var is_boss := false
var dead := false
var status := StatusSet.new()
var knock := Vector3.ZERO
## Visual pivot used for squash & stretch; the model hangs below it.
var pivot: Node3D
var _flash := 0.0
var _flash_color := Color.WHITE
var _geo: Array[GeometryInstance3D] = []
var _squash_tween: Tween
var status_fx: StatusFx


func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	wall_min_slide_angle = 0.0
	if pivot == null:
		pivot = Node3D.new()
		pivot.name = "Pivot"
		add_child(pivot)
	status_fx = StatusFx.new()
	status_fx.actor = self
	add_child(status_fx)


## Collects every mesh under the pivot so flash/tint can be driven per instance.
func collect_geometry() -> void:
	_geo.clear()
	var stack: Array[Node] = [pivot]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is GeometryInstance3D:
			_geo.append(n)
		for c in n.get_children():
			stack.append(c)


func set_shader_instance(param: StringName, value) -> void:
	for g in _geo:
		if is_instance_valid(g):
			g.set_instance_shader_parameter(param, value)


func targetable() -> bool:
	return not dead


func hp_ratio() -> float:
	return clampf(hp / maxf(max_hp, 1.0), 0.0, 1.0)


## Applies damage. Subclasses extend via _on_damaged / _on_died.
func take_hit(hit: Hit) -> void:
	if dead:
		return
	var amount := hit.amount * status.damage_taken_mult() * _damage_taken_mult(hit)
	# Aurora smites marked targets.
	if Elem.has_part(hit.element, "radiant") and status.marked():
		amount *= 1.3
	amount = maxf(0.0, amount)
	hit.dealt = minf(amount, hp)
	hp -= amount
	if hit.knockback != Vector3.ZERO:
		apply_knockback(hit.knockback)
	if hit.stagger > 0.0:
		status.stun_time = maxf(status.stun_time, hit.stagger * (0.3 if is_boss else 1.0))
	if hit.kind != "dot":
		flash(Color.WHITE, 1.0)
		squash(0.18 if not is_boss else 0.06, 0.22)
	damaged.emit(self, hit)
	_on_damaged(hit)
	if hp <= 0.0:
		hit.killed = true
		die(hit)


func _damage_taken_mult(_hit: Hit) -> float:
	return 1.0


func _on_damaged(_hit: Hit) -> void:
	pass


func die(hit: Hit) -> void:
	if dead:
		return
	dead = true
	hp = 0.0
	died.emit(self, hit)
	_on_died(hit)


func _on_died(_hit: Hit) -> void:
	queue_free()


func apply_knockback(v: Vector3) -> void:
	var k := Combat.flat(v) / maxf(weight, 0.1)
	if is_boss:
		k *= 0.15
	knock += k


func flash(color: Color, amount := 1.0) -> void:
	_flash = maxf(_flash, amount)
	_flash_color = color
	set_shader_instance(&"flash_color", color)


func squash(amount: float, duration := 0.2) -> void:
	if pivot == null:
		return
	if _squash_tween:
		_squash_tween.kill()
	pivot.scale = Vector3(1.0 + amount * 0.6, 1.0 - amount, 1.0 + amount * 0.6)
	_squash_tween = create_tween()
	_squash_tween.tween_property(pivot, "scale", Vector3.ONE, duration).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func stretch(amount: float, duration := 0.2) -> void:
	squash(-amount, duration)


## Call from _physics_process: statuses, DoTs, flash decay, knockback decay.
func tick_actor(delta: float) -> void:
	var dots := status.tick(delta)
	for element in dots:
		var h := Hit.make(float(dots[element]), status.dot_source, global_position, "dot")
		h.element = element
		h.no_proc = true
		h.profile = status.dot_profile
		take_hit(h)
		Fx.damage_number(global_position + Vector3.UP * 1.6, h.dealt, Elem.main_color(element), false, true)
		if dead:
			return
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 9.0)
		set_shader_instance(&"flash", _flash)
	knock = knock.lerp(Vector3.ZERO, 1.0 - exp(-delta * 9.0))
	if knock.length() < 0.05:
		knock = Vector3.ZERO


func stunned() -> bool:
	return status.stun_time > 0.0 or status.frozen()

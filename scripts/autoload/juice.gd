extends Node
## Game-feel toolbox: hitstop, slow motion, camera trauma, screen pulses.
## Everything respects the accessibility settings in Game.settings.

signal trauma_added(amount: float, direction: Vector3)
signal zoom_punch(amount: float, duration: float)
signal screen_pulse(kind: StringName, strength: float)

var _hitstop_until := 0
var _slowmo_until := 0
var _slowmo_scale := 1.0
var _slowmo_recover := 0.25
var _in_hitstop := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Freezes the whole simulation for a few milliseconds so impacts land.
func hitstop(seconds: float, strength := 1.0) -> void:
	if not Game.settings.get("hitstop", true) or get_tree().paused:
		return
	var ms := int(seconds * 1000.0 * clampf(strength, 0.0, 1.5))
	_hitstop_until = maxi(_hitstop_until, Time.get_ticks_msec() + ms)


func slowmo(seconds: float, time_scale := 0.3, recover := 0.25) -> void:
	_slowmo_until = maxi(_slowmo_until, Time.get_ticks_msec() + int(seconds * 1000.0))
	_slowmo_scale = minf(_slowmo_scale, time_scale) if _slowmo_active() else time_scale
	_slowmo_recover = recover


func shake(amount: float, direction := Vector3.ZERO) -> void:
	trauma_added.emit(amount * float(Game.settings.get("shake", 1.0)), direction)


func punch(amount: float, duration := 0.18) -> void:
	zoom_punch.emit(amount * float(Game.settings.get("shake", 1.0)), duration)


func pulse(kind: StringName, strength := 1.0) -> void:
	if kind == &"flash" and not Game.settings.get("flashes", true):
		strength *= 0.25
	screen_pulse.emit(kind, strength)


func _slowmo_active() -> bool:
	return Time.get_ticks_msec() < _slowmo_until


func _process(delta: float) -> void:
	var now := Time.get_ticks_msec()
	if now < _hitstop_until:
		Engine.time_scale = 0.02
		_in_hitstop = true
		return
	var target := 1.0
	if now < _slowmo_until:
		target = _slowmo_scale
	else:
		_slowmo_scale = 1.0
	if _in_hitstop:
		# Hitstop releases instantly: the snap back is part of the punch.
		_in_hitstop = false
		Engine.time_scale = target
		return
	if target < Engine.time_scale:
		Engine.time_scale = target
	else:
		# Ease out of slow motion using unscaled time so recovery feels smooth.
		var real_dt := delta / maxf(Engine.time_scale, 0.001)
		var k := 1.0 - exp(-real_dt / maxf(_slowmo_recover * 0.35, 0.01))
		Engine.time_scale = lerpf(Engine.time_scale, target, k)
		if absf(Engine.time_scale - target) < 0.01:
			Engine.time_scale = target


func reset() -> void:
	_hitstop_until = 0
	_slowmo_until = 0
	_slowmo_scale = 1.0
	Engine.time_scale = 1.0

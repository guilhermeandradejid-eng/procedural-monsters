class_name PlayerInput
extends RefCounted
## Input state for ONE player bound to ONE device. Local co-op needs every
## player to read their own device, so gameplay never touches the global
## InputMap: it asks its PlayerInput instead. Button presses are buffered with
## timestamps so actions pressed slightly early still fire (input buffering).

enum Kind { KBM, KB_ARROWS, PAD }

const ACTIONS := [
	"attack", "dash", "spell_0", "spell_1", "spell_2", "interact", "grimoire", "pause",
	"ui_up", "ui_down", "ui_left", "ui_right", "ui_accept", "ui_back", "ui_prev", "ui_next", "ui_alt",
]

var kind: Kind = Kind.KBM
var pad_id := -1
var move := Vector2.ZERO
## Aim from a stick (pads / keyboard B). KBM aims with the mouse, resolved by the player.
var stick_aim := Vector2.ZERO
## Left stick only (pads), used for repeating menu navigation.
var nav_stick := Vector2.ZERO
var mouse_screen := Vector2.ZERO
var last_mouse_move_ms := 0
## Driven by code (bots/tests): the device is never polled.
var virtual := false

var _held := {}
var _pressed_at := {}


func _init(p_kind: Kind = Kind.KBM, p_pad := -1) -> void:
	kind = p_kind
	pad_id = p_pad
	for a in ACTIONS:
		_held[a] = false
		_pressed_at[a] = -100000


func uses_mouse() -> bool:
	return kind == Kind.KBM and not virtual


func device_key() -> String:
	match kind:
		Kind.KBM:
			return "kbm"
		Kind.KB_ARROWS:
			return "kb2"
	return "pad%d" % pad_id


func label() -> String:
	match kind:
		Kind.KBM:
			return tr("DEVICE_KBM")
		Kind.KB_ARROWS:
			return tr("DEVICE_KB2")
	var n := Input.get_joy_name(pad_id)
	return n if n != "" else tr("DEVICE_PAD")


func set_action(action: String, pressed: bool) -> void:
	if not _held.has(action):
		return
	if pressed and not _held[action]:
		_pressed_at[action] = Time.get_ticks_msec()
	_held[action] = pressed


func is_held(action: String) -> bool:
	return _held.get(action, false)


## True if the action was pressed within `window_ms` and not yet consumed.
func consume(action: String, window_ms := 140) -> bool:
	var t: int = _pressed_at.get(action, -100000)
	if Time.get_ticks_msec() - t <= window_ms:
		_pressed_at[action] = -100000
		return true
	return false


func peek(action: String, window_ms := 140) -> bool:
	var t: int = _pressed_at.get(action, -100000)
	return Time.get_ticks_msec() - t <= window_ms


func clear_buffer() -> void:
	for a in ACTIONS:
		_pressed_at[a] = -100000


func rumble(weak: float, strong: float, duration: float) -> void:
	if kind != Kind.PAD or not Game.settings.get("rumble", true):
		return
	Input.start_joy_vibration(pad_id, clampf(weak, 0.0, 1.0), clampf(strong, 0.0, 1.0), duration)

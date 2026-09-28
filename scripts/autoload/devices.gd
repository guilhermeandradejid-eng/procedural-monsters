extends Node
## Routes raw input events to per-player PlayerInput objects and detects
## "press to join" on devices that are not yet bound to a player.
## Keyboard+mouse, a second keyboard layout (arrows/numpad) and up to 4 pads.

signal join_requested(input: PlayerInput)
signal device_disconnected(input: PlayerInput)

const DEADZONE := 0.22
const TRIGGER_THRESHOLD := 0.45

## device_key -> PlayerInput for devices bound to a player.
var bound := {}
## When false, unbound devices never raise join_requested (e.g. mid-run).
var joining_enabled := true
## Stick-driven UI navigation repeat state, per PlayerInput.
var _nav_repeat := {}
## Trigger edge detection for pads: "padN:axis" -> bool.
var _trigger_state := {}

# --- Keyboard maps -----------------------------------------------------------
const KBM_KEYS := {
	KEY_Q: ["spell_1", "ui_prev"],
	KEY_E: ["spell_2", "ui_next"],
	KEY_SPACE: ["dash", "ui_accept"],
	KEY_F: ["interact", "ui_accept"],
	KEY_TAB: ["grimoire"],
	KEY_ESCAPE: ["pause", "ui_back"],
	KEY_BACKSPACE: ["ui_back"],
	KEY_X: ["ui_alt"],
	KEY_R: ["ui_alt"],
	KEY_DELETE: ["ui_alt"],
	KEY_J: ["attack"],
	KEY_K: ["spell_0"],
	KEY_W: ["ui_up"],
	KEY_S: ["ui_down"],
	KEY_A: ["ui_left"],
	KEY_D: ["ui_right"],
}
## Keys that belong to keyboard B when a player uses it, else to keyboard A.
const SHARED_ARROWS := {
	KEY_UP: "ui_up", KEY_DOWN: "ui_down", KEY_LEFT: "ui_left", KEY_RIGHT: "ui_right",
}
const KB2_KEYS := {
	KEY_KP_1: ["attack", "ui_accept"],
	KEY_SLASH: ["attack", "ui_accept"],
	KEY_KP_0: ["dash", "ui_back"],
	KEY_KP_2: ["spell_0"],
	KEY_PERIOD: ["spell_0", "ui_next"],
	KEY_KP_3: ["spell_1"],
	KEY_COMMA: ["spell_1", "ui_prev"],
	KEY_KP_5: ["spell_2", "ui_alt"],
	KEY_M: ["spell_2", "ui_alt"],
	KEY_KP_ENTER: ["interact", "ui_accept"],
	KEY_ENTER: ["interact", "ui_accept"],
	KEY_KP_ADD: ["grimoire"],
	KEY_SEMICOLON: ["grimoire"],
}
const PAD_BUTTONS := {
	JOY_BUTTON_A: ["dash", "ui_accept"],
	JOY_BUTTON_B: ["spell_1", "ui_back"],
	JOY_BUTTON_X: ["attack", "ui_alt"],
	JOY_BUTTON_Y: ["spell_0"],
	JOY_BUTTON_LEFT_SHOULDER: ["interact", "ui_prev"],
	JOY_BUTTON_RIGHT_SHOULDER: ["spell_2", "ui_next"],
	JOY_BUTTON_BACK: ["grimoire"],
	JOY_BUTTON_START: ["pause"],
	JOY_BUTTON_DPAD_UP: ["ui_up"],
	JOY_BUTTON_DPAD_DOWN: ["ui_down"],
	JOY_BUTTON_DPAD_LEFT: ["ui_left"],
	JOY_BUTTON_DPAD_RIGHT: ["ui_right"],
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func bind(input: PlayerInput) -> void:
	bound[input.device_key()] = input


func unbind(input: PlayerInput) -> void:
	bound.erase(input.device_key())
	_nav_repeat.erase(input)


func is_bound(key: String) -> bool:
	return bound.has(key)


func kb2_active() -> bool:
	return bound.has("kb2")


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if connected:
		return
	var key := "pad%d" % device
	if bound.has(key):
		device_disconnected.emit(bound[key])


# --- Event routing -------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		_route_key(event)
	elif event is InputEventMouseButton:
		_route_mouse_button(event)
	elif event is InputEventMouseMotion:
		var kbm: PlayerInput = bound.get("kbm")
		if kbm:
			kbm.mouse_screen = event.position
			kbm.last_mouse_move_ms = Time.get_ticks_msec()
	elif event is InputEventJoypadButton:
		_route_pad_button(event)


func _route_key(e: InputEventKey) -> void:
	if e.echo:
		return
	var code := e.physical_keycode if e.physical_keycode != KEY_NONE else e.keycode
	var kb2_owns_arrows := kb2_active()
	# Shift: left = keyboard A dash, right = keyboard B dash.
	if code == KEY_SHIFT:
		if e.location == KEY_LOCATION_RIGHT and kb2_owns_arrows:
			_emit_actions("kb2", ["dash", "ui_back"], e.pressed)
		else:
			_emit_actions("kbm", ["dash"], e.pressed)
		return
	if SHARED_ARROWS.has(code):
		_emit_actions("kb2" if kb2_owns_arrows else "kbm", [SHARED_ARROWS[code]], e.pressed)
		return
	if code == KEY_ENTER and not kb2_owns_arrows:
		_emit_actions("kbm", ["ui_accept", "interact"], e.pressed)
		return
	if KB2_KEYS.has(code) and (kb2_owns_arrows or _is_kb2_join_key(code)):
		_emit_actions("kb2", KB2_KEYS[code], e.pressed)
		return
	if KBM_KEYS.has(code):
		_emit_actions("kbm", KBM_KEYS[code], e.pressed)


func _is_kb2_join_key(code: int) -> bool:
	return code == KEY_KP_ENTER or code == KEY_KP_0 or code == KEY_KP_1


func _route_mouse_button(e: InputEventMouseButton) -> void:
	match e.button_index:
		MOUSE_BUTTON_LEFT:
			_emit_actions("kbm", ["attack"], e.pressed)
		MOUSE_BUTTON_RIGHT:
			_emit_actions("kbm", ["spell_0"], e.pressed)
		MOUSE_BUTTON_WHEEL_UP:
			if e.pressed:
				_emit_actions("kbm", ["ui_prev"], true)
				_emit_actions("kbm", ["ui_prev"], false)
		MOUSE_BUTTON_WHEEL_DOWN:
			if e.pressed:
				_emit_actions("kbm", ["ui_next"], true)
				_emit_actions("kbm", ["ui_next"], false)


func _route_pad_button(e: InputEventJoypadButton) -> void:
	if PAD_BUTTONS.has(e.button_index):
		_emit_actions("pad%d" % e.device, PAD_BUTTONS[e.button_index], e.pressed)


func _emit_actions(key: String, actions: Array, pressed: bool) -> void:
	var input: PlayerInput = bound.get(key)
	if input == null:
		if pressed and joining_enabled and _is_join_action(key, actions):
			var fresh := _make_input(key)
			join_requested.emit(fresh)
		return
	for a in actions:
		input.set_action(a, pressed)


func _is_join_action(key: String, actions: Array) -> bool:
	if key.begins_with("pad"):
		return actions.has("ui_accept") or actions.has("pause")
	if key == "kbm":
		return actions.has("ui_accept") or actions.has("attack")
	return actions.has("ui_accept") or actions.has("dash")


func _make_input(key: String) -> PlayerInput:
	if key == "kbm":
		return PlayerInput.new(PlayerInput.Kind.KBM)
	if key == "kb2":
		return PlayerInput.new(PlayerInput.Kind.KB_ARROWS)
	return PlayerInput.new(PlayerInput.Kind.PAD, int(key.substr(3)))


# --- Continuous state (sticks, held movement keys, triggers) --------------------
func _process(delta: float) -> void:
	for key in bound:
		var input: PlayerInput = bound[key]
		match input.kind:
			PlayerInput.Kind.KBM:
				_poll_kbm(input)
			PlayerInput.Kind.KB_ARROWS:
				_poll_kb2(input)
			PlayerInput.Kind.PAD:
				_poll_pad(input)
		_stick_nav(input, delta)


func _key(code: Key) -> bool:
	return Input.is_physical_key_pressed(code)


func _poll_kbm(input: PlayerInput) -> void:
	var v := Vector2(
		float(_key(KEY_D)) - float(_key(KEY_A)),
		float(_key(KEY_S)) - float(_key(KEY_W)))
	if not kb2_active():
		v += Vector2(
			float(_key(KEY_RIGHT)) - float(_key(KEY_LEFT)),
			float(_key(KEY_DOWN)) - float(_key(KEY_UP)))
	input.move = v.limit_length(1.0)
	input.mouse_screen = get_viewport().get_mouse_position()


func _poll_kb2(input: PlayerInput) -> void:
	var v := Vector2(
		float(_key(KEY_RIGHT)) - float(_key(KEY_LEFT)),
		float(_key(KEY_DOWN)) - float(_key(KEY_UP)))
	input.move = v.limit_length(1.0)
	input.stick_aim = Vector2.ZERO


func _poll_pad(input: PlayerInput) -> void:
	var d := input.pad_id
	var ls := Vector2(Input.get_joy_axis(d, JOY_AXIS_LEFT_X), Input.get_joy_axis(d, JOY_AXIS_LEFT_Y))
	var dpad := Vector2(
		float(Input.is_joy_button_pressed(d, JOY_BUTTON_DPAD_RIGHT)) - float(Input.is_joy_button_pressed(d, JOY_BUTTON_DPAD_LEFT)),
		float(Input.is_joy_button_pressed(d, JOY_BUTTON_DPAD_DOWN)) - float(Input.is_joy_button_pressed(d, JOY_BUTTON_DPAD_UP)))
	input.nav_stick = _radial_deadzone(ls)
	input.move = (input.nav_stick + dpad).limit_length(1.0)
	var rs := Vector2(Input.get_joy_axis(d, JOY_AXIS_RIGHT_X), Input.get_joy_axis(d, JOY_AXIS_RIGHT_Y))
	input.stick_aim = _radial_deadzone(rs, 0.3)
	_trigger(input, JOY_AXIS_TRIGGER_RIGHT, ["spell_2"])
	_trigger(input, JOY_AXIS_TRIGGER_LEFT, ["dash"])


func _trigger(input: PlayerInput, axis: JoyAxis, actions: Array) -> void:
	var k := "%s:%d" % [input.device_key(), axis]
	var now := Input.get_joy_axis(input.pad_id, axis) > TRIGGER_THRESHOLD
	var was: bool = _trigger_state.get(k, false)
	if now != was:
		_trigger_state[k] = now
		for a in actions:
			input.set_action(a, now)


func _radial_deadzone(v: Vector2, dz := DEADZONE) -> Vector2:
	var l := v.length()
	if l < dz:
		return Vector2.ZERO
	var t := clampf((l - dz) / (1.0 - dz), 0.0, 1.0)
	return v / l * t


## Converts stick/held movement into discrete, repeating UI navigation presses.
func _stick_nav(input: PlayerInput, delta: float) -> void:
	var st: Dictionary = _nav_repeat.get(input, {"dir": Vector2i.ZERO, "t": 0.0})
	var is_pad := input.kind == PlayerInput.Kind.PAD
	var v := input.nav_stick if is_pad else input.move
	var dir := Vector2i.ZERO
	if v.length() > 0.55:
		if absf(v.x) > absf(v.y):
			dir = Vector2i(signi(int(signf(v.x))), 0)
		else:
			dir = Vector2i(0, signi(int(signf(v.y))))
	if dir != st.dir:
		st.dir = dir
		st.t = 0.38
		# Keyboards already emitted the first press from the key event itself.
		if dir != Vector2i.ZERO and is_pad:
			_pulse_nav(input, dir)
	elif dir != Vector2i.ZERO:
		st.t -= delta
		if st.t <= 0.0:
			st.t = 0.09
			_pulse_nav(input, dir)
	_nav_repeat[input] = st


func _pulse_nav(input: PlayerInput, dir: Vector2i) -> void:
	var a := "ui_right" if dir.x > 0 else "ui_left" if dir.x < 0 else "ui_down" if dir.y > 0 else "ui_up"
	input.set_action(a, false)
	input.set_action(a, true)
	input.set_action(a, false)

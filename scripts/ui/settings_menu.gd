class_name SettingsMenu
extends Control
## Options written on a sheet: volumes, game feel, accessibility, language.

signal closed

var _panel: PaperPanel
var _first: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.03, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var vp := get_viewport_rect().size
	_panel = PaperPanel.new()
	_panel.size = Vector2(900, 900)
	_panel.position = (vp - _panel.size) * 0.5
	_panel.tilt_deg = 0.8
	_panel.set_margins(56)
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_panel.content.add_child(box)
	box.add_child(UiKit.title(tr("SETTINGS_TITLE"), 60))
	_section(box, tr("SETTINGS_SOUND"))
	_first = _slider(box, "SET_MASTER", "master")
	_slider(box, "SET_MUSIC", "music")
	_slider(box, "SET_SFX", "sfx")
	_section(box, tr("SETTINGS_FEEL"))
	_slider(box, "SET_SHAKE", "shake", 0.0, 1.5)
	_toggle(box, "SET_HITSTOP", "hitstop")
	_toggle(box, "SET_FLASHES", "flashes")
	_toggle(box, "SET_NUMBERS", "damage_numbers")
	_toggle(box, "SET_RUMBLE", "rumble")
	_section(box, tr("SETTINGS_DISPLAY"))
	_toggle(box, "SET_FULLSCREEN", "fullscreen")
	var lang := InkButton.new()
	lang.text = "%s: %s" % [tr("SET_LANGUAGE"), "Português (BR)" if Game.settings.language.begins_with("pt") else "English"]
	lang.font_size = 28
	lang.pressed.connect(func():
		Game.set_setting("language", "en" if Game.settings.language.begins_with("pt") else "pt_BR")
		lang.text = "%s: %s" % [tr("SET_LANGUAGE"), "Português (BR)" if Game.settings.language.begins_with("pt") else "English"])
	box.add_child(lang)
	var back := InkButton.new()
	back.text = tr("MENU_BACK")
	back.font_size = 32
	back.pressed.connect(close)
	box.add_child(back)
	UiKit.pop_in(_panel)
	_first.call_deferred("grab_focus")


func _section(box: VBoxContainer, text: String) -> void:
	var h := UiKit.heading(text, 22, Pal.WAX)
	box.add_child(h)


func _row(box: VBoxContainer, key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var l := UiKit.label(tr(key), UiFonts.body(), 28, Pal.INK)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	box.add_child(row)
	return row


func _slider(box: VBoxContainer, key: String, setting: String, lo := 0.0, hi := 1.0) -> Control:
	var row := _row(box, key)
	var s := InkControls.InkSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 0.05
	s.value = float(Game.settings.get(setting, 1.0))
	s.value_changed.connect(func(v): Game.set_setting(setting, v))
	row.add_child(s)
	return s


func _toggle(box: VBoxContainer, key: String, setting: String) -> void:
	var row := _row(box, key)
	var t := InkControls.InkToggle.new()
	t.button_pressed = bool(Game.settings.get(setting, true))
	t.toggled.connect(func(on): Game.set_setting(setting, on))
	row.add_child(t)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func close() -> void:
	closed.emit()
	UiKit.fade_out_free(self, 0.18)

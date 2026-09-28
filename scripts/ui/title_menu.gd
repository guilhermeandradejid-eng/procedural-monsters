class_name TitleMenu
extends Control
## Title screen: blackletter title, and the menu written on a torn strip.

signal play(input: PlayerInput)
signal settings
signal credits
signal quit

var _buttons: Array[InkButton] = []
var _last_device := "kbm"
var _t := 0.0
var _title: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_title = UiKit.label("Emberquill", UiFonts.display(800), 150, Pal.PAPER_LIGHT)
	_title.add_theme_color_override("font_outline_color", Pal.INK)
	_title.add_theme_constant_override("outline_size", 26)
	_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	_title.add_theme_constant_override("shadow_offset_x", 6)
	_title.add_theme_constant_override("shadow_offset_y", 10)
	_title.position = Vector2(120, 120)
	add_child(_title)
	var sub := UiKit.label(tr("GAME_SUBTITLE"), UiFonts.italic(), 40, Pal.GOLD_BRIGHT)
	sub.add_theme_color_override("font_outline_color", Pal.INK)
	sub.add_theme_constant_override("outline_size", 12)
	sub.position = Vector2(150, 300)
	add_child(sub)
	var flourish := Control.new()
	flourish.position = Vector2(140, 360)
	flourish.size = Vector2(600, 40)
	flourish.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flourish.draw.connect(func():
		Quill.stroke(flourish, GlyphArt._curve([Vector2(10, 20), Vector2(200, 8), Vector2(320, 26), Vector2(520, 14)], 12), 3.0, Pal.GOLD, 0.9)
		Quill.dot(flourish, Vector2(540, 14), 5.0, Pal.GOLD)
		Quill.dot(flourish, Vector2(0, 20), 4.0, Pal.GOLD))
	add_child(flourish)
	var strip := PaperPanel.new()
	strip.position = Vector2(150, 460)
	strip.size = Vector2(520, 420)
	strip.tilt_deg = -2.0
	strip.seed = 9.0
	strip.set_margins(46)
	add_child(strip)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	strip.content.add_child(box)
	for entry in [["TITLE_PLAY", "_on_play"], ["TITLE_SETTINGS", "_on_settings"], ["TITLE_CREDITS", "_on_credits"], ["TITLE_QUIT", "_on_quit"]]:
		var b := InkButton.new()
		b.text = tr(entry[0])
		b.font_size = 38
		b.pressed.connect(Callable(self, entry[1]))
		box.add_child(b)
		_buttons.append(b)
	for i in _buttons.size():
		var b := _buttons[i]
		b.focus_neighbor_top = _buttons[(i + _buttons.size() - 1) % _buttons.size()].get_path()
		b.focus_neighbor_bottom = _buttons[(i + 1) % _buttons.size()].get_path()
	var foot := UiKit.italic(tr("TITLE_FOOT"), 20, Pal.PAPER_DARK)
	foot.anchor_top = 1.0
	foot.anchor_bottom = 1.0
	foot.offset_left = 150
	foot.offset_right = 1350
	foot.offset_top = -60
	foot.offset_bottom = -30
	add_child(foot)
	UiKit.pop_in(strip, 0.25)
	_buttons[0].call_deferred("grab_focus")


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		_last_device = "pad%d" % event.device
	elif (event is InputEventKey or event is InputEventMouseButton) and event.pressed:
		_last_device = "kbm"


func _process(delta: float) -> void:
	_t += delta
	_title.position.y = 120 + sin(_t * 0.9) * 4.0


func _on_play() -> void:
	var input: PlayerInput
	if _last_device.begins_with("pad"):
		input = PlayerInput.new(PlayerInput.Kind.PAD, int(_last_device.substr(3)))
	else:
		input = PlayerInput.new(PlayerInput.Kind.KBM)
	play.emit(input)


func _on_settings() -> void:
	settings.emit()


func _on_credits() -> void:
	credits.emit()


func _on_quit() -> void:
	quit.emit()


func focus_first() -> void:
	_buttons[0].grab_focus()

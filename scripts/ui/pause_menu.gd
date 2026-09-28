class_name PauseMenu
extends Control
## A folded letter: resume, options, abandon the expedition, leave.
## Also lists each knight's controls for their own device.

signal resume
signal open_settings
signal abandon
signal to_title
signal quit_game

var in_run := false
var _first: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.03, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var vp := get_viewport_rect().size
	var letter := PaperPanel.new()
	letter.size = Vector2(620, 700)
	letter.position = Vector2(vp.x * 0.5 - 700, (vp.y - 700) * 0.5)
	letter.tilt_deg = -1.4
	letter.fold = 0.0
	letter.set_margins(56)
	add_child(letter)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	letter.content.add_child(box)
	box.add_child(UiKit.title(tr("PAUSE_TITLE"), 64))
	if Game.run:
		var info := UiKit.italic("%s · %s · %s" % [tr("CHAPTER_%d" % (Game.run.chapter + 1)), tr("PAGE_SHORT") % (Game.run.page + 1), _time(Game.run.time)], 22, Pal.INK_SOFT)
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(info)
	var entries := [["PAUSE_RESUME", resume], ["TITLE_SETTINGS", open_settings]]
	if in_run:
		entries.append(["PAUSE_ABANDON", abandon])
	entries.append_array([["PAUSE_TITLE_SCREEN", to_title], ["TITLE_QUIT", quit_game]])
	var buttons: Array[InkButton] = []
	for e in entries:
		var b := InkButton.new()
		b.text = tr(e[0])
		b.font_size = 34
		var sig: Signal = e[1]
		b.pressed.connect(func(): sig.emit())
		box.add_child(b)
		buttons.append(b)
	_first = buttons[0]
	var ctrl := PaperPanel.new()
	ctrl.size = Vector2(640, 640)
	ctrl.position = Vector2(vp.x * 0.5 + 40, (vp.y - 640) * 0.5 + 20)
	ctrl.tilt_deg = 1.2
	ctrl.set_margins(48)
	add_child(ctrl)
	var cbox := VBoxContainer.new()
	cbox.add_theme_constant_override("separation", 4)
	ctrl.content.add_child(cbox)
	cbox.add_child(UiKit.heading(tr("PAUSE_CONTROLS"), 24, Pal.WAX))
	var actions := ["attack", "spell_0", "spell_1", "spell_2", "dash", "interact", "grimoire"]
	for prof in Game.profiles:
		var t := InputGlyphs.table(prof.input)
		var lines: PackedStringArray = []
		for a in actions:
			lines.append("%s %s" % [t.get(a, "?"), tr("ACT_%s" % a.to_upper())])
		var who := UiKit.label("%s — %s" % [prof.display_name(), prof.input.label()], UiFonts.label(650), 22, prof.cloth_color().darkened(0.2))
		cbox.add_child(who)
		var l := UiKit.body("   ".join(lines), 19, Pal.INK_SOFT)
		cbox.add_child(l)
	if Game.profiles.is_empty():
		cbox.add_child(UiKit.body(tr("PAUSE_NO_PLAYERS"), 20, Pal.INK_SOFT))
	UiKit.pop_in(letter)
	UiKit.pop_in(ctrl, 0.08)
	_first.call_deferred("grab_focus")


func _time(t: float) -> String:
	return "%d:%02d" % [int(t / 60.0), int(t) % 60]


func focus_first() -> void:
	if _first:
		_first.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		resume.emit()
		get_viewport().set_input_as_handled()

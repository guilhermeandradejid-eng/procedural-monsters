class_name CreditsPanel
extends Control
## Colophon page, the way old books end.

signal closed


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.03, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var vp := get_viewport_rect().size
	var page := PaperPanel.new()
	page.size = Vector2(900, 760)
	page.position = (vp - page.size) * 0.5
	page.set_margins(64)
	add_child(page)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	page.content.add_child(box)
	box.add_child(UiKit.title(tr("CREDITS_TITLE"), 60))
	var body := UiKit.body(tr("CREDITS_BODY"), 24, Pal.INK_SOFT)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(body)
	var back := InkButton.new()
	back.text = tr("MENU_BACK")
	back.font_size = 32
	back.align_left = false
	back.pressed.connect(close)
	box.add_child(back)
	UiKit.pop_in(page)
	back.call_deferred("grab_focus")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func close() -> void:
	closed.emit()
	UiKit.fade_out_free(self, 0.18)

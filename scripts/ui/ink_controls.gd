class_name InkControls
extends RefCounted
## Inked settings widgets built on native controls (keyboard/pad focus works).


class InkSlider:
	extends HSlider

	var _focus := 0.0

	func _ready() -> void:
		custom_minimum_size = Vector2(320, 40)
		focus_mode = Control.FOCUS_ALL
		var empty := StyleBoxEmpty.new()
		for s in ["slider", "grabber_area", "grabber_area_highlight"]:
			add_theme_stylebox_override(s, empty)
		var img := Image.create(24, 36, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		var tex := ImageTexture.create_from_image(img)
		for s in ["grabber", "grabber_highlight", "grabber_disabled"]:
			add_theme_icon_override(s, tex)
		value_changed.connect(func(_v): queue_redraw())
		focus_entered.connect(func():
			_focus = 1.0
			queue_redraw())
		focus_exited.connect(func():
			_focus = 0.0
			queue_redraw())
		mouse_entered.connect(grab_focus)

	func _draw() -> void:
		var y := size.y * 0.5
		var x0 := 12.0
		var x1 := size.x - 12.0
		var f := (value - min_value) / maxf(max_value - min_value, 0.0001)
		var xv := lerpf(x0, x1, f)
		Quill.stroke(self, Quill.line_points(Vector2(x0, y), Vector2(x1, y), 16), 2.0, Color(Pal.INK, 0.45), 0.2, 0.5, 3)
		if xv > x0 + 1.0:
			Quill.stroke(self, Quill.line_points(Vector2(x0, y), Vector2(xv, y), 12), 5.0, Pal.WAX, 0.3, 0.5, 7)
		var nib := PackedVector2Array([Vector2(xv, y - 14), Vector2(xv + 7, y), Vector2(xv, y + 14), Vector2(xv - 7, y)])
		draw_colored_polygon(nib, Pal.INK if _focus < 0.5 else Pal.WAX_DARK)
		draw_line(Vector2(xv, y - 8), Vector2(xv, y + 8), Pal.GOLD, 1.4)


class InkToggle:
	extends Button

	func _ready() -> void:
		toggle_mode = true
		flat = true
		focus_mode = Control.FOCUS_ALL
		custom_minimum_size = Vector2(80, 40)
		var empty := StyleBoxEmpty.new()
		for s in ["normal", "hover", "pressed", "focus", "hover_pressed", "disabled"]:
			add_theme_stylebox_override(s, empty)
		toggled.connect(func(_on):
			Audio.ui("wax_seal", -8.0)
			queue_redraw())
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)
		mouse_entered.connect(grab_focus)

	func _draw() -> void:
		var c := Vector2(size.x - 24.0, size.y * 0.5)
		var pts := PackedVector2Array()
		for k in 18:
			var a := TAU * k / 18.0
			pts.append(c + Vector2(cos(a), sin(a)) * (14.0 + 1.5 * sin(a * 4.0)))
		if button_pressed:
			draw_colored_polygon(pts, Pal.WAX)
			draw_arc(c, 8.0, 0.0, TAU, 16, Pal.WAX_DARK, 2.0, true)
		draw_polyline(pts + PackedVector2Array([pts[0]]), Pal.INK if not has_focus() else Pal.WAX_DARK, 1.6 if not has_focus() else 2.6, true)

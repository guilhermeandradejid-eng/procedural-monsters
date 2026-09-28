class_name UiKit
extends RefCounted
## Small UI factory: labels in the house typography, ink colours and tweens.

const PARCHMENT := preload("res://shaders/ui/parchment.gdshader")


static func label(text: String, font: Font, size: int, color := Pal.INK, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func title(text: String, size := 56, color := Pal.INK) -> Label:
	return label(text, UiFonts.display(700), size, color, HORIZONTAL_ALIGNMENT_CENTER)


static func heading(text: String, size := 26, color := Pal.WAX) -> Label:
	var l := label(text.to_upper(), UiFonts.label(650), size, color)
	l.add_theme_constant_override("outline_size", 0)
	return l


static func body(text: String, size := 24, color := Pal.INK) -> Label:
	var l := label(text, UiFonts.body(), size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func italic(text: String, size := 22, color := Pal.INK_SOFT) -> Label:
	var l := label(text, UiFonts.italic(), size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func parchment_material(size: Vector2, seed := 0.0, burn := 0.45, deckle := 9.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = PARCHMENT
	m.set_shader_parameter("size", size)
	m.set_shader_parameter("seed", seed)
	m.set_shader_parameter("burn", burn)
	m.set_shader_parameter("deckle", deckle)
	return m


## Pops a control in with a slight overshoot and rotation settle.
static func pop_in(c: Control, delay := 0.0, from_scale := 0.85) -> void:
	c.pivot_offset = c.size * 0.5
	c.scale = Vector2.ONE * from_scale
	c.modulate.a = 0.0
	var t := c.create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_interval(delay)
	t.set_parallel(true)
	t.tween_property(c, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(c, "modulate:a", 1.0, 0.18)


static func fade_out_free(c: Control, duration := 0.2) -> void:
	var t := c.create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.set_parallel(true)
	t.tween_property(c, "modulate:a", 0.0, duration)
	t.tween_property(c, "scale", Vector2.ONE * 0.94, duration)
	t.chain().tween_callback(c.queue_free)


## Per-player screen region for simultaneous panels (1: centre, 2: halves, 3-4: quadrants).
static func player_region(vp: Vector2, index: int, count: int) -> Rect2:
	if count <= 1:
		return Rect2(Vector2.ZERO, vp)
	if count == 2:
		return Rect2(Vector2(vp.x * 0.5 * (index % 2), 0), Vector2(vp.x * 0.5, vp.y))
	return Rect2(Vector2(vp.x * 0.5 * (index % 2), vp.y * 0.5 * int(index / 2)), vp * 0.5)


## Anchors `c` to the top centre of its parent with a fixed size.
static func anchor_top_center(c: Control, w: float, h: float, top: float) -> void:
	c.anchor_left = 0.5
	c.anchor_right = 0.5
	c.anchor_top = 0.0
	c.anchor_bottom = 0.0
	c.offset_left = -w * 0.5
	c.offset_right = w * 0.5
	c.offset_top = top
	c.offset_bottom = top + h

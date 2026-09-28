class_name InkButton
extends Button
## A menu entry written in ink. Focus/hover draws a quill underline that
## grows from the left and a small ink bullet; pressing blots it.

@export var font_size := 34
@export var ink := Color("1c1411")
@export var accent := Color("9e2b25")
@export var align_left := true

var _t := 0.0
var _target := 0.0
var _press := 0.0


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	add_theme_font_override("font", UiFonts.body())
	add_theme_font_size_override("font_size", font_size)
	for st in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		add_theme_color_override(st, ink)
	add_theme_color_override("font_disabled_color", Color(ink, 0.35))
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		add_theme_stylebox_override(st, empty)
	alignment = HORIZONTAL_ALIGNMENT_LEFT if align_left else HORIZONTAL_ALIGNMENT_CENTER
	mouse_entered.connect(func(): grab_focus())
	focus_entered.connect(func():
		_target = 1.0
		Audio.ui("ui_hover", -14.0, randf_range(0.95, 1.08)))
	focus_exited.connect(func(): _target = 0.0)
	pressed.connect(func():
		_press = 1.0
		Audio.ui("ui_click", -6.0))
	custom_minimum_size.y = font_size * 1.5


func _process(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, 0.001)
	var prev := _t
	_t = move_toward(_t, _target, real * 5.0)
	_press = maxf(0.0, _press - real * 3.0)
	if not is_equal_approx(prev, _t) or _press > 0.0:
		queue_redraw()


func _draw() -> void:
	if _t <= 0.001:
		return
	var font := get_theme_font("font")
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var x0 := 0.0 if align_left else (size.x - w) * 0.5
	var y := size.y * 0.5 + font_size * 0.42
	var e := ease(_t, 0.4)
	var pts := PackedVector2Array()
	var n := 14
	for i in n + 1:
		var f := float(i) / n
		pts.append(Vector2(x0 + (w + 18.0) * f * e, y + sin(f * 5.0 + 1.3) * 1.6))
	Quill.stroke(self, pts, 3.0, accent, 0.9, 0.0)
	Quill.dot(self, Vector2(x0 - 16.0, size.y * 0.5 + 2.0), 4.5 * e + _press * 3.0, accent)

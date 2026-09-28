class_name PaperPanel
extends Control
## A sheet of parchment with a hand-inked double rule and corner flourishes.
## Children are laid out inside `content` (a MarginContainer).

@export var seed := 0.0
@export var burn := 0.45
@export var frame := true
@export var frame_color := Color("3a2a22")
@export var tilt_deg := 0.0
@export var fold := 0.0

var content: MarginContainer
var _paper: Control
var _ink: Control


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_paper = Control.new()
	_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_paper.draw.connect(func(): _paper.draw_rect(Rect2(Vector2.ZERO, _paper.size), Color.WHITE))
	add_child(_paper)
	_ink = Control.new()
	_ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ink.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ink.draw.connect(_draw_frame)
	add_child(_ink)
	content = MarginContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		content.add_theme_constant_override("margin_" + side, 34)
	add_child(content)


func _ready() -> void:
	if seed == 0.0:
		seed = randf() * 100.0
	_paper.material = UiKit.parchment_material(size, seed, burn)
	_paper.material.set_shader_parameter("fold", fold)
	rotation = deg_to_rad(tilt_deg)
	resized.connect(_on_resized)
	_on_resized()


func _on_resized() -> void:
	pivot_offset = size * 0.5
	if _paper.material:
		_paper.material.set_shader_parameter("size", size)
	_paper.queue_redraw()
	_ink.queue_redraw()


func set_margins(m: int) -> void:
	for side in ["left", "right", "top", "bottom"]:
		content.add_theme_constant_override("margin_" + side, m)


func _draw_frame() -> void:
	if not frame:
		return
	var r := Rect2(Vector2.ZERO, size).grow(-16.0)
	var r2 := r.grow(-6.0)
	var s := int(seed * 10.0)
	_rect_stroke(r, 2.2, frame_color, s)
	_rect_stroke(r2, 1.0, Color(frame_color, 0.7), s + 7)
	for c in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		var inward: Vector2 = (r.get_center() - c).sign()
		var p: Vector2 = c + inward * 3.0
		Quill.stroke(_ink, GlyphArt._curve([p + Vector2(inward.x * 26, 0), p + inward * 9.0, p + Vector2(0, inward.y * 26)], 6), 2.0, frame_color, 0.8)
		Quill.dot(_ink, c + inward * 12.0, 2.4, frame_color)


func _rect_stroke(r: Rect2, w: float, col: Color, s: int) -> void:
	var pts := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
	for i in 4:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var seg := Quill.line_points(a, b, maxi(4, int(a.distance_to(b) / 24.0)))
		Quill.stroke(_ink, seg, w, col, 0.25, 0.6, s + i * 31)

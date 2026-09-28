class_name BossBar
extends Control
## The boss's name in blackletter over a parchment strip that drains like
## ink soaking back into the page. Notches mark the phase thresholds.

var boss: Node3D
var _shown := 1.0
var _lag := 1.0
var _paper: Control


func _ready() -> void:
	UiKit.anchor_top_center(self, 900, 110, 64)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper = Control.new()
	_paper.show_behind_parent = true
	_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper.position = Vector2(20, 52)
	_paper.size = Vector2(860, 44)
	_paper.material = UiKit.parchment_material(_paper.size, 5.0, 0.6, 5.0)
	_paper.draw.connect(func(): _paper.draw_rect(Rect2(Vector2.ZERO, _paper.size), Color.WHITE))
	add_child(_paper)


func track(b: Node3D) -> void:
	boss = b
	_shown = 1.0
	_lag = 1.0
	visible = true
	UiKit.pop_in(self)


func _process(delta: float) -> void:
	if boss == null or not is_instance_valid(boss):
		return
	var r: float = boss.hp_ratio()
	var real := delta / maxf(Engine.time_scale, 0.001)
	_shown = lerpf(_shown, r, 1.0 - exp(-real * 12.0))
	_lag = lerpf(_lag, _shown, 1.0 - exp(-real * 2.0))
	queue_redraw()


func _draw() -> void:
	if boss == null or not is_instance_valid(boss):
		return
	var name_txt: String = boss.display_name() if boss.has_method("display_name") else "?"
	var f := UiFonts.display(700)
	var w := f.get_string_size(name_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 46).x
	draw_string_outline(f, Vector2((size.x - w) * 0.5, 44), name_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 46, 12, Pal.INK)
	draw_string(f, Vector2((size.x - w) * 0.5, 44), name_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 46, Pal.PAPER_LIGHT)
	var bar := Rect2(34, 62, 832, 24)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * _lag, bar.size.y)), Color(Pal.WAX_LIGHT, 0.55))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * _shown, bar.size.y)), Pal.WAX)
	for k in 12:
		var x := bar.position.x + bar.size.x * _shown - k * 3.0
		if x > bar.position.x:
			draw_line(Vector2(x, bar.position.y + randf() * 4.0), Vector2(x, bar.end.y - randf() * 4.0), Color(Pal.WAX_DARK, 0.25), 1.0)
	for th in [0.66, 0.33]:
		var x2: float = bar.position.x + bar.size.x * th
		Quill.stroke(self, PackedVector2Array([Vector2(x2, bar.position.y - 6), Vector2(x2, bar.end.y + 6)]), 2.4, Pal.INK, 0.5)
	Quill.stroke(self, PackedVector2Array([bar.position, Vector2(bar.end.x, bar.position.y), bar.end, Vector2(bar.position.x, bar.end.y), bar.position]), 2.0, Pal.INK, 0.0)

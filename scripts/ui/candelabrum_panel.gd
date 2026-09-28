class_name CandelabrumPanel
extends Control
## Permanent upgrades bought with Embers. Each level lights one candle.

signal closed

const DESIGN := Vector2(1000, 820)

var player: Player
var input: PlayerInput
var cursor := 0
var _panel: PaperPanel
var _rows: Array[Control] = []
var _embers: Label
var _desc: Label
var _closing := false


func setup(p: Player, region: Rect2) -> void:
	player = p
	input = p.input
	size = DESIGN
	var s := minf(minf(region.size.x / DESIGN.x, region.size.y / DESIGN.y) * 0.95, 1.0)
	scale = Vector2.ONE * s
	position = region.position + (region.size - DESIGN * s) * 0.5


func _ready() -> void:
	_panel = PaperPanel.new()
	_panel.size = DESIGN
	_panel.seed = 41.0
	_panel.set_margins(48)
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_panel.content.add_child(box)
	box.add_child(UiKit.title(tr("STATION_CANDELABRUM"), 58))
	_embers = UiKit.label("", UiFonts.numbers(), 30, Pal.EMBER.darkened(0.3), HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_embers)
	for id in Upgrades.ORDER:
		var row := Control.new()
		row.custom_minimum_size = Vector2(880, 62)
		row.draw.connect(_draw_row.bind(row, id))
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		var idx := _rows.size()
		row.gui_input.connect(func(e):
			if not input.uses_mouse():
				return
			if e is InputEventMouseMotion:
				cursor = idx
				_refresh()
			elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				cursor = idx
				_buy())
		box.add_child(row)
		_rows.append(row)
	_desc = UiKit.italic("", 22, Pal.INK_SOFT)
	_desc.custom_minimum_size = Vector2(880, 60)
	_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_desc)
	input.clear_buffer()
	UiKit.pop_in(self)
	_refresh()


func _refresh() -> void:
	_embers.text = "%s  %d" % [tr("EMBERS"), int(Game.meta.embers)]
	_desc.text = Upgrades.desc(Upgrades.ORDER[cursor])
	for r in _rows:
		r.queue_redraw()


func _draw_row(row: Control, id: String) -> void:
	var sel: bool = Upgrades.ORDER[cursor] == id
	if sel:
		Quill.stroke(row, Quill.line_points(Vector2(0, 58), Vector2(row.size.x, 58), 20), 2.0, Pal.WAX, 0.8, 0.8, 3)
		Quill.dot(row, Vector2(-14, 32), 5.0, Pal.WAX)
	row.draw_string(UiFonts.body(), Vector2(8, 42), Upgrades.title(id), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Pal.INK)
	var lv := Upgrades.level(id)
	var mx: int = Upgrades.LIST[id].max
	for k in mx:
		var p := Vector2(470 + k * 34, 46)
		row.draw_rect(Rect2(p + Vector2(-6, -24), Vector2(12, 24)), Pal.PAPER_LIGHT if k < lv else Color(Pal.INK, 0.12))
		row.draw_rect(Rect2(p + Vector2(-6, -24), Vector2(12, 24)), Color(Pal.INK, 0.6), false, 1.2)
		if k < lv:
			row.draw_colored_polygon(PackedVector2Array([p + Vector2(-5, -28), p + Vector2(0, -44), p + Vector2(5, -28)]), Pal.EMBER)
	var cost := Upgrades.next_cost(id)
	var txt := tr("UPGRADE_MAX") if cost < 0 else "%d" % cost
	var col := Pal.INK_FADED if cost < 0 else (Pal.INK if int(Game.meta.embers) >= cost else Pal.WAX)
	row.draw_string(UiFonts.numbers(), Vector2(780, 42), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, col)


func _process(_delta: float) -> void:
	if _closing:
		return
	if input.consume("ui_up", 200):
		cursor = (cursor + Upgrades.ORDER.size() - 1) % Upgrades.ORDER.size()
		Audio.ui("ui_tick", -12.0)
		_refresh()
	if input.consume("ui_down", 200):
		cursor = (cursor + 1) % Upgrades.ORDER.size()
		Audio.ui("ui_tick", -12.0)
		_refresh()
	if input.consume("ui_accept"):
		_buy()
	if input.consume("ui_back") or input.consume("pause") or input.consume("interact"):
		close()


func _buy() -> void:
	var id: String = Upgrades.ORDER[cursor]
	if Upgrades.buy(id):
		Audio.ui("upgrade", -2.0)
		for p in Game.profiles:
			p.reset_for_run(Game.meta)
			if p.actor:
				p.actor.max_hp = p.stat("max_hp")
				p.actor.hp = p.hp
	else:
		Audio.ui("fizzle", -4.0)
	_refresh()


func close() -> void:
	if _closing:
		return
	_closing = true
	input.clear_buffer()
	closed.emit()
	UiKit.fade_out_free(self, 0.2)

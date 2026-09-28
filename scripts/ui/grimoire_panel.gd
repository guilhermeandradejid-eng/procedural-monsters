class_name GrimoirePanel
extends Control
## The open grimoire. Left page: loose glyphs (the satchel) and the glyph
## under the quill. Right page: the chosen spell page written as a sentence,
## its generated name, the full sentence, grammar notes, stats and sigil.
## Driven by the owner's own device (pads/keyboard) or the mouse.

signal closed

const DESIGN := Vector2(1500, 860)
const LP := Rect2(40, 34, 700, 796)
const RP := Rect2(760, 34, 700, 796)
const TILE := 82.0
const GAP := 14.0
const COLS := 6
const ROWS := 4

var player: Player
var profile: PlayerProfile
var input: PlayerInput
var grim: Grimoire
var page := 0
var zone := "satchel"
var cursor := 0
var scroll := 0
var carry := ""
var carry_from := {}
var _sigil_t := 1.0
var _t := 0.0
var _canvas: Control
var _name: Label
var _sentence: Label
var _notes: Label
var _stats: Label
var _desc_name: Label
var _desc_type: Label
var _desc_body: Label
var _hints: Label
var _page_title: Label
var _sigil_spec := {}
var _closing := false


func setup(p: Player, region: Rect2) -> void:
	player = p
	profile = p.profile
	input = p.input
	grim = profile.grimoire
	var s := minf(region.size.x / DESIGN.x, region.size.y / DESIGN.y) * 0.96
	size = DESIGN
	scale = Vector2.ONE * s
	position = region.position + (region.size - DESIGN * s) * 0.5


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var cover := Control.new()
	cover.size = DESIGN
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.draw.connect(_draw_cover.bind(cover))
	add_child(cover)
	for r in [LP, RP]:
		var pg := Control.new()
		pg.position = r.position
		pg.size = r.size
		pg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var m := UiKit.parchment_material(r.size, 3.0 + r.position.x * 0.01, 0.35, 4.0)
		m.set_shader_parameter("fold", 0.0)
		pg.material = m
		pg.draw.connect(func(): pg.draw_rect(Rect2(Vector2.ZERO, pg.size), Color.WHITE))
		add_child(pg)
	var gutter := Control.new()
	gutter.size = DESIGN
	gutter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gutter.draw.connect(func():
		for k in 18:
			var a := 0.2 * (1.0 - k / 18.0)
			gutter.draw_rect(Rect2(750 - k * 3.0, 34, 3.0, 796), Color(0.2, 0.12, 0.08, a * 0.5))
			gutter.draw_rect(Rect2(750 + k * 3.0, 34, 3.0, 796), Color(0.2, 0.12, 0.08, a * 0.5)))
	add_child(gutter)
	_build_texts()
	_canvas = Control.new()
	_canvas.size = DESIGN
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_canvas)
	add_child(_canvas)
	grim.changed.connect(_on_changed)
	input.clear_buffer()
	_refresh()
	pivot_offset = DESIGN * 0.5
	var t := create_tween()
	var target_scale := scale
	scale = target_scale * Vector2(0.05, 1.0)
	modulate.a = 0.0
	t.set_parallel(true)
	t.tween_property(self, "scale", target_scale, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "modulate:a", 1.0, 0.15)
	Audio.ui("book_open", -2.0)


func _build_texts() -> void:
	var legend := UiKit.heading(tr("GRIMOIRE_SATCHEL"), 24, Pal.WAX)
	legend.position = LP.position + Vector2(40, 38)
	add_child(legend)
	_desc_name = UiKit.label("", UiFonts.display(700), 40, Pal.INK)
	_desc_name.position = LP.position + Vector2(150, 548)
	_desc_name.size = Vector2(500, 50)
	add_child(_desc_name)
	_desc_type = UiKit.label("", UiFonts.label(650), 18, Pal.WAX)
	_desc_type.position = LP.position + Vector2(152, 598)
	add_child(_desc_type)
	_desc_body = UiKit.body("", 23, Pal.INK_SOFT)
	_desc_body.position = LP.position + Vector2(40, 640)
	_desc_body.size = Vector2(620, 90)
	add_child(_desc_body)
	_hints = UiKit.italic("", 18, Pal.INK_FADED)
	_hints.position = LP.position + Vector2(40, 748)
	_hints.size = Vector2(620, 40)
	add_child(_hints)
	_page_title = UiKit.heading("", 22, Pal.WAX)
	_page_title.position = RP.position + Vector2(270, 44)
	add_child(_page_title)
	_name = UiKit.label("", UiFonts.display(700), 46, Pal.INK)
	_name.position = RP.position + Vector2(40, 84)
	_name.size = Vector2(620, 110)
	_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_name)
	_sentence = UiKit.italic("", 24, Pal.INK_SOFT)
	_sentence.position = RP.position + Vector2(40, 360)
	_sentence.size = Vector2(620, 110)
	add_child(_sentence)
	_notes = UiKit.italic("", 19, Pal.WAX)
	_notes.position = RP.position + Vector2(40, 470)
	_notes.size = Vector2(620, 60)
	add_child(_notes)
	_stats = UiKit.body("", 22, Pal.INK)
	_stats.position = RP.position + Vector2(40, 560)
	_stats.size = Vector2(330, 200)
	add_child(_stats)


# --- geometry -------------------------------------------------------------------------
func _satchel_rect(i: int) -> Rect2:
	var local := i - scroll * COLS
	var col := local % COLS
	var row := int(local / COLS)
	return Rect2(LP.position + Vector2(40 + col * (TILE + GAP), 96 + row * (TILE + GAP)), Vector2(TILE, TILE))


func _slot_rect(j: int) -> Rect2:
	var cap := grim.capacity(page)
	var span := 620.0
	var step := span / cap
	var x := RP.position.x + 40 + step * (j + 0.5)
	var y := RP.position.y + 262 + sin(j * 1.3) * 4.0
	var sz := minf(TILE, step - 8.0)
	return Rect2(Vector2(x - sz * 0.5, y - sz * 0.5), Vector2(sz, sz))


func _visible_satchel() -> int:
	return mini(grim.satchel.size() - scroll * COLS, COLS * ROWS)


# --- input ----------------------------------------------------------------------------
func _process(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, 0.001)
	_t += real
	_sigil_t = minf(1.0, _sigil_t + real * 1.6)
	if _closing:
		return
	if input.consume("ui_back") or input.consume("grimoire") or input.consume("pause"):
		if carry != "":
			_cancel_carry()
		else:
			close()
		return
	if input.consume("ui_prev"):
		_set_page((page + 2) % 3)
	if input.consume("ui_next"):
		_set_page((page + 1) % 3)
	if input.consume("ui_left", 200):
		_move(-1, 0)
	if input.consume("ui_right", 200):
		_move(1, 0)
	if input.consume("ui_up", 200):
		_move(0, -1)
	if input.consume("ui_down", 200):
		_move(0, 1)
	if input.consume("ui_accept"):
		_activate()
	if input.consume("ui_alt"):
		_remove_at_cursor()
	_canvas.queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not input.uses_mouse() or _closing:
		return
	if event is InputEventMouseMotion:
		_hover_at(event.position)
	elif event is InputEventMouseButton and event.pressed:
		_hover_at(event.position)
		if event.button_index == MOUSE_BUTTON_LEFT:
			_activate()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if carry != "":
				_cancel_carry()
			else:
				_remove_at_cursor()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll = maxi(0, scroll - 1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll = mini(scroll + 1, maxi(0, int(ceil(grim.satchel.size() / float(COLS))) - ROWS))
		accept_event()
	# Clicks on the page ribbons.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in 3:
			if _tab_rect(i).has_point(event.position):
				_set_page(i)


func _hover_at(p: Vector2) -> void:
	for i in _visible_satchel():
		var idx := i + scroll * COLS
		if _satchel_rect(idx).has_point(p):
			if zone != "satchel" or cursor != idx:
				zone = "satchel"
				cursor = idx
				_refresh_desc()
			return
	for j in grim.capacity(page):
		if _slot_rect(j).grow(6).has_point(p):
			if zone != "slots" or cursor != j:
				zone = "slots"
				cursor = j
				_refresh_desc()
			return


func _move(dx: int, dy: int) -> void:
	Audio.ui("ui_tick", -16.0, randf_range(0.95, 1.1))
	if zone == "satchel":
		var n := grim.satchel.size()
		var col := cursor % COLS
		var row := int(cursor / COLS)
		if dx > 0 and (col == COLS - 1 or cursor + 1 >= n):
			zone = "slots"
			cursor = 0
		elif dx < 0 and col == 0:
			zone = "slots"
			cursor = grim.capacity(page) - 1
		else:
			var nc := clampi(col + dx, 0, COLS - 1)
			var nr := maxi(0, row + dy)
			var idx := nr * COLS + nc
			if n > 0:
				cursor = clampi(idx, 0, n - 1)
			if int(cursor / COLS) < scroll:
				scroll = int(cursor / COLS)
			elif int(cursor / COLS) >= scroll + ROWS:
				scroll = int(cursor / COLS) - ROWS + 1
	else:
		var cap := grim.capacity(page)
		if dy != 0:
			_set_page((page + (1 if dy > 0 else 2)) % 3)
			return
		var nj := cursor + dx
		if nj < 0 or nj >= cap:
			zone = "satchel"
			cursor = mini(maxi(0, grim.satchel.size() - 1), scroll * COLS + (COLS - 1 if nj < 0 else 0))
		else:
			cursor = nj
	_refresh_desc()


func _activate() -> void:
	if zone == "satchel":
		if carry != "":
			if carry_from.zone == "slot":
				grim.lift_to_satchel(carry_from.page, carry_from.index)
				Audio.ui("glyph_lift", -6.0)
			carry = ""
			carry_from = {}
			return
		if cursor < grim.satchel.size():
			carry = grim.satchel[cursor]
			carry_from = {"zone": "satchel", "index": cursor}
			Audio.ui("glyph_pick", -6.0)
	else:
		var j := cursor
		if carry != "":
			if carry_from.zone == "satchel":
				grim.place_from_satchel(carry_from.index, page, j)
			else:
				grim.swap_slots(carry_from.page, carry_from.index, page, j)
			carry = ""
			carry_from = {}
			_sigil_t = 0.0
			Audio.ui("quill_write", -4.0, randf_range(0.95, 1.08))
			Audio.ui("glyph_place", -4.0)
		elif grim.slot(page, j) != "":
			carry = grim.slot(page, j)
			carry_from = {"zone": "slot", "index": j, "page": page}
			Audio.ui("glyph_pick", -6.0)
	_refresh()


func _remove_at_cursor() -> void:
	if zone == "slots" and grim.slot(page, cursor) != "":
		grim.lift_to_satchel(page, cursor)
		_sigil_t = 0.0
		Audio.ui("glyph_lift", -4.0)
		_refresh()


func _cancel_carry() -> void:
	carry = ""
	carry_from = {}
	Audio.ui("ui_back", -8.0)


func _set_page(p: int) -> void:
	if p == page:
		return
	# A carried glyph may travel to another page (swap_slots handles cross-page moves).
	page = p
	if zone == "slots":
		cursor = mini(cursor, grim.capacity(page) - 1)
	_sigil_t = 0.0
	Audio.ui("page_flip", -4.0, randf_range(0.95, 1.1))
	_refresh()


func _on_changed(_p: int) -> void:
	_refresh()


func close() -> void:
	if _closing:
		return
	_closing = true
	input.clear_buffer()
	Audio.ui("book_close", -2.0)
	closed.emit()
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(self, "scale", scale * Vector2(0.05, 1.0), 0.2).set_ease(Tween.EASE_IN)
	t.tween_property(self, "modulate:a", 0.0, 0.2)
	t.chain().tween_callback(queue_free)


# --- text refresh -----------------------------------------------------------------------
func _refresh() -> void:
	if grim.satchel.size() > 0 and zone == "satchel":
		cursor = clampi(cursor, 0, grim.satchel.size() - 1)
	var prog := grim.program(page)
	_page_title.text = "%s %s" % [tr("GRIMOIRE_PAGE"), ["I", "II", "III"][page]]
	_name.text = prog.display_name()
	_sentence.text = prog.sentence()
	var notes: PackedStringArray = []
	for n in prog.notes:
		notes.append("※ " + tr("NOTE_%s" % String(n.kind).to_upper()))
	_notes.text = "  ".join(notes)
	var el := prog.element()
	var stats := "%s  %.1f s\n%s  ~%d\n%s  %s" % [tr("STAT_COOLDOWN"), prog.cooldown * profile.stat("haste"), tr("STAT_DAMAGE"), int(prog.estimate_damage() * profile.stat("might")), tr("STAT_ESSENCE"), Elem.display_name(el)]
	if Elem.is_fusion(el):
		var parts := Elem.parts_of(el)
		stats += "\n(%s + %s)\n%s" % [Elem.display_name(parts[0]), Elem.display_name(parts[1]), tr("E_%s_DESC" % el.to_upper())]
	stats += "\n%s  %d / %d" % [tr("STAT_SLOTS"), _filled(page), grim.capacity(page)]
	_stats.text = stats
	_sigil_spec = SigilArt.spec(prog)
	_hints.text = _hint_text()
	_refresh_desc()


func _filled(p: int) -> int:
	var n := 0
	for g in grim.pages[p]:
		if g != "":
			n += 1
	return n


func _hint_text() -> String:
	var t := InputGlyphs.table(input)
	return "%s %s   %s %s   %s/%s %s   %s %s" % [t.ui_accept, tr("HINT_TAKE"), t.ui_alt, tr("HINT_RETURN"), t.ui_prev, t.ui_next, tr("HINT_PAGE"), t.ui_back, tr("HINT_CLOSE")]


func _refresh_desc() -> void:
	var id := carry
	if id == "":
		if zone == "satchel" and cursor < grim.satchel.size():
			id = grim.satchel[cursor]
		elif zone == "slots":
			id = grim.slot(page, cursor)
	if id == "":
		_desc_name.text = ""
		_desc_type.text = ""
		_desc_body.text = tr("GRIMOIRE_EMPTY_HINT")
		return
	var t := GlyphDB.type_of(id)
	_desc_name.text = GlyphDB.glyph_name(id)
	_desc_type.text = "%s — %s" % [GlyphDB.type_name(t).to_upper(), tr(["GT_FORM_HINT", "GT_ESSENCE_HINT", "GT_INFLECTION_HINT", "GT_LINK_HINT"][t])]
	_desc_body.text = GlyphDB.glyph_desc(id)


# --- drawing ----------------------------------------------------------------------------
func _draw_cover(c: Control) -> void:
	var col := profile.cloth_color().darkened(0.45)
	var r := Rect2(Vector2(8, 8), DESIGN - Vector2(16, 16))
	c.draw_rect(r.grow(8), Color(0, 0, 0, 0.35))
	c.draw_rect(r, col)
	c.draw_rect(Rect2(r.position + Vector2(6, 6), r.size - Vector2(12, 12)), col.darkened(0.2), false, 2.0)
	for k in 3:
		Quill.stroke(c, Quill.line_points(r.position + Vector2(20 + k * 6, r.size.y - 12), Vector2(r.end.x - 20 - k * 6, r.end.y - 12), 12), 1.2, Color(Pal.GOLD, 0.5), 0.0)
	# Page-block edges peeking below each page.
	for pr in [LP, RP]:
		for k in 3:
			c.draw_rect(Rect2(pr.position + Vector2(k * 2 + 4, pr.size.y + k * 3), Vector2(pr.size.x - k * 4 - 8, 3)), Pal.PAPER_DARK.darkened(0.08 * k))


func _tab_rect(i: int) -> Rect2:
	return Rect2(RP.position + Vector2(40 + i * 72, -22), Vector2(56, 70 + (22 if i == page else 0)))


func _draw_canvas() -> void:
	var ci := _canvas
	# Ribbon bookmarks for the three pages.
	for i in 3:
		var r := _tab_rect(i)
		var col := profile.cloth_color() if i == page else profile.cloth_color().darkened(0.35)
		var pts := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.get_center().x, r.end.y - 14), Vector2(r.position.x, r.end.y)])
		ci.draw_colored_polygon(pts, col)
		ci.draw_polyline(pts + PackedVector2Array([pts[0]]), Color(Pal.INK, 0.5), 1.2, true)
		var numeral: String = ["I", "II", "III"][i]
		var f := UiFonts.display(700)
		var w := f.get_string_size(numeral, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
		ci.draw_string(f, Vector2(r.get_center().x - w * 0.5, r.position.y + 50), numeral, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Pal.PAPER_LIGHT)
	# Grammar legend.
	var lx := LP.position.x + 250.0
	for t in 4:
		var mark := PackedVector2Array([Vector2(lx, LP.position.y + 40), Vector2(lx + 14, LP.position.y + 40), Vector2(lx, LP.position.y + 54)])
		ci.draw_colored_polygon(mark, GlyphTile._type_mark(t))
		ci.draw_string(UiFonts.italic(), Vector2(lx + 18, LP.position.y + 55), GlyphDB.type_name(t), HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Pal.INK_SOFT)
		lx += 108.0
	# Satchel grid.
	var n := grim.satchel.size()
	for i in _visible_satchel():
		var idx := i + scroll * COLS
		var r := _satchel_rect(idx)
		var state := ""
		if carry != "" and carry_from.get("zone") == "satchel" and carry_from.index == idx:
			state = "ghost"
		elif zone == "satchel" and cursor == idx:
			state = "hover"
		GlyphTile.draw(ci, r, grim.satchel[idx], state)
	if n == 0:
		ci.draw_string(UiFonts.italic(), LP.position + Vector2(44, 150), tr("GRIMOIRE_SATCHEL_EMPTY"), HORIZONTAL_ALIGNMENT_LEFT, 600, 22, Pal.INK_FADED)
	if n > COLS * ROWS:
		var more := "%d / %d" % [scroll + 1, int(ceil(n / float(COLS))) - ROWS + 1]
		ci.draw_string(UiFonts.label(600), LP.position + Vector2(600, 480), more, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Pal.INK_FADED)
	# Big glyph under the description.
	var did := carry
	if did == "":
		if zone == "satchel" and cursor < n:
			did = grim.satchel[cursor]
		elif zone == "slots":
			did = grim.slot(page, cursor)
	if did != "":
		GlyphTile.draw(ci, Rect2(LP.position + Vector2(40, 540), Vector2(96, 96)), did, "", 1.2)
	Quill.stroke(ci, Quill.line_points(LP.position + Vector2(40, 526), LP.position + Vector2(660, 526), 16), 1.4, Color(Pal.INK, 0.4), 0.9, 0.8, 5)
	# The sentence line: ruled baseline, clause arcs, slots.
	var prog := grim.program(page)
	var base_y := RP.position.y + 262 + 50
	Quill.stroke(ci, Quill.line_points(Vector2(RP.position.x + 30, base_y), Vector2(RP.end.x - 30, base_y), 20), 1.6, Color(Pal.INK, 0.55), 0.6, 1.0, 11)
	var clause_cols := [Pal.INK, Pal.WAX, Color("2d6f91"), Color("6a4a14")]
	var cls := prog.clauses()
	for ci_idx in cls.size():
		var c: SpellClause = cls[ci_idx]
		if c.glyph_indices.is_empty():
			continue
		var a := _slot_rect(c.glyph_indices[0]).get_center()
		var b := _slot_rect(c.glyph_indices[-1]).get_center()
		var y := base_y + 14 + ci_idx * 6
		Quill.stroke(ci, GlyphArt._curve([Vector2(a.x - 30, y), Vector2((a.x + b.x) * 0.5, y + 10), Vector2(b.x + 30, y)], 8), 2.2, Color(clause_cols[ci_idx % 4], 0.8), 0.8)
	var cap := grim.capacity(page)
	for j in cap:
		var r := _slot_rect(j)
		var id := grim.slot(page, j)
		var hl := zone == "slots" and cursor == j
		if id == "" or (carry != "" and carry_from.get("zone") == "slot" and carry_from.page == page and carry_from.index == j):
			GlyphTile.draw_slot(ci, r, hl)
			if id != "":
				GlyphTile.draw(ci, r, id, "ghost")
		else:
			GlyphTile.draw(ci, r, id, "hover" if hl else "")
		if GlyphDB.type_of(id) == GlyphDB.Type.LINK:
			var p := r.get_center() + Vector2(r.size.x * 0.5 + 2, 0)
			Quill.stroke(ci, PackedVector2Array([p, p + Vector2(8, 0)]), 2.0, Pal.WAX, 0.2)
	# Sigil, written progressively when the page changes.
	if not prog.empty:
		SigilArt.draw(ci, _sigil_spec, RP.position + Vector2(530, 650), 122.0, Color(Pal.INK, 0.85), ease(_sigil_t, 0.5), 2.2)
	else:
		ci.draw_string(UiFonts.italic(), RP.position + Vector2(420, 660), tr("SPELL_BLANK_SENTENCE"), HORIZONTAL_ALIGNMENT_LEFT, 240, 20, Pal.INK_FADED)
	# Cursor: an inked quill pointing at the focused cell, and the carried glyph.
	var focus_r := _satchel_rect(cursor) if zone == "satchel" else _slot_rect(cursor)
	var bob := sin(_t * 6.0) * 4.0
	var tip := focus_r.position + Vector2(focus_r.size.x * 0.8, -6 + bob)
	Quill.stroke(ci, PackedVector2Array([tip, tip + Vector2(34, -40)]), 5.0, Pal.INK, 0.9)
	Quill.stroke(ci, GlyphArt._curve([tip + Vector2(12, -14), tip + Vector2(42, -30), tip + Vector2(50, -58)], 6), 3.0, Color(Pal.INK, 0.7), 0.9)
	if carry != "":
		var cr := Rect2(focus_r.position + Vector2(-14, -64 + bob), Vector2(TILE, TILE) * 0.9)
		GlyphTile.draw(ci, cr, carry, "selected", 1.0)

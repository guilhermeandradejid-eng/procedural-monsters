class_name ChoicePanel
extends Control
## Pick one of N cards (glyphs, relics, page to expand, starting tome).
## Each knight gets their own panel in their screen region.

signal chosen(choice: String)

const CARD := Vector2(300, 420)

var player: Player
var input: PlayerInput
var kind := "glyph"
var options: Array = []
var cursor := 0
var _cards: Array[Control] = []
var _closing := false
var _t := 0.0


func setup(p: Player, p_kind: String, p_options: Array, region: Rect2) -> void:
	player = p
	input = p.input
	kind = p_kind
	options = p_options
	var n := maxi(1, options.size())
	var design := Vector2(n * (CARD.x + 30) + 60, CARD.y + 200)
	size = design
	var s := minf(region.size.x / design.x, region.size.y / design.y) * 0.95
	s = minf(s, 1.0)
	scale = Vector2.ONE * s
	position = region.position + (region.size - design * s) * 0.5


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var head := UiKit.title(tr("CHOICE_%s" % kind.to_upper()), 54, Pal.PAPER_LIGHT)
	head.add_theme_color_override("font_outline_color", Pal.INK)
	head.add_theme_constant_override("outline_size", 14)
	head.size = Vector2(size.x, 70)
	head.position = Vector2(0, 0)
	add_child(head)
	var sub := UiKit.italic(tr("CHOICE_SUB") % player.profile.display_name(), 24, Pal.PAPER)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_outline_color", Pal.INK)
	sub.add_theme_constant_override("outline_size", 8)
	sub.size = Vector2(size.x, 30)
	sub.position = Vector2(0, 72)
	add_child(sub)
	for i in options.size():
		var card := _make_card(i)
		card.position = Vector2(30 + i * (CARD.x + 30), 130)
		add_child(card)
		_cards.append(card)
		UiKit.pop_in(card, 0.06 * i)
	input.clear_buffer()
	Audio.ui("cards", -4.0)


func _make_card(i: int) -> Control:
	var id: String = options[i]
	var card := PaperPanel.new()
	card.size = CARD
	card.custom_minimum_size = CARD
	card.seed = 20.0 + i * 3.1
	card.tilt_deg = [-1.5, 0.8, -0.6, 1.2][i % 4]
	card.set_margins(30)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.content.add_child(box)
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(0, 120)
	icon.draw.connect(func(): _draw_icon(icon, id))
	box.add_child(icon)
	var title := UiKit.label(_title(id), UiFonts.display(700), 34, Pal.INK, HORIZONTAL_ALIGNMENT_CENTER)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)
	var tag := UiKit.label(_tag(id), UiFonts.label(650), 17, Pal.WAX, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(tag)
	var body := UiKit.body(_desc(id), 21, Pal.INK_SOFT)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(body)
	card.gui_input.connect(func(e):
		if input.uses_mouse() and e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			cursor = i
			_confirm())
	card.mouse_entered.connect(func():
		if input.uses_mouse():
			cursor = i)
	return card


func _title(id: String) -> String:
	match kind:
		"glyph":
			return GlyphDB.glyph_name(id)
		"relic":
			return Relics.title(id)
		"page":
			return "%s %s" % [tr("GRIMOIRE_PAGE"), ["I", "II", "III"][int(id)]]
		"tome":
			return tr("TOME_%s" % id.to_upper())
	return id


func _tag(id: String) -> String:
	match kind:
		"glyph":
			return GlyphDB.type_name(GlyphDB.type_of(id)).to_upper()
		"relic":
			return tr(["RARITY_COMMON", "RARITY_UNCOMMON", "RARITY_RARE"][int(Relics.DATA[id].rarity)]).to_upper()
		"page":
			return "+1 %s" % tr("STAT_SLOTS").to_upper()
		"tome":
			return tr("TOME_TAG").to_upper()
	return ""


func _desc(id: String) -> String:
	match kind:
		"glyph":
			return GlyphDB.glyph_desc(id)
		"relic":
			return Relics.desc(id)
		"page":
			var prog := player.profile.grimoire.program(int(id))
			return "%s\n(%d/%d)" % [prog.display_name(), player.profile.grimoire.capacity(int(id)), Grimoire.MAX_SLOTS]
		"tome":
			return tr("TOME_%s_DESC" % id.to_upper())
	return ""


func _draw_icon(c: Control, id: String) -> void:
	var center := Vector2(c.size.x * 0.5, 60)
	match kind:
		"glyph":
			GlyphTile.draw(c, Rect2(center - Vector2(52, 52), Vector2(104, 104)), id, "", 1.3)
		"relic":
			var col: Color = [Pal.GOLD, Color("c08cff"), Pal.EMBER][int(Relics.DATA[id].rarity)]
			c.draw_texture_rect(Fx.icons.for_icon("reward_relic"), Rect2(center - Vector2(56, 56), Vector2(112, 112)), false, col.darkened(0.35))
		"page":
			c.draw_texture_rect(Fx.icons.for_icon("reward_page"), Rect2(center - Vector2(56, 56), Vector2(112, 112)), false, Pal.INK)
		"tome":
			var col2: Color = {"ember": Elem.main_color("ember"), "winter": Elem.main_color("frost"), "storm": Elem.main_color("storm"), "blank": Pal.INK_FADED}.get(id, Pal.INK)
			c.draw_texture_rect(Fx.icons.for_icon("reward_boss"), Rect2(center - Vector2(56, 56), Vector2(112, 112)), false, Color(col2).darkened(0.3))


func _process(delta: float) -> void:
	_t += delta / maxf(Engine.time_scale, 0.001)
	if _closing:
		return
	if input.consume("ui_left", 200):
		cursor = (cursor + options.size() - 1) % options.size()
		Audio.ui("ui_tick", -12.0)
	if input.consume("ui_right", 200):
		cursor = (cursor + 1) % options.size()
		Audio.ui("ui_tick", -12.0)
	if input.consume("ui_accept"):
		_confirm()
		return
	if input.consume("ui_back") or input.consume("pause"):
		_close("")
		return
	for i in _cards.size():
		var card := _cards[i]
		var target := Vector2(30 + i * (CARD.x + 30), 130 - (22.0 if i == cursor else 0.0))
		card.position = card.position.lerp(target, 1.0 - exp(-delta * 14.0))
		card.modulate = Color(1, 1, 1, card.modulate.a) if i == cursor else Color(0.82, 0.8, 0.78, card.modulate.a)


func _confirm() -> void:
	if options.is_empty():
		_close("")
		return
	var card := _cards[cursor]
	var seal := Control.new()
	seal.position = card.size * 0.5 - Vector2(60, 60)
	seal.size = Vector2(120, 120)
	seal.draw.connect(func():
		var c := Vector2(60, 60)
		var pts := PackedVector2Array()
		for k in 22:
			var a := TAU * k / 22.0
			pts.append(c + Vector2(cos(a), sin(a)) * (50.0 + 5.0 * sin(a * 5.0)))
		seal.draw_colored_polygon(pts, player.profile.cloth_color().darkened(0.2))
		seal.draw_arc(c, 36, 0, TAU, 32, player.profile.cloth_color().darkened(0.5), 3.0, true)
		var numeral: String = ["I", "II", "III", "IV"][player.profile.index]
		var f := UiFonts.display(700)
		var w := f.get_string_size(numeral, HORIZONTAL_ALIGNMENT_LEFT, -1, 44).x
		seal.draw_string(f, c + Vector2(-w * 0.5, 15), numeral, HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Pal.PAPER_LIGHT))
	card.add_child(seal)
	seal.pivot_offset = Vector2(60, 60)
	seal.scale = Vector2.ONE * 2.2
	seal.modulate.a = 0.0
	var t := seal.create_tween()
	t.set_parallel(true)
	t.tween_property(seal, "scale", Vector2.ONE, 0.16).set_ease(Tween.EASE_IN)
	t.tween_property(seal, "modulate:a", 1.0, 0.1)
	Audio.ui("wax_seal", -2.0)
	var choice: String = options[cursor]
	_closing = true
	var t2 := create_tween()
	t2.tween_interval(0.45)
	t2.tween_callback(func(): _close(choice))


func _close(choice: String) -> void:
	_closing = true
	input.clear_buffer()
	chosen.emit(choice)
	UiKit.fade_out_free(self, 0.2)

class_name Hud
extends Control
## In-game overlay: player cards in the corners (Ember Knights layout), team
## purse, boss ribbon, chapter title cards and toasts.

var cards := {}
var boss_bar: BossBar
var _purse: Control
var _cards_root: Control
var _title_label: Label
var _sub_label: Label
var _title_box: VBoxContainer
var _title_tween: Tween
var _toasts: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cards_root = Control.new()
	_cards_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cards_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cards_root)
	_purse = Control.new()
	_purse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.anchor_top_center(_purse, 520, 48, 12)
	_purse.draw.connect(_draw_purse)
	add_child(_purse)
	boss_bar = BossBar.new()
	boss_bar.visible = false
	add_child(boss_bar)
	_title_box = VBoxContainer.new()
	UiKit.anchor_top_center(_title_box, 1400, 220, 150)
	_title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_title_box)
	_title_label = UiKit.title("", 92, Pal.PAPER_LIGHT)
	_title_label.add_theme_color_override("font_outline_color", Pal.INK)
	_title_label.add_theme_constant_override("outline_size", 18)
	_title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	_title_label.add_theme_constant_override("shadow_offset_y", 6)
	_title_box.add_child(_title_label)
	_sub_label = UiKit.italic("", 32, Pal.PAPER)
	_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_label.add_theme_color_override("font_outline_color", Pal.INK)
	_sub_label.add_theme_constant_override("outline_size", 10)
	_title_box.add_child(_sub_label)
	_title_box.modulate.a = 0.0
	_toasts = VBoxContainer.new()
	UiKit.anchor_top_center(_toasts, 620, 320, 70)
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toasts)
	Events.toast.connect(toast)
	Game.players_changed.connect(rebuild_cards)
	rebuild_cards()


func rebuild_cards() -> void:
	for c in _cards_root.get_children():
		c.queue_free()
	cards.clear()
	var vp := get_viewport_rect().size
	var i := 0
	for prof in Game.profiles:
		var card := PlayerCard.new()
		card.setup(prof, prof.index)
		_cards_root.add_child(card)
		var m := 22.0
		var pos := Vector2.ZERO
		match prof.index:
			0:
				pos = Vector2(m, vp.y - PlayerCard.CARD.y - m)
			1:
				pos = Vector2(vp.x - PlayerCard.CARD.x - m, vp.y - PlayerCard.CARD.y - m)
			2:
				pos = Vector2(m, m + 60)
			_:
				pos = Vector2(vp.x - PlayerCard.CARD.x - m, m + 60)
		card.position = pos
		cards[prof.index] = card
		UiKit.pop_in(card, 0.1 * i)
		i += 1


func _process(_delta: float) -> void:
	_purse.queue_redraw()


func _draw_purse() -> void:
	if Game.run == null:
		return
	var f := UiFonts.numbers()
	var gold := str(Game.run.gold)
	var emb := str(Game.run.embers)
	var x := 150.0
	var y := 32.0
	_coin(Vector2(x, y - 7))
	_outlined(f, Vector2(x + 18, y), gold, 26, Pal.GOLD_BRIGHT)
	x += 40 + f.get_string_size(gold, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
	_ember_icon(Vector2(x, y - 8))
	_outlined(f, Vector2(x + 16, y), emb, 26, Pal.EMBER)
	var page_txt := "%s · %s" % [tr("CHAPTER_SHORT_%d" % (Game.run.chapter + 1)), tr("PAGE_SHORT") % (Game.run.page + 1)]
	_outlined(UiFonts.italic(), Vector2(x + 70, y), page_txt, 20, Pal.PAPER)


func _outlined(f: Font, p: Vector2, t: String, s: int, col: Color) -> void:
	_purse.draw_string_outline(f, p, t, HORIZONTAL_ALIGNMENT_LEFT, -1, s, 8, Pal.INK)
	_purse.draw_string(f, p, t, HORIZONTAL_ALIGNMENT_LEFT, -1, s, col)


func _coin(c: Vector2) -> void:
	_purse.draw_circle(c, 11.0, Pal.INK)
	_purse.draw_circle(c, 9.0, Pal.GOLD_BRIGHT)
	_purse.draw_arc(c, 5.5, 0.0, TAU, 16, Pal.GOLD.darkened(0.3), 1.6, true)


func _ember_icon(c: Vector2) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -12), c + Vector2(7, 2), c + Vector2(0, 10), c + Vector2(-7, 2)])
	_purse.draw_colored_polygon(pts, Pal.INK)
	var inner := PackedVector2Array([c + Vector2(0, -8), c + Vector2(4.5, 2), c + Vector2(0, 7), c + Vector2(-4.5, 2)])
	_purse.draw_colored_polygon(inner, Pal.EMBER)


func show_title(title: String, subtitle := "", hold := 1.6) -> void:
	_title_label.text = title
	_sub_label.text = subtitle
	_title_label.visible_ratio = 0.0
	if _title_tween:
		_title_tween.kill()
	_title_tween = create_tween()
	_title_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_title_tween.tween_property(_title_box, "modulate:a", 1.0, 0.15)
	_title_tween.parallel().tween_property(_title_label, "visible_ratio", 1.0, 0.55)
	_title_tween.tween_interval(hold)
	_title_tween.tween_property(_title_box, "modulate:a", 0.0, 0.5)
	if title != "":
		Audio.ui("quill_write", -8.0)


func toast(text: String, col := Pal.INK) -> void:
	var slip := PaperPanel.new()
	slip.custom_minimum_size = Vector2(520, 70)
	slip.frame = false
	slip.set_margins(14)
	var l := UiKit.label(text, UiFonts.label(600), 26, col, HORIZONTAL_ALIGNMENT_CENTER)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	slip.content.add_child(l)
	_toasts.add_child(slip)
	UiKit.pop_in(slip)
	var t := slip.create_tween()
	t.tween_interval(2.4)
	t.tween_callback(func(): UiKit.fade_out_free(slip, 0.35))

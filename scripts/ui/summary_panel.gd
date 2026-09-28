class_name SummaryPanel
extends Control
## The Chronicle: an illuminated page summarising the expedition.

signal done

var won := false
var embers_earned := 0
var _counter: Label
var _shown := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.02, 0.02, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var vp := get_viewport_rect().size
	var page := PaperPanel.new()
	page.size = Vector2(1300, 900)
	page.position = (vp - page.size) * 0.5
	page.set_margins(64)
	add_child(page)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	page.content.add_child(box)
	box.add_child(UiKit.title(tr("CHRONICLE_TITLE"), 64))
	var verdict := UiKit.italic(tr("CHRONICLE_WON") if won else tr("CHRONICLE_LOST"), 30, Pal.WAX)
	verdict.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(verdict)
	var r := Game.run
	if r:
		var facts := UiKit.body("%s: %d   ·   %s: %d   ·   %s: %s" % [tr("CHRONICLE_PAGES"), r.pages_cleared, tr("CHRONICLE_KILLS"), r.kills, tr("CHRONICLE_TIME"), "%d:%02d" % [int(r.time / 60.0), int(r.time) % 60]], 26, Pal.INK)
		facts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(facts)
	var grid := HBoxContainer.new()
	grid.alignment = BoxContainer.ALIGNMENT_CENTER
	grid.add_theme_constant_override("separation", 40)
	box.add_child(grid)
	for prof in Game.profiles:
		var col := VBoxContainer.new()
		col.custom_minimum_size = Vector2(260, 0)
		col.add_child(UiKit.label(prof.display_name(), UiFonts.display(700), 32, prof.cloth_color().darkened(0.25), HORIZONTAL_ALIGNMENT_CENTER))
		var best := prof.grimoire.program(0)
		var lines := "%s: %d\n%s: %d\n%s: %d\n%s: %d\n%s: %d\n\n%s\n“%s”" % [
			tr("CHRONICLE_KILLS"), prof.kills, tr("CHRONICLE_DAMAGE"), int(prof.damage_dealt),
			tr("CHRONICLE_CASTS"), prof.casts, tr("CHRONICLE_PERFECT"), prof.perfect_dodges,
			tr("CHRONICLE_REVIVES"), prof.revives_given, tr("CHRONICLE_SPELL"), best.display_name()]
		var l := UiKit.body(lines, 22, Pal.INK_SOFT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(l)
		var sig := Control.new()
		sig.custom_minimum_size = Vector2(0, 150)
		var spec := SigilArt.spec(best)
		sig.draw.connect(func():
			if not best.empty:
				SigilArt.draw(sig, spec, Vector2(sig.size.x * 0.5, 75), 68.0, Color(Pal.INK, 0.8), 1.0, 1.6))
		col.add_child(sig)
		grid.add_child(col)
	_counter = UiKit.label("", UiFonts.numbers(), 44, Pal.EMBER.darkened(0.25), HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_counter)
	var ok := InkButton.new()
	ok.text = tr("CHRONICLE_CONTINUE")
	ok.font_size = 34
	ok.align_left = false
	ok.pressed.connect(func(): done.emit())
	box.add_child(ok)
	UiKit.pop_in(page)
	ok.call_deferred("grab_focus")
	var t := create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_interval(0.6)
	t.tween_method(func(v: float):
		_shown = v
		_counter.text = "+ %d %s" % [int(v), tr("EMBERS")], 0.0, float(embers_earned), 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

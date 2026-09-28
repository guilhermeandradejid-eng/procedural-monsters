class_name PlayerCard
extends Control
## HUD card for one knight: a melting candle (health), three wax seals
## bearing each page's sigil (cooldown as an ink wash), dash quills, relics.

const CARD := Vector2(360, 156)

var profile: PlayerProfile
var corner := 0
var _paper: Control
var _seeds: Array[int] = [0, 0, 0]
var _ready_flash: Array[float] = [0.0, 0.0, 0.0]
var _was_ready: Array[bool] = [true, true, true]
var _hp_shown := 1.0
var _hurt := 0.0
var _t := 0.0


func setup(p: PlayerProfile, p_corner: int) -> void:
	profile = p
	corner = p_corner


func _ready() -> void:
	custom_minimum_size = CARD
	size = CARD
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = CARD * 0.5
	rotation = deg_to_rad([-1.2, 1.4, 1.0, -1.1][corner % 4])
	_paper = Control.new()
	_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paper.size = CARD
	_paper.material = UiKit.parchment_material(CARD, 13.0 + corner * 7.0, 0.55, 7.0)
	_paper.draw.connect(func(): _paper.draw_rect(Rect2(Vector2.ZERO, CARD), Color.WHITE))
	_paper.show_behind_parent = true
	add_child(_paper)
	Events.player_damaged.connect(func(pl, _h):
		if pl.get("profile") == profile:
			_hurt = 1.0)


func _process(delta: float) -> void:
	if profile == null:
		return
	var real := delta / maxf(Engine.time_scale, 0.001)
	_t += real
	_hurt = maxf(0.0, _hurt - real * 2.5)
	var ratio := clampf(profile.hp / maxf(profile.stat("max_hp"), 1.0), 0.0, 1.0)
	_hp_shown = lerpf(_hp_shown, ratio, 1.0 - exp(-real * 6.0))
	for i in 3:
		var prog := profile.grimoire.program(i)
		var s := prog.seed if prog and not prog.empty else 0
		_seeds[i] = s
		var actor: Player = profile.actor as Player
		var ready := actor == null or actor.cooldowns[i] <= 0.0
		if ready and not _was_ready[i] and s != 0:
			_ready_flash[i] = 1.0
		_was_ready[i] = ready
		_ready_flash[i] = maxf(0.0, _ready_flash[i] - real * 2.5)
	queue_redraw()


func _draw() -> void:
	if profile == null:
		return
	var ink := Pal.INK
	var flame := profile.flame_color()
	var actor: Player = profile.actor as Player
	# Name ribbon.
	var ribbon := PackedVector2Array([Vector2(18, 10), Vector2(150, 10), Vector2(140, 22), Vector2(150, 34), Vector2(18, 34)])
	draw_colored_polygon(ribbon, profile.cloth_color())
	Quill.stroke(self, PackedVector2Array([Vector2(18, 10), Vector2(150, 10)]), 1.2, Color(ink, 0.6), 0.0)
	var numeral: String = ["I", "II", "III", "IV"][profile.index]
	draw_string(UiFonts.display(700), Vector2(26, 31), numeral, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Pal.PAPER_LIGHT)
	draw_string(UiFonts.label(600), Vector2(60, 29), Pal.PLAYER_NAMES[profile.index].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Pal.PAPER_LIGHT)
	_draw_candle(Vector2(52, 132), flame, actor)
	var labels := ["spell_0", "spell_1", "spell_2"]
	for i in 3:
		var c := Vector2(128 + i * 76, 74)
		_draw_seal(c, i, actor)
		var hint := InputGlyphs.raw(profile.input, labels[i])
		var f := UiFonts.label(600)
		var w := f.get_string_size(hint, HORIZONTAL_ALIGNMENT_CENTER, -1, 14).x
		draw_string(f, c + Vector2(-w * 0.5, 44), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(ink, 0.65))
	# Dash quills.
	var charges := int(profile.stat("dash_charges"))
	var have := actor.dash_charges if actor else charges
	for i in charges:
		var p := Vector2(106 + i * 18, 142)
		var col := ink if i < have else Color(ink, 0.22)
		Quill.stroke(self, PackedVector2Array([p + Vector2(-5, 7), p + Vector2(5, -7)]), 2.6, col, 0.6)
		Quill.stroke(self, PackedVector2Array([p + Vector2(0, 0), p + Vector2(6, -3)]), 1.2, col, 0.4)
	# Relics as small gilt lozenges.
	var rx := 106.0 + charges * 18.0 + 14.0
	for i in mini(profile.relics.size(), 9):
		var p := Vector2(rx + i * 16, 141)
		var pts := PackedVector2Array([p + Vector2(0, -6), p + Vector2(5, 0), p + Vector2(0, 6), p + Vector2(-5, 0)])
		draw_colored_polygon(pts, Pal.GOLD)
		Quill.stroke(self, pts + PackedVector2Array([p + Vector2(0, -6)]), 1.0, ink, 0.0)
	if actor and actor.living_ink > 0.0:
		var a := 0.5 + 0.5 * sin(_t * 12.0)
		draw_string(UiFonts.italic(), Vector2(210, 30), tr("FX_LIVING_INK"), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(Pal.GOLD_BRIGHT.darkened(0.3), a))


func _draw_candle(base: Vector2, flame: Color, actor: Player) -> void:
	var ink := Pal.INK
	var max_h := 78.0
	var h := maxf(4.0, max_h * _hp_shown)
	var w := 24.0
	var body := Rect2(base.x - w * 0.5, base.y - 10.0 - h, w, h)
	var wax := Pal.PAPER_LIGHT.lerp(Color("f6d7c4"), _hurt * 0.6)
	draw_rect(body, wax)
	draw_rect(Rect2(body.position, Vector2(6, body.size.y)), Color(0, 0, 0, 0.06))
	for d in [Vector2(-7, 12), Vector2(5, 20), Vector2(9, 8)]:
		var dp := Vector2(base.x + d.x, body.position.y)
		draw_rect(Rect2(dp.x - 2.0, dp.y, 4.0, d.y), wax)
		draw_circle(dp + Vector2(0, d.y), 2.6, wax)
	Quill.stroke(self, PackedVector2Array([body.position, Vector2(body.position.x, body.end.y)]), 1.4, Color(ink, 0.7), 0.1)
	Quill.stroke(self, PackedVector2Array([Vector2(body.end.x, body.position.y), body.end]), 1.4, Color(ink, 0.7), 0.1)
	var dish := PackedVector2Array([Vector2(base.x - 26, base.y - 10), Vector2(base.x + 26, base.y - 10), Vector2(base.x + 18, base.y), Vector2(base.x - 18, base.y)])
	draw_colored_polygon(dish, Pal.GOLD)
	Quill.stroke(self, dish + PackedVector2Array([dish[0]]), 1.4, ink, 0.0)
	var top := Vector2(base.x, body.position.y)
	Quill.stroke(self, PackedVector2Array([top, top + Vector2(0, -7)]), 2.0, ink, 0.2)
	var downed := actor != null and actor.downed
	if downed or profile.hp <= 0.0:
		for i in 3:
			var y := top.y - 12.0 - i * 9.0 - fmod(_t * 14.0, 9.0)
			Quill.stroke(self, GlyphArt._curve([Vector2(top.x, y + 8), Vector2(top.x + 5 * sin(_t + i), y + 4), Vector2(top.x - 4, y)], 4), 1.2, Color(ink, 0.35), 0.8)
	else:
		var fl := 1.0 + 0.12 * sin(_t * 17.0) + 0.08 * sin(_t * 31.0)
		var fs := (10.0 + 10.0 * _hp_shown) * fl
		_flame_shape(top, fs, flame, 1.0)
		_flame_shape(top + Vector2(0, -1), fs * 0.55, Pal.EMBER_HOT, 0.55)
	var txt := "%d/%d" % [int(ceil(profile.hp)), int(profile.stat("max_hp"))]
	var f := UiFonts.numbers()
	var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	draw_string(f, Vector2(base.x - tw * 0.5, base.y + 17), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Pal.WAX_DARK if _hp_shown < 0.3 else ink)


func _flame_shape(top: Vector2, s: float, col: Color, k: float) -> void:
	var center := top + Vector2(0, -6.0 - s * 0.5)
	var tip := center + Vector2(sin(_t * 9.0) * 2.0 * k, -s * 1.25)
	var r := s * 0.55
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		var p := center + Vector2(sin(a), -cos(a)) * r
		if p.y < center.y:
			var f := (center.y - p.y) / r
			p = p.lerp(tip, f * f * 0.85)
		pts.append(p)
	draw_colored_polygon(pts, col)


func _draw_seal(c: Vector2, i: int, actor: Player) -> void:
	var prog := profile.grimoire.program(i)
	var empty := prog == null or prog.empty
	var r := 27.0
	var pts := PackedVector2Array()
	for k in 24:
		var a := TAU * k / 24.0
		var rr := r * (1.0 + 0.07 * sin(a * 5.0 + i * 1.7) + 0.04 * sin(a * 11.0))
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	var wax := Pal.WAX if not empty else Color("d8c6a0")
	if not empty:
		wax = wax.lerp(Elem.palette(prog.element())["dark"], 0.25)
	draw_colored_polygon(pts, wax)
	draw_polyline(pts + PackedVector2Array([pts[0]]), wax.darkened(0.35), 1.6, true)
	draw_arc(c, r * 0.78, 0.0, TAU, 32, wax.darkened(0.25), 1.4, true)
	if empty:
		for k in 12:
			if k % 2 == 0:
				var a0 := TAU * k / 12.0
				draw_arc(c, r * 0.55, a0, a0 + TAU / 12.0, 4, Color(Pal.INK, 0.35), 1.2, true)
		return
	var tex := Fx.sigils.for_program(prog)
	var sr := r * 0.78
	draw_texture_rect(tex, Rect2(c - Vector2(sr, sr), Vector2(sr, sr) * 2.0), false, Pal.GOLD_BRIGHT.lerp(Color.WHITE, 0.2))
	var cd := actor.cooldowns[i] if actor else 0.0
	var mx := actor.cooldown_max[i] if actor else 1.0
	if cd > 0.0:
		var f := clampf(cd / maxf(mx, 0.01), 0.0, 1.0)
		var wedge := PackedVector2Array([c])
		var steps := 28
		for k in steps + 1:
			var a := -PI * 0.5 + TAU * f * float(k) / steps
			wedge.append(c + Vector2(cos(a), sin(a)) * (r + 2.0))
		if wedge.size() >= 3:
			draw_colored_polygon(wedge, Color(0.08, 0.05, 0.06, 0.62))
		if cd > 0.95:
			var txt := "%d" % int(ceil(cd))
			var fnt := UiFonts.numbers()
			var tw := fnt.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
			draw_string_outline(fnt, c + Vector2(-tw * 0.5, 8), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 6, Pal.INK)
			draw_string(fnt, c + Vector2(-tw * 0.5, 8), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Pal.PAPER_LIGHT)
	if _ready_flash[i] > 0.0:
		draw_arc(c, r + 4.0 + (1.0 - _ready_flash[i]) * 8.0, 0.0, TAU, 32, Color(Pal.GOLD_BRIGHT, _ready_flash[i]), 2.5, true)

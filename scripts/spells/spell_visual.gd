class_name SpellVisual
extends RefCounted
## Procedural look of a clause. Everything derives from the clause seed,
## its essence(s) and inflections, so two different sentences never look the
## same while the same sentence always looks identical.

static var _cache := {}
static var _mat_cache := {}

var element := "arcane"
var form := "bolt"
var seed := 0
var core := Color.WHITE
var main := Color.WHITE
var dark := Color.BLACK
var rim := Color.WHITE
## Core silhouette.
var spikes := 3
var twist := 0.0
var shape := 0
var pulse_hz := 3.0
var wobble := 0.0
var noise_scale := 3.0
var noise_speed := 1.0
var glow := 3.0
var size_mult := 1.0
var stretch := 1.0
var trail_width := 0.5
var trail_time := 0.22
var motes: Array[String] = []
var mote_rate := 1.0
var ghost := false
var jagged := false


static func for_clause(c: SpellClause, p_form: String) -> SpellVisual:
	var key := "%d|%s|%s|%s" % [c.seed, c.element, p_form, str(c.mods)]
	if _cache.has(key):
		return _cache[key]
	var v := SpellVisual.new()
	v._build(c, p_form, hash(key))
	_cache[key] = v
	if _cache.size() > 512:
		_cache.clear()
	return v


func _build(c: SpellClause, p_form: String, p_seed: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = p_seed
	seed = p_seed
	element = c.element
	form = p_form
	var pal := Elem.palette(element)
	var hue_j := r.randf_range(-0.022, 0.022)
	core = pal.core
	main = _hue(pal.main, hue_j)
	dark = _hue(pal.dark, hue_j * 0.5)
	rim = pal.rim
	spikes = r.randi_range(2, 6)
	twist = r.randf_range(0.0, 1.0)
	shape = r.randi_range(0, 3)
	pulse_hz = r.randf_range(2.0, 6.5)
	wobble = r.randf_range(0.0, 0.35)
	noise_scale = r.randf_range(2.0, 5.5)
	noise_speed = r.randf_range(0.6, 2.2)
	glow = r.randf_range(2.6, 4.2) + 0.6 * maxf(0.0, c.intensity - 1.0)
	size_mult = pow(1.3, c.mod("grow"))
	stretch = 1.0 + 0.35 * c.mod("swift") + 0.25 * c.mod("pierce")
	trail_width = r.randf_range(0.35, 0.7) * size_mult / (1.0 + 0.3 * c.mod("swift"))
	trail_time = r.randf_range(0.14, 0.3) * (1.0 + 0.4 * c.mod("swift"))
	motes = Elem.motes(element)
	mote_rate = 1.0 + 0.5 * maxf(0.0, c.intensity - 1.0)
	ghost = c.has_mod("echo")
	jagged = Elem.has_part(element, "storm") or c.has_mod("chain")
	if c.has_mod("seek"):
		wobble += 0.35
	if c.has_mod("heavy"):
		spikes = maxi(spikes, 5)
	if element == "arcane":
		glow *= 0.8


static func _hue(col: Color, dh: float) -> Color:
	return Color.from_hsv(fposmod(col.h + dh, 1.0), col.s, col.v, col.a)


## Shared energy material for this look (cached per visual).
func energy_material() -> ShaderMaterial:
	var key := "energy|%d" % seed
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/fx/energy.gdshader")
	m.set_shader_parameter("core_color", core)
	m.set_shader_parameter("main_color", main)
	m.set_shader_parameter("dark_color", dark)
	m.set_shader_parameter("rim_color", rim)
	m.set_shader_parameter("glow", glow)
	m.set_shader_parameter("noise_scale", noise_scale)
	m.set_shader_parameter("noise_speed", noise_speed)
	m.set_shader_parameter("pulse_hz", pulse_hz)
	m.set_shader_parameter("wobble", wobble)
	m.set_shader_parameter("dark_core", 1.0 if element in ["void", "blackflame", "eclipse", "entropy", "blight", "rift"] else 0.0)
	_mat_cache[key] = m
	if _mat_cache.size() > 400:
		_mat_cache.clear()
	return m


func gradient() -> Gradient:
	var g := Gradient.new()
	g.set_color(0, Color(core.r, core.g, core.b, 1.0))
	g.set_color(1, Color(dark.r, dark.g, dark.b, 0.0))
	g.add_point(0.35, Color(main.r, main.g, main.b, 0.9))
	return g

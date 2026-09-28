class_name UiRoot
extends Node
## Owns every UI layer: world post-fx (below the HUD), HUD, per-player
## panels, global menus and transitions.

const PAGE_TURN := preload("res://shaders/ui/page_turn.gdshader")
const INK_WIPE := preload("res://shaders/ui/ink_wipe.gdshader")

var fx_layer: CanvasLayer
var hud_layer: CanvasLayer
var panel_layer: CanvasLayer
var menu_layer: CanvasLayer
var trans_layer: CanvasLayer
var screen_fx: ScreenFx
var hud: Hud
var title_menu: TitleMenu
var panels := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	fx_layer = _layer("ScreenFx", 5)
	hud_layer = _layer("Hud", 10)
	panel_layer = _layer("Panels", 20)
	menu_layer = _layer("Menus", 30)
	trans_layer = _layer("Transition", 100)
	screen_fx = ScreenFx.new()
	fx_layer.add_child(screen_fx)
	panel_layer.process_mode = Node.PROCESS_MODE_PAUSABLE


func _layer(n: String, idx: int) -> CanvasLayer:
	var l := CanvasLayer.new()
	l.name = n
	l.layer = idx
	add_child(l)
	return l


func show_hud(on: bool) -> void:
	if on and hud == null:
		hud = Hud.new()
		hud_layer.add_child(hud)
	elif not on and hud:
		hud.queue_free()
		hud = null


func show_title_menu() -> TitleMenu:
	hide_title_menu()
	title_menu = TitleMenu.new()
	menu_layer.add_child(title_menu)
	return title_menu


func hide_title_menu() -> void:
	if title_menu and is_instance_valid(title_menu):
		title_menu.queue_free()
	title_menu = null


# --- per-player panels ----------------------------------------------------------------
func has_panel(p: PlayerProfile) -> bool:
	return panels.has(p.index) and is_instance_valid(panels[p.index])


func _region(p: PlayerProfile) -> Rect2:
	var vp := get_viewport().get_visible_rect().size
	var order := Game.profiles.find(p)
	return UiKit.player_region(vp, maxi(order, 0), Game.profiles.size())


func _register(pl: Player, panel: Control, close_signal: Signal) -> void:
	panels[pl.profile.index] = panel
	pl.frozen_input = true
	panel_layer.add_child(panel)
	close_signal.connect(func(_a = null):
		panels.erase(pl.profile.index)
		if is_instance_valid(pl):
			pl.frozen_input = false
			pl.input.clear_buffer()
		Audio.duck(not panels.is_empty()))
	Audio.duck(true)


func open_grimoire(pl: Player) -> void:
	if has_panel(pl.profile):
		return
	var g := GrimoirePanel.new()
	g.setup(pl, _region(pl.profile))
	_register(pl, g, g.closed)


func open_choice(pl: Player, kind: String, options: Array, cb: Callable) -> void:
	if has_panel(pl.profile) or options.is_empty():
		return
	var c := ChoicePanel.new()
	c.setup(pl, kind, options, _region(pl.profile))
	c.chosen.connect(func(choice: String): cb.call(choice))
	_register(pl, c, c.chosen)


func open_station(pl: Player, kind: String) -> void:
	if has_panel(pl.profile):
		return
	match kind:
		"candelabrum":
			var c := CandelabrumPanel.new()
			c.setup(pl, _region(pl.profile))
			_register(pl, c, c.closed)
		"tomes":
			var tomes: Array = Game.meta.get("tomes", ["ember", "winter", "storm"])
			open_choice(pl, "tome", tomes, func(choice: String):
				if choice != "":
					pl.profile.tome = choice
					pl.profile.grimoire.setup_tome(choice, Game.upgrade_level("margins"), Game.rng)
					Fx.burst(pl.global_position + Vector3.UP * 1.4, "twinkle", Pal.GOLD_BRIGHT, pl.profile.flame_color(), 20, 1.2))


func close_all_panels() -> void:
	for k in panels.keys():
		var p = panels[k]
		if is_instance_valid(p):
			p.queue_free()
	panels.clear()
	for prof in Game.profiles:
		if prof.actor and is_instance_valid(prof.actor):
			prof.actor.frozen_input = false
	Audio.duck(false)


# --- menus -----------------------------------------------------------------------------
func add_menu(c: Control) -> void:
	menu_layer.add_child(c)


# --- transitions -------------------------------------------------------------------------
func capture_frame() -> Texture2D:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	return ImageTexture.create_from_image(img)


func page_turn(tex: Texture2D, duration := 0.95) -> void:
	var r := ColorRect.new()
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = PAGE_TURN
	m.set_shader_parameter("old_frame", tex)
	m.set_shader_parameter("progress", 0.0)
	r.material = m
	trans_layer.add_child(r)
	var t := r.create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_interval(0.12)
	t.tween_method(func(v: float): m.set_shader_parameter("progress", v), 0.0, 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_callback(r.queue_free)
	Audio.ui("page_turn", -2.0)


func ink_reveal(duration := 0.8) -> void:
	var r := ColorRect.new()
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = INK_WIPE
	var vp := get_viewport().get_visible_rect().size
	m.set_shader_parameter("aspect", Vector2(vp.x / vp.y, 1.0))
	m.set_shader_parameter("progress", 1.0)
	r.material = m
	trans_layer.add_child(r)
	var t := r.create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_method(func(v: float): m.set_shader_parameter("progress", v), 1.0, 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(r.queue_free)


func ink_cover(duration := 0.45) -> void:
	var r := ColorRect.new()
	r.name = "InkCover"
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = INK_WIPE
	var vp := get_viewport().get_visible_rect().size
	m.set_shader_parameter("aspect", Vector2(vp.x / vp.y, 1.0))
	m.set_shader_parameter("progress", 0.0)
	r.material = m
	trans_layer.add_child(r)
	var t := r.create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_method(func(v: float): m.set_shader_parameter("progress", v), 0.0, 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await t.finished
	var t2 := r.create_tween()
	t2.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t2.tween_interval(0.25)
	t2.tween_callback(r.queue_free)

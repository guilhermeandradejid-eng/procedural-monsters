extends Node
## Root of the game: level swapping with page-turn transitions, the flow
## Title → Frontispiece (hub) → Chapters → Chronicle, pause and panels.
##
## Test hooks (after `--` on the command line):
##   --autostart=hub|run   skip the title with a keyboard knight
##   --players=N           add N knights (extra ones are bots)
##   --bot                 let a bot drive knight I
##   --shot=path.png --shot_at=6   save a screenshot after N seconds
##   --quit_after=20       quit automatically

var world: Node3D
var ui: UiRoot
var current: Node = null
var args := {}
var _busy := false
var _pause: PauseMenu
var _elapsed := 0.0
var _shot_done := false


func _ready() -> void:
	Game.main = self
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv := a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	world = Node3D.new()
	world.name = "World"
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	ui = UiRoot.new()
	ui.name = "UI"
	add_child(ui)
	match String(args.get("autostart", "")):
		"hub":
			_add_test_players()
			goto_hub(false)
		"run":
			_add_test_players()
			start_run()
		_:
			goto_title()


func _add_test_players() -> void:
	var n := int(args.get("players", "1"))
	for i in n:
		var input := PlayerInput.new(PlayerInput.Kind.KBM) if i == 0 else PlayerInput.new(PlayerInput.Kind.PAD, 90 + i)
		var p := Game.add_player(input)
		if p:
			p.reset_for_run(Game.meta)
	if args.has("bot") or n > 1:
		var bot := BotDriver.new()
		bot.all_players = args.has("bot")
		add_child(bot)


func _process(delta: float) -> void:
	_elapsed += delta / maxf(Engine.time_scale, 0.001)
	if args.has("shot") and not _shot_done and _elapsed >= float(args.get("shot_at", "6")):
		_shot_done = true
		_save_shot(String(args.shot))
	# --shots=4,8,12 saves shot_4.png, shot_8.png... next to --shot.
	if args.has("shots") and args.has("shot"):
		for t in String(args.shots).split(","):
			var key := "done_" + t
			if not args.has(key) and _elapsed >= float(t):
				args[key] = "1"
				_save_shot(String(args.shot).get_basename() + "_" + t + ".png")
	if args.has("quit_after") and _elapsed >= float(args.quit_after):
		get_tree().quit()
	if get_tree().paused or _busy or current == null or current is TitleLevel:
		return
	for p in Game.profiles:
		if not ui.has_panel(p) and p.input.consume("pause"):
			open_pause()
			break


func _save_shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("screenshot saved: ", path)


# --- level management -----------------------------------------------------------------
func _set_level(level: Node, transition := "page") -> void:
	if _busy:
		level.free()
		return
	_busy = true
	var cap: Texture2D = null
	if transition == "page" and current != null:
		cap = await ui.capture_frame()
	elif transition == "ink" and current != null:
		await ui.ink_cover()
	ui.close_all_panels()
	get_tree().paused = false
	Juice.reset()
	if current:
		world.remove_child(current)
		current.queue_free()
	Combat.enemies.clear()
	Combat.players.clear()
	SpellRunner.alive_entities = 0
	current = level
	world.add_child(level)
	if cap:
		ui.page_turn(cap)
	elif transition == "ink":
		ui.ink_reveal()
	_busy = false


func goto_title() -> void:
	Game.run = null
	for p in Game.profiles.duplicate():
		Game.remove_player(p)
	Devices.joining_enabled = false
	ui.show_hud(false)
	await _set_level(TitleLevel.new(), "ink")
	var menu := ui.show_title_menu()
	menu.play.connect(_on_title_play)
	menu.settings.connect(func():
		var s := SettingsMenu.new()
		ui.add_menu(s)
		s.closed.connect(func(): if ui.title_menu: ui.title_menu.focus_first()))
	menu.credits.connect(_show_credits)
	menu.quit.connect(func(): get_tree().quit())


func _on_title_play(input: PlayerInput) -> void:
	ui.hide_title_menu()
	if Game.profiles.is_empty():
		var p := Game.add_player(input)
		if p:
			p.reset_for_run(Game.meta)
	goto_hub()


func goto_hub(transition := true) -> void:
	Game.run = null
	for p in Game.profiles:
		p.reset_for_run(Game.meta)
	ui.show_hud(false)
	await _set_level(HubLevel.new(), "ink" if transition else "none")
	ui.show_hud(true)
	ui.hud.show_title(tr("HUB_TITLE"), tr("HUB_SUB"), 2.2)


func start_run() -> void:
	Game.run = RunState.new()
	Game.run.start(randi(), Game.meta)
	Game.meta.runs = int(Game.meta.get("runs", 0)) + 1
	Game.save_meta()
	for p in Game.profiles:
		p.reset_for_run(Game.meta, Game.run.rng)
	Devices.joining_enabled = false
	_enter_room(Game.run.next_room)


func next_page(room: Dictionary) -> void:
	if Game.run == null or _busy:
		return
	if room.kind == "chapter":
		if not Game.run.advance_chapter():
			end_run(true)
			return
	else:
		Game.run.advance(room)
	_enter_room(Game.run.next_room)


func _enter_room(room: Dictionary) -> void:
	var lv := RoomLevel.new()
	lv.setup(room)
	await _set_level(lv, "page")
	ui.show_hud(true)
	if ui.hud:
		ui.hud.rebuild_cards()


func end_run(won: bool) -> void:
	if Game.run == null:
		return
	var r := Game.run
	r.won = won
	var earned := r.embers + r.pages_cleared * 2 + r.chapter * 25 + (150 if won else 0)
	Game.add_embers(earned)
	Game.meta.wins = int(Game.meta.get("wins", 0)) + (1 if won else 0)
	Game.meta.best_chapter = maxi(int(Game.meta.get("best_chapter", 0)), r.chapter + (1 if won else 0))
	Game.meta.kills = int(Game.meta.get("kills", 0)) + r.kills
	Game.save_meta()
	var s := SummaryPanel.new()
	s.won = won
	s.embers_earned = earned
	ui.add_menu(s)
	s.done.connect(func():
		s.queue_free()
		goto_hub())


# --- pause ------------------------------------------------------------------------------
func open_pause() -> void:
	if _pause and is_instance_valid(_pause):
		return
	get_tree().paused = true
	Audio.duck(true)
	_pause = PauseMenu.new()
	_pause.in_run = Game.run != null
	ui.add_menu(_pause)
	_pause.resume.connect(close_pause)
	_pause.open_settings.connect(func():
		var s := SettingsMenu.new()
		ui.add_menu(s)
		s.closed.connect(func(): if _pause: _pause.focus_first()))
	_pause.abandon.connect(func():
		close_pause()
		end_run(false))
	_pause.to_title.connect(func():
		close_pause()
		goto_title())
	_pause.quit_game.connect(func(): get_tree().quit())
	Audio.ui("book_close", -4.0)


func close_pause() -> void:
	if _pause and is_instance_valid(_pause):
		UiKit.fade_out_free(_pause, 0.15)
	_pause = null
	get_tree().paused = false
	Audio.duck(not ui.panels.is_empty())
	for p in Game.profiles:
		p.input.clear_buffer()


func _show_credits() -> void:
	var c := CreditsPanel.new()
	ui.add_menu(c)
	c.closed.connect(func(): if ui.title_menu: ui.title_menu.focus_first())


# --- hooks used by levels ---------------------------------------------------------------
func show_title_card(title: String, subtitle := "", hold := 1.6) -> void:
	if ui.hud:
		ui.hud.show_title(title, subtitle, hold)


func show_boss_bar(b: Node3D) -> void:
	if ui.hud:
		ui.hud.boss_bar.track(b)


func hide_boss_bar() -> void:
	if ui.hud:
		ui.hud.boss_bar.visible = false


func open_grimoire(p: Player) -> void:
	ui.open_grimoire(p)


func open_choice(p: Player, kind: String, options: Array, cb: Callable) -> void:
	ui.open_choice(p, kind, options, cb)


func open_station(p: Player, kind: String) -> void:
	ui.open_station(p, kind)


func on_device_lost(input: PlayerInput) -> void:
	Events.toast.emit(tr("DEVICE_LOST") % input.label(), Pal.WAX)
	if current is RoomLevel:
		open_pause()

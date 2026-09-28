class_name RoomLevel
extends Level
## One page of the Grimoire. Builds itself procedurally from the run seed:
## parchment floor, pop-up scenery, waves of errata, a reward and the exits.

const SIZES := {
	"combat": Vector2(28, 19), "elite": Vector2(28, 19), "boss": Vector2(32, 22),
	"rest": Vector2(20, 14), "shop": Vector2(22, 15),
}
const POOLS := {
	"grove": {"blot": 5.0, "moth": 3.0, "scribbler": 2.0, "inkpot": 1.0},
	"catacombs": {"blot": 3.0, "brute": 3.0, "scribbler": 3.0, "inkpot": 2.0, "moth": 1.0},
	"inksea": {"blot": 2.0, "moth": 3.0, "scribbler": 3.0, "inkpot": 2.0, "brute": 3.0},
}

var room := {"kind": "combat", "reward": "glyph"}
var mood := "grove"
var page_size := Vector2(28, 19)
var rng := RandomNumberGenerator.new()
var players: Array[Player] = []
var doors: Array[ExitDoor] = []
var boss: Enemy = null
var cleared := false
var waves_left := 0
var _wave_budget := 0.0
var _wave_cooldown := 0.0
var _started := false
var _spawned_this_wave := 0
var _blockers: Array = []
var _ended := false
## Enemies scheduled to spawn (they count as alive for wave/clear logic).
var _pending_spawns := 0


func setup(p_room: Dictionary) -> void:
	room = p_room
	if Game.run:
		mood = Game.run.chapter_id()
		rng.seed = hash(Game.run.seed + Game.run.chapter * 1000 + Game.run.page * 31 + Game.run.pages_cleared)
	else:
		rng.randomize()
	page_size = SIZES.get(room.kind, SIZES.combat)
	bounds = Rect2(-page_size * 0.5 + Vector2(1, 1), page_size - Vector2(2, 2))


func _ready() -> void:
	Stage.build(self, mood)
	camera_rig = CameraRig.new()
	camera_rig.name = "CameraRig"
	add_child(camera_rig)
	camera_rig.camera.add_child(Stage.outline_quad())
	camera_rig.focus_bounds = Rect2(-page_size.x * 0.5 + 8.0, -page_size.y * 0.5 + 5.0, page_size.x - 16.0, page_size.y - 10.0)
	RoomBuilder.build_page(self, page_size, mood, rng.randf() * 100.0)
	RoomBuilder.build_walls(self, page_size)
	var pops: Array = []
	pops.append_array(_build_frame())
	pops.append_array(_build_interior())
	_build_doors()
	_spawn_players()
	RoomBuilder.popup(pops, Vector3.ZERO, 0.15)
	camera_rig.snap()
	Events.room_started.emit()
	Audio.music(mood)
	Audio.set_intensity(0.0)
	if Game.main and Game.main.has_method("show_title_card"):
		Game.main.show_title_card(_title(), _subtitle())
	after(1.1, _begin)


func _title() -> String:
	if Game.run == null:
		return ""
	return tr("CHAPTER_%d" % (Game.run.chapter + 1))


func _subtitle() -> String:
	if Game.run == null:
		return ""
	match String(room.kind):
		"boss":
			return tr("PAGE_BOSS")
		"rest":
			return tr("PAGE_REST")
		"shop":
			return tr("PAGE_SHOP")
		"elite":
			return tr("PAGE_ELITE")
	return tr("PAGE_N") % (Game.run.page + 1)


# --- construction -------------------------------------------------------------------
func _build_frame() -> Array:
	var kit: Dictionary = RoomBuilder.KITS.get(mood, RoomBuilder.KITS.grove)
	var frame: Array = kit.frame
	var out: Array = []
	var hx := page_size.x * 0.5 - 1.2
	var hz := page_size.y * 0.5 - 1.2
	# Left and right edges: a dense row of scenery; top edge between doors; bottom sparse.
	var z := -hz
	while z <= hz:
		for side in [-1.0, 1.0]:
			if rng.randf() < 0.82:
				var id: String = frame[rng.randi() % frame.size()]
				var p := Vector3(side * (hx + rng.randf_range(-0.3, 0.5)), 0, z + rng.randf_range(-0.4, 0.4))
				out.append(_add_prop(id, p, (PI * 0.5 if side < 0 else -PI * 0.5) + rng.randf_range(-0.3, 0.3)))
		z += rng.randf_range(2.0, 3.0)
	var x := -hx + 2.0
	while x <= hx - 2.0:
		if absf(x) > 3.5 and rng.randf() < 0.7:
			var id2: String = frame[rng.randi() % frame.size()]
			out.append(_add_prop(id2, Vector3(x, 0, -hz - 0.2), rng.randf_range(-0.3, 0.3)))
		if rng.randf() < 0.35:
			var decor: Array = kit.decor
			out.append(_add_prop(decor[rng.randi() % decor.size()], Vector3(x + 0.7, 0, hz + 0.3), rng.randf() * TAU))
		x += rng.randf_range(2.4, 3.6)
	return out


func _build_interior() -> Array:
	var kit: Dictionary = RoomBuilder.KITS.get(mood, RoomBuilder.KITS.grove)
	var out: Array = []
	var inner := Rect2(-page_size.x * 0.5 + 4.0, -page_size.y * 0.5 + 4.5, page_size.x - 8.0, page_size.y - 9.0)
	var avoid := [[Vector3(0, 0, page_size.y * 0.5 - 3.0), 4.0], [Vector3.ZERO, 3.5]]
	var n := 0
	match String(room.kind):
		"combat", "elite":
			n = rng.randi_range(4, 7)
		"boss":
			n = 4
		_:
			n = 2
	var obstacles: Array = kit.obstacles
	for p in RoomBuilder.scatter(rng, inner, n, 5.0, avoid):
		out.append(_add_prop(obstacles[rng.randi() % obstacles.size()], p, rng.randf() * TAU))
		_blockers.append([p, 1.6])
	var decor: Array = kit.decor
	for p in RoomBuilder.scatter(rng, inner, rng.randi_range(3, 6), 3.0, avoid + _blockers):
		out.append(_add_prop(decor[rng.randi() % decor.size()], p, rng.randf() * TAU))
	for i in rng.randi_range(1, 3):
		var p := Vector3(rng.randf_range(-page_size.x * 0.35, page_size.x * 0.35), 0, rng.randf_range(-page_size.y * 0.3, page_size.y * 0.3))
		RoomBuilder.page_illustration(self, rng, p, rng.randf_range(2.5, 4.5))
	return out


func _add_prop(id: String, p: Vector3, yaw: float) -> Node3D:
	return RoomBuilder.prop(self, id, p, yaw, rng.randf_range(0.9, 1.15))


func _build_doors() -> void:
	if not Game.run:
		return
	var options: Array[Dictionary] = []
	if room.kind == "boss":
		return
	var hp_ratio := 1.0
	var total := 0.0
	var maxs := 0.0
	for p in Game.profiles:
		total += p.hp
		maxs += p.stat("max_hp")
	if maxs > 0.0:
		hp_ratio = total / maxs
	var extra := false
	for p in Game.profiles:
		if p.relics.has("wanderer_map"):
			extra = true
	options = Game.run.roll_doors(hp_ratio, extra)
	_place_doors(options)


func _place_doors(options: Array[Dictionary]) -> void:
	var n := options.size()
	var z := -page_size.y * 0.5 + 0.9
	for i in n:
		var d := ExitDoor.new()
		d.room = options[i]
		add_child(d)
		var x := (i - (n - 1) * 0.5) * 6.5
		d.position = Vector3(x, 0, z)
		d.chosen.connect(_on_door_chosen)
		doors.append(d)


func _spawn_players() -> void:
	var entry := Vector3(0, 0, page_size.y * 0.5 - 3.2)
	var i := 0
	for prof in Game.profiles:
		var p := Player.new()
		p.setup(prof)
		p.position = entry + Vector3((i - (Game.profiles.size() - 1) * 0.5) * 1.6, 0, 0)
		p.facing = Vector3(0, 0, -1)
		add_actor(p)
		players.append(p)
		i += 1


# --- flow -------------------------------------------------------------------------------
func _begin() -> void:
	_started = true
	match String(room.kind):
		"combat":
			waves_left = 2 + (1 if Game.run and Game.run.chapter >= 1 and Game.run.page >= 3 else 0)
			_next_wave()
		"elite":
			waves_left = 3
			_next_wave()
		"boss":
			_spawn_boss()
		"rest":
			_build_rest()
			_clear()
		"shop":
			_build_shop()
			_clear()
		_:
			_clear()


func _budget() -> float:
	var ch := Game.run.chapter if Game.run else 0
	var pg := Game.run.page if Game.run else 0
	var b := 5.0 + 2.4 * ch + 0.8 * pg
	b *= 1.0 + 0.55 * (Game.profiles.size() - 1)
	if room.kind == "elite":
		b *= 1.25
	return b


func _next_wave() -> void:
	waves_left -= 1
	var budget := _budget()
	var pool: Dictionary = POOLS.get(mood, POOLS.grove)
	var kinds: Array[String] = []
	var guard := 0
	while budget > 0.5 and guard < 40:
		guard += 1
		var total := 0.0
		for k in pool:
			if float(Enemy.KINDS[k].cost) <= budget + 0.5:
				total += float(pool[k])
		if total <= 0.0:
			break
		var roll := rng.randf() * total
		for k in pool:
			if float(Enemy.KINDS[k].cost) > budget + 0.5:
				continue
			roll -= float(pool[k])
			if roll <= 0.0:
				kinds.append(k)
				budget -= float(Enemy.KINDS[k].cost)
				break
	var elite_chance := 0.04 + 0.07 * (Game.run.chapter if Game.run else 0)
	if room.kind == "elite":
		elite_chance = 0.35
	_spawned_this_wave = 0
	for k in kinds:
		var p := _spawn_point()
		var delay := rng.randf_range(0.0, 0.9)
		var is_elite := rng.randf() < elite_chance
		_pending_spawns += 1
		after(delay, func():
			_pending_spawns -= 1
			spawn_enemy(k, p, is_elite))
		_spawned_this_wave += 1
	Audio.set_intensity(1.0)


func _spawn_point() -> Vector3:
	var inner := Rect2(-page_size.x * 0.5 + 2.5, -page_size.y * 0.5 + 2.5, page_size.x - 5.0, page_size.y - 5.0)
	for i in 30:
		var p := Vector3(rng.randf_range(inner.position.x, inner.end.x), 0, rng.randf_range(inner.position.y, inner.end.y))
		var ok := true
		for pl in players:
			if Combat.flat_dist(pl.global_position, p) < 6.5:
				ok = false
		for b in _blockers:
			if Combat.flat_dist(b[0], p) < float(b[1]):
				ok = false
		if ok:
			return p
	return Vector3(rng.randf_range(-6, 6), 0, -page_size.y * 0.25)


func spawn_enemy(kind: String, p: Vector3, elite := false) -> Enemy:
	var e := Enemy.create(kind, elite)
	e.position = Combat.flat(p)
	add_actor(e)
	return e


func _spawn_boss() -> void:
	boss = spawn_enemy("binder", Vector3(0, 0, -page_size.y * 0.18), false)
	camera_rig.extra_targets = [boss]
	Audio.set_intensity(1.0)
	if Game.main and Game.main.has_method("show_boss_bar"):
		Game.main.show_boss_bar(boss)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if Game.run:
		Game.run.time += delta
	if not _started or _ended:
		return
	_check_team()
	if cleared:
		return
	var alive := Combat.enemies.size() + _pending_spawns
	if room.kind == "boss":
		if boss and (not is_instance_valid(boss) or boss.dead) and alive == 0:
			_clear()
		return
	if alive <= maxi(0, int(_spawned_this_wave * 0.25)) and waves_left > 0:
		_wave_cooldown += delta
		if _wave_cooldown > 0.8 or alive == 0:
			_wave_cooldown = 0.0
			_next_wave()
	elif alive == 0 and waves_left <= 0:
		_clear()


func _check_team() -> void:
	if players.is_empty():
		return
	for p in players:
		if not p.downed:
			return
	if Game.run and Game.run.revive_stock > 0:
		return
	_ended = true
	after(1.6, func():
		if Game.main:
			Game.main.end_run(false))


func _clear() -> void:
	if cleared:
		return
	cleared = true
	Audio.set_intensity(0.0)
	camera_rig.extra_targets = []
	Events.room_cleared.emit()
	# Everyone downed gets back up when a page is won (like EK after bosses).
	for p in players:
		if p.downed and (room.kind == "boss" or room.kind == "rest"):
			p.revive(0.35)
	if room.kind in ["combat", "elite"]:
		Juice.slowmo(0.5, 0.35, 0.4)
		Audio.play("page_clear", null, -2.0)
		if Game.main and Game.main.has_method("show_title_card"):
			Game.main.show_title_card(tr("PAGE_CLEARED"), "", 1.4)
		_spawn_reward(String(room.reward))
		if room.kind == "elite":
			after(0.5, func(): Pickup.scatter(Vector3(2, 0, 1), "gold", 40))
	elif room.kind == "boss":
		_boss_cleared()
		return
	for d in doors:
		after(1.2, d.unlock)


func _spawn_reward(kind: String) -> void:
	var c := Vector3(0, 0, -1.0)
	match kind:
		"gold":
			Pickup.scatter(c, "gold", rng.randi_range(45, 75))
			Pickup.scatter(c, "ember", rng.randi_range(4, 8))
		"glyph", "relic", "page":
			var ped := RewardPedestal.new()
			ped.reward = kind
			add_child(ped)
			ped.position = c
			RoomBuilder.popup([ped], c)


func _boss_cleared() -> void:
	Audio.play("victory", null, 0.0)
	if Game.main and Game.main.has_method("hide_boss_bar"):
		Game.main.hide_boss_bar()
	Pickup.scatter(Vector3(0, 0, -2), "ember", 30)
	var last := Game.run and Game.run.chapter >= RunState.CHAPTERS - 1
	if Game.main and Game.main.has_method("show_title_card"):
		Game.main.show_title_card(tr("CHAPTER_DONE"), tr("CHAPTER_%d" % (Game.run.chapter + 1)) if Game.run else "", 2.2)
	if last:
		after(3.0, func():
			if Game.main:
				Game.main.end_run(true))
		return
	var d := ExitDoor.new()
	d.room = {"kind": "chapter", "reward": "boss"}
	add_child(d)
	d.position = Vector3(0, 0, -page_size.y * 0.5 + 0.9)
	d.chosen.connect(_on_door_chosen)
	doors.append(d)
	after(2.0, d.unlock)
	var ped := RewardPedestal.new()
	ped.reward = "relic"
	add_child(ped)
	ped.position = Vector3(0, 0, 1.5)


func _on_door_chosen(d: ExitDoor) -> void:
	for other in doors:
		other.open = false
	if Game.main:
		Game.main.next_page(d.room)


# --- special pages --------------------------------------------------------------------
func _build_rest() -> void:
	var font := InkFont.new()
	add_child(font)
	font.position = Vector3(0, 0, -1)
	RoomBuilder.popup([font], Vector3.ZERO)


func _build_shop() -> void:
	var stock: Array[Dictionary] = []
	for g in RewardPedestal.roll_glyphs(rng, 3):
		stock.append({"type": "glyph", "id": g, "price": GlyphDB.price(g)})
	var rel := Relics.roll_choices(rng, 1, [])
	if not rel.is_empty():
		stock.append({"type": "relic", "id": rel[0], "price": Relics.price(rel[0])})
	stock.append({"type": "heal", "id": "heal", "price": 50})
	var n := stock.size()
	for i in n:
		var s := ShopStand.new()
		s.item = stock[i]
		add_child(s)
		s.position = Vector3((i - (n - 1) * 0.5) * 3.2, 0, -1.5)
	var keeper := RoomBuilder.prop(self, "lectern", Vector3(0, 0, -4.5), 0.0)
	RoomBuilder.popup([keeper], Vector3.ZERO)


# --- UI hooks ----------------------------------------------------------------------------
func can_edit_grimoire() -> bool:
	return cleared or Combat.enemies.is_empty()


func open_grimoire(p: Player) -> void:
	if not can_edit_grimoire():
		Fx.text_pop(p.global_position + Vector3.UP * 2.4, tr("GRIMOIRE_LOCKED"), Pal.DANGER, 36)
		Audio.ui("fizzle", -6.0)
		return
	if Game.main and Game.main.has_method("open_grimoire"):
		Game.main.open_grimoire(p)


func open_choice(p: Player, kind: String, options: Array, callback: Callable) -> void:
	if Game.main and Game.main.has_method("open_choice"):
		Game.main.open_choice(p, kind, options, callback)

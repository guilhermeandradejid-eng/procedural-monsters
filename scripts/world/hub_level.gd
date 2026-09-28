class_name HubLevel
extends Level
## The Frontispiece: the first page of the Grimoire. Knights join here
## (press a button on any free device), rewrite their books, test spells on
## the dummy, spend Embers at the Candelabrum and open Chapter I.

const SIZE := Vector2(26, 18)

var players: Array[Player] = []
var door: ExitDoor
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.seed = 7
	bounds = Rect2(-SIZE * 0.5 + Vector2(1, 1), SIZE - Vector2(2, 2))
	Stage.build(self, "hub")
	camera_rig = CameraRig.new()
	add_child(camera_rig)
	camera_rig.camera.add_child(Stage.outline_quad())
	camera_rig.focus_bounds = Rect2(-SIZE.x * 0.5 + 8.0, -SIZE.y * 0.5 + 5.0, SIZE.x - 16.0, SIZE.y - 10.0)
	RoomBuilder.build_page(self, SIZE, "hub", 11.0)
	RoomBuilder.build_walls(self, SIZE)
	var pops: Array = []
	var hx := SIZE.x * 0.5 - 1.2
	var hz := SIZE.y * 0.5 - 1.2
	var z := -hz
	while z <= hz:
		for side in [-1.0, 1.0]:
			var id: String = ["bookshelf", "bookshelf", "candles", "pillar"][rng.randi() % 4]
			pops.append(RoomBuilder.prop(self, id, Vector3(side * hx, 0, z), PI * 0.5 * -side))
		z += 2.6
	for x in [-8.0, -5.0, 5.0, 8.0]:
		pops.append(RoomBuilder.prop(self, "bookshelf", Vector3(x, 0, -hz - 0.1), 0.0))
	pops.append(RoomBuilder.prop(self, "big_book", Vector3(-6.5, 0, 5.5), 0.4))
	pops.append(RoomBuilder.prop(self, "book_stack", Vector3(7.5, 0, 5.8), 1.1))
	pops.append(RoomBuilder.prop(self, "scroll_pile", Vector3(-3.5, 0, 6.8), 0.3))
	RoomBuilder.page_illustration(self, rng, Vector3(0, 0, 0.5), 7.0)
	var tree := Station.new()
	tree.kind = "candelabrum"
	tree.prop_id = "ember_tree"
	add_child(tree)
	tree.position = Vector3(-7.0, 0, -1.5)
	var lectern := Station.new()
	lectern.kind = "tomes"
	lectern.prop_id = "lectern"
	add_child(lectern)
	lectern.position = Vector3(7.0, 0, -1.5)
	var dummy := TrainingDummy.new()
	add_actor(dummy)
	dummy.position = Vector3(4.5, 0, 3.5)
	door = ExitDoor.new()
	door.room = {"kind": "combat", "reward": "glyph"}
	add_child(door)
	door.position = Vector3(0, 0, -SIZE.y * 0.5 + 0.9)
	door.chosen.connect(_on_begin)
	pops.append_array([tree, lectern])
	RoomBuilder.popup(pops, Vector3.ZERO, 0.1)
	for prof in Game.profiles:
		_spawn_player(prof)
	camera_rig.snap()
	Devices.joining_enabled = true
	Devices.join_requested.connect(_on_join)
	Audio.music("hub")
	Audio.set_intensity(0.0)
	after(0.6, door.unlock)


func _exit_tree() -> void:
	super._exit_tree()
	if Devices.join_requested.is_connected(_on_join):
		Devices.join_requested.disconnect(_on_join)


func _spawn_player(prof: PlayerProfile) -> Player:
	var p := Player.new()
	p.setup(prof)
	p.position = Vector3((prof.index - 1.5) * 1.6, 0, SIZE.y * 0.5 - 3.5)
	p.facing = Vector3(0, 0, -1)
	add_actor(p)
	players.append(p)
	return p


func _on_join(input: PlayerInput) -> void:
	var prof := Game.add_player(input)
	if prof == null:
		return
	prof.reset_for_run(Game.meta)
	var p := _spawn_player(prof)
	Fx.ring(p.position, 2.5, prof.flame_color(), Pal.EMBER_HOT, 0.5, 0.12)
	Fx.burst(p.position + Vector3.UP, "flame", prof.flame_color(), Pal.EMBER, 20, 1.3)
	Audio.play("join", p.position, 0.0)
	Fx.text_pop(p.position + Vector3.UP * 2.5, prof.display_name(), prof.flame_color(), 40)


func remove_player(prof: PlayerProfile) -> void:
	for p in players:
		if p.profile == prof:
			players.erase(p)
			Fx.burst(p.global_position + Vector3.UP, "dust", Pal.PAPER_DARK, Color(0, 0, 0, 0), 12, 1.2)
			p.queue_free()
			break
	Game.remove_player(prof)


func _on_begin(_d: ExitDoor) -> void:
	if Game.profiles.is_empty():
		door.open = true
		return
	Devices.joining_enabled = false
	if Game.main:
		Game.main.start_run()


func can_edit_grimoire() -> bool:
	return true


func open_grimoire(p: Player) -> void:
	if Game.main and Game.main.has_method("open_grimoire"):
		Game.main.open_grimoire(p)


func open_choice(p: Player, kind: String, options: Array, callback: Callable) -> void:
	if Game.main and Game.main.has_method("open_choice"):
		Game.main.open_choice(p, kind, options, callback)

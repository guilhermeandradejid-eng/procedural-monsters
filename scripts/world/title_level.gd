class_name TitleLevel
extends Level
## Title screen diorama: a candle-lit page with a lone knight, drifting
## paper motes and a slow, breathing camera.

var cam: Camera3D
var _t := 0.0


func _ready() -> void:
	Stage.build(self, "hub")
	var env: Environment = ($WorldEnvironment as WorldEnvironment).environment
	env.ambient_light_energy = 0.55
	RoomBuilder.build_page(self, Vector2(22, 16), "hub", 4.0)
	var pops: Array = []
	pops.append(RoomBuilder.prop(self, "bookshelf", Vector3(-4.5, 0, -4.5), 0.25, 1.3))
	pops.append(RoomBuilder.prop(self, "bookshelf", Vector3(-1.2, 0, -5.3), 0.05, 1.3))
	pops.append(RoomBuilder.prop(self, "pillar", Vector3(2.6, 0, -5.0), 0.0, 1.2))
	pops.append(RoomBuilder.prop(self, "candles", Vector3(-2.4, 0, -1.2), 0.3, 1.4))
	pops.append(RoomBuilder.prop(self, "candles", Vector3(3.8, 0, -1.8), 1.1, 1.1))
	pops.append(RoomBuilder.prop(self, "book_stack", Vector3(-4.2, 0, 0.6), 0.6, 1.2))
	pops.append(RoomBuilder.prop(self, "big_book", Vector3(3.2, 0, 1.2), -0.5, 1.0))
	pops.append(RoomBuilder.prop(self, "scroll_pile", Vector3(1.0, 0, 2.4), 0.2, 1.0))
	pops.append(RoomBuilder.prop(self, "lectern", Vector3(0.6, 0, -2.6), -0.2, 1.3))
	RoomBuilder.page_illustration(self, RandomNumberGenerator.new(), Vector3(0, 0, 0.5), 6.0)
	var knight := Toon.spawn("res://assets/models/knight.glb", {"Cloth": Pal.player_cloth(0)})
	add_child(knight)
	knight.position = Vector3(-0.6, 0, -0.6)
	knight.rotation.y = 0.5
	var ap := Toon.find_anim_player(knight)
	if ap:
		ap.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
		ap.play("idle")
	var skel := Toon.find_skeleton(knight)
	if skel:
		var att := BoneAttachment3D.new()
		att.bone_name = "flame"
		skel.add_child(att)
		Fx.emitter(att, "flame", Pal.EMBER_HOT, Pal.EMBER, 18, 0.9)
		var l := CandleLight.new()
		l.base_energy = 2.2
		att.add_child(l)
	var motes := Fx.emitter(self, "paper", Pal.PAPER, Pal.PAPER_DARK, 40, 4.0)
	var pm := (motes.process_material as ParticleProcessMaterial).duplicate() as ParticleProcessMaterial
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(9, 3, 6)
	pm.gravity = Vector3(0.3, -0.25, 0)
	pm.initial_velocity_min = 0.1
	pm.initial_velocity_max = 0.5
	motes.process_material = pm
	motes.position = Vector3(0, 3, 0)
	var dust := Fx.emitter(self, "twinkle", Pal.EMBER_HOT, Pal.GOLD, 30, 5.0)
	var dm := (dust.process_material as ParticleProcessMaterial).duplicate() as ParticleProcessMaterial
	dm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	dm.emission_box_extents = Vector3(7, 2, 5)
	dm.gravity = Vector3(0, 0.15, 0)
	dm.initial_velocity_min = 0.0
	dm.initial_velocity_max = 0.2
	dm.scale_min = 0.05
	dm.scale_max = 0.1
	dust.process_material = dm
	dust.position = Vector3(0, 1.5, 0)
	cam = Camera3D.new()
	cam.fov = 38.0
	add_child(cam)
	cam.make_current()
	cam.add_child(Stage.outline_quad())
	RoomBuilder.popup(pops, Vector3.ZERO, 0.3)
	Audio.music("title")
	Audio.set_intensity(0.0)


func _process(delta: float) -> void:
	_t += delta
	var a := 0.35 + sin(_t * 0.07) * 0.12
	var target := Vector3(0.4, 1.0, -1.0)
	cam.global_position = target + Vector3(sin(a) * 8.5, 3.4 + sin(_t * 0.11) * 0.2, cos(a) * 8.5)
	cam.look_at(target, Vector3.UP)

extends Node3D
## Screenshot rig for reviewing models and effects without the editor.
##   godot --path . res://tools/tests/preview.tscn -- --model=knight --anim=run --t=0.2 --out=/tmp/x.png
## Options: --dist=6 --pitch=40 --yaw=0 --frames=20 --size=1280x720 --mood=grove

var args := {}


func _parse_args() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and "=" in a:
			var kv := a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1]
		elif a.begins_with("--"):
			args[a.substr(2)] = "1"


func _ready() -> void:
	_parse_args()
	var size_s: String = args.get("size", "1280x720")
	var wh := size_s.split("x")
	get_window().size = Vector2i(int(wh[0]), int(wh[1]))
	Stage.build(self, args.get("mood", "grove"))
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(16, 12)
	floor_mi.mesh = pm
	floor_mi.material_override = Stage.page_material(args.get("mood", "grove"), pm.size, 3.0)
	add_child(floor_mi)
	var cam := Camera3D.new()
	cam.fov = float(args.get("fov", "32"))
	add_child(cam)
	var dist := float(args.get("dist", "5.5"))
	var pitch := deg_to_rad(float(args.get("pitch", "38")))
	var yaw := deg_to_rad(float(args.get("yaw", "0")))
	var target := Vector3(0, float(args.get("ty", "0.7")), 0)
	var offs := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * dist
	cam.global_position = target + offs
	cam.look_at(target, Vector3.UP)
	cam.make_current()
	if args.get("outline", "1") == "1":
		cam.add_child(Stage.outline_quad())
	var models: String = args.get("model", "knight")
	var i := 0
	var names := models.split(",")
	for model_name in names:
		var path := "res://assets/models/%s.glb" % model_name
		if not ResourceLoader.exists(path):
			push_error("missing " + path)
			continue
		var over := {}
		if model_name == "knight":
			over = {"Cloth": Pal.player_cloth(i % 4)}
		var inst := Toon.spawn(path, over)
		add_child(inst)
		var spread := float(args.get("spread", "1.6"))
		inst.position = Vector3((i - (names.size() - 1) * 0.5) * spread, 0, 0)
		inst.rotation.y = deg_to_rad(float(args.get("face", "0")))
		var ap := Toon.find_anim_player(inst)
		if ap:
			print(model_name, " animations: ", ap.get_animation_list())
			var anim: String = args.get("anim", "")
			var t := float(args.get("t", "0"))
			# --anims=run@0.14,attack_1@0.1 gives each model its own clip/time.
			if args.has("anims"):
				var per: PackedStringArray = String(args.anims).split(",")
				if i < per.size():
					var at := per[i].split("@")
					anim = at[0]
					t = float(at[1]) if at.size() > 1 else 0.0
			if anim != "" and ap.has_animation(anim):
				ap.play(anim)
				ap.seek(t, true)
				ap.pause()
		i += 1
	var frames := int(args.get("frames", "12"))
	for f in frames:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var out: String = args.get("out", "user://preview.png")
	img.save_png(out)
	print("saved ", out)
	get_tree().quit()

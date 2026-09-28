class_name RewardPedestal
extends Node3D
## Stone pedestal holding the page's reward. Every knight takes their own
## pick (1 of 3), like Ember Knights' selectors.

var reward := "glyph"
var interact_radius := 2.0
var claimed := {}
var _item: MeshInstance3D
var _t := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("interactable")
	_rng.seed = hash(str(global_position) + reward + str(Game.run.seed if Game.run else 0))
	RoomBuilder.prop(self, "pedestal", Vector3.ZERO)
	_item = MeshInstance3D.new()
	_item.mesh = SpellMeshes.flat_quad()
	_item.material_override = SpellFx.sigil_material(Fx.icons.for_icon("reward_" + reward), _color(), Color.WHITE, 0.3)
	_item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_item)
	_item.position = Vector3(0, 1.7, 0)
	_item.rotation.x = PI * 0.5 - 0.6
	_item.scale = Vector3.ONE * 0.6
	var l := OmniLight3D.new()
	l.light_color = _color()
	l.light_energy = 1.4
	l.omni_range = 3.5
	l.position = Vector3.UP * 1.5
	add_child(l)
	Fx.ring(global_position, 2.0, _color(), Color.WHITE, 0.5, 0.1)
	Fx.burst(global_position + Vector3.UP * 1.4, "twinkle", _color(), Pal.GOLD, 16, 1.2)


func _color() -> Color:
	match reward:
		"relic":
			return Color("c08cff")
		"page":
			return Pal.PAPER_LIGHT
		"heal":
			return Pal.HEAL
	return Pal.GOLD_BRIGHT


func _process(delta: float) -> void:
	_t += delta
	_item.position.y = 1.7 + sin(_t * 2.4) * 0.1


func can_interact(p: Node3D) -> bool:
	return not claimed.has(p.profile.index)


func interact_prompt() -> String:
	return tr("PEDESTAL_%s" % reward.to_upper())


func interact(p: Node3D) -> void:
	if claimed.has(p.profile.index):
		return
	var level := Level.current
	match reward:
		"glyph":
			level.open_choice(p, "glyph", roll_glyphs(_rng, 3), func(choice): _take(p, choice))
		"relic":
			level.open_choice(p, "relic", Relics.roll_choices(_rng, 3, p.profile.relics), func(choice): _take(p, choice))
		"page":
			level.open_choice(p, "page", ["0", "1", "2"], func(choice): _take(p, choice))


func _take(p: Node3D, choice: String) -> void:
	if choice == "":
		return
	claimed[p.profile.index] = true
	match reward:
		"glyph":
			p.profile.grimoire.add_glyph(choice)
			Game.mark_seen(choice)
		"relic":
			Relics.give(p.profile, choice)
		"page":
			p.profile.grimoire.expand(int(choice))
	Fx.burst(p.global_position + Vector3.UP * 1.2, "twinkle", Pal.GOLD_BRIGHT, _color(), 18, 1.2)
	Audio.play("reward", p.global_position, -2.0)
	if claimed.size() >= Game.profiles.size():
		var t := create_tween()
		t.tween_property(_item, "scale", Vector3.ZERO, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)


static func roll_glyphs(rng: RandomNumberGenerator, n: int) -> Array[String]:
	var pool: Array = Game.meta.get("unlocked_glyphs", GlyphDB.starting_pool())
	var bag: Array[String] = []
	for id in pool:
		if not GlyphDB.exists(id):
			continue
		var w: int = [6, 3, 1][GlyphDB.rarity_of(id)]
		# Links and forms are the spice of the grammar: make them a bit more common.
		if GlyphDB.type_of(id) in [GlyphDB.Type.LINK, GlyphDB.Type.FORM]:
			w += 1
		for i in w:
			bag.append(id)
	var out: Array[String] = []
	while out.size() < n and not bag.is_empty():
		var id: String = bag[rng.randi() % bag.size()]
		out.append(id)
		bag.assign(bag.filter(func(x): return x != id))
	return out

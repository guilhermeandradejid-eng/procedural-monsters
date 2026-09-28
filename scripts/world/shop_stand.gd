class_name ShopStand
extends Node3D
## A pedestal with a price tag. Gold is shared by the team.

var item := {"type": "glyph", "id": "bolt", "price": 50}
var interact_radius := 1.8
var sold := false
var _icon: MeshInstance3D
var _tag: Label3D


func _ready() -> void:
	add_to_group("interactable")
	RoomBuilder.prop(self, "pedestal", Vector3.ZERO)
	_icon = MeshInstance3D.new()
	_icon.mesh = SpellMeshes.flat_quad()
	var tex: Texture2D
	match String(item.type):
		"glyph":
			tex = Fx.icons.for_glyph(item.id)
		"relic":
			tex = Fx.icons.for_icon("reward_relic")
		_:
			tex = Fx.icons.for_icon("reward_heal")
	_icon.material_override = SpellFx.sigil_material(tex, _color(), Color.WHITE, 0.0)
	_icon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_icon)
	_icon.position = Vector3(0, 1.6, 0)
	_icon.rotation.x = PI * 0.5 - 0.6
	_icon.scale = Vector3.ONE * 0.55
	_tag = Label3D.new()
	_tag.text = "%d ◉" % int(item.price)
	_tag.font = UiFonts.numbers()
	_tag.font_size = 40
	_tag.outline_size = 12
	_tag.modulate = Pal.GOLD_BRIGHT
	_tag.outline_modulate = Pal.INK
	_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_tag.fixed_size = true
	_tag.pixel_size = 0.0005
	_tag.position = Vector3(0, 2.35, 0)
	add_child(_tag)


func _color() -> Color:
	match String(item.type):
		"relic":
			return Color("c08cff")
		"heal":
			return Pal.HEAL
	return GlyphArt.glyph_color(item.id).lerp(Pal.GOLD_BRIGHT, 0.5)


func can_interact(_p: Node3D) -> bool:
	return not sold


func interact_prompt() -> String:
	var n := ""
	match String(item.type):
		"glyph":
			n = GlyphDB.glyph_name(item.id)
		"relic":
			n = Relics.title(item.id)
		_:
			n = tr("SHOP_HEAL")
	return "%s — %d" % [n, int(item.price)]


func interact(p: Node3D) -> void:
	if sold or Game.run == null:
		return
	if Game.run.gold < int(item.price):
		Fx.text_pop(global_position + Vector3.UP * 2.6, tr("SHOP_POOR"), Pal.DANGER, 34)
		Audio.ui("fizzle", -4.0)
		return
	Game.run.gold -= int(item.price)
	sold = true
	match String(item.type):
		"glyph":
			p.profile.grimoire.add_glyph(item.id)
			Game.mark_seen(item.id)
		"relic":
			Relics.give(p.profile, item.id)
		_:
			for pl in Combat.players:
				pl.heal(pl.profile.stat("max_hp") * 0.3)
	Audio.play("buy", global_position, -2.0)
	Fx.burst(global_position + Vector3.UP * 1.6, "twinkle", Pal.GOLD_BRIGHT, _color(), 16, 1.0)
	var t := create_tween()
	t.tween_property(_icon, "scale", Vector3.ZERO, 0.25)
	_tag.text = tr("SHOP_SOLD")

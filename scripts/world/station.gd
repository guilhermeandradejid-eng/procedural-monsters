class_name Station
extends Node3D
## A hub interactable that opens a per-player menu (Candelabrum, Tome lectern).

var kind := "candelabrum"
var interact_radius := 2.6
var prop_id := "ember_tree"
var _label: Label3D


func _ready() -> void:
	add_to_group("interactable")
	RoomBuilder.prop(self, prop_id, Vector3.ZERO, 0.0, 1.0 if prop_id != "ember_tree" else 1.2)
	_label = Label3D.new()
	_label.text = tr("STATION_%s" % kind.to_upper())
	_label.font = UiFonts.display(700)
	_label.font_size = 56
	_label.outline_size = 14
	_label.modulate = Pal.GOLD_BRIGHT
	_label.outline_modulate = Pal.INK
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.fixed_size = true
	_label.pixel_size = 0.0005
	_label.position = Vector3(0, 3.4 if prop_id == "ember_tree" else 2.4, 0)
	add_child(_label)


func can_interact(_p: Node3D) -> bool:
	return true


func interact_prompt() -> String:
	return tr("STATION_%s_PROMPT" % kind.to_upper())


func interact(p: Node3D) -> void:
	if Game.main and Game.main.has_method("open_station"):
		Game.main.open_station(p, kind)

class_name UiFonts
extends RefCounted
## Typography: Grenze Gotisch (display blackletter), Grenze (numbers, labels),
## IM Fell English (body text, historic print texture). All SIL OFL.

static var _cache := {}


static func _wght_tag() -> int:
	return TextServerManager.get_primary_interface().name_to_tag("wght")


static func _variable(path: String, weight: int) -> Font:
	var key := "%s@%d" % [path, weight]
	if _cache.has(key):
		return _cache[key]
	var base: FontFile = load(path)
	var fv := FontVariation.new()
	fv.base_font = base
	fv.variation_opentype = {_wght_tag(): weight}
	_cache[key] = fv
	return fv


static func display(weight := 600) -> Font:
	return _variable("res://assets/fonts/GrenzeGotisch.ttf", weight)


static func label(weight := 600) -> Font:
	return _variable("res://assets/fonts/Grenze.ttf", weight)


static func numbers() -> Font:
	return _variable("res://assets/fonts/Grenze.ttf", 850)


static func body() -> Font:
	return _static("res://assets/fonts/IMFellEnglish-Regular.ttf")


static func italic() -> Font:
	return _static("res://assets/fonts/IMFellEnglish-Italic.ttf")


static func caps() -> Font:
	return _static("res://assets/fonts/IMFellEnglishSC-Regular.ttf")


static func _static(path: String) -> Font:
	if not _cache.has(path):
		_cache[path] = load(path)
	return _cache[path]

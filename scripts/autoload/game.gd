extends Node
## Global state: settings, meta-progression save, joined players and the
## current expedition. Scene flow is delegated to Main (scenes/main.tscn).

signal players_changed
signal settings_changed
signal embers_changed

const SAVE_PATH := "user://emberquill_save.json"
const SETTINGS_PATH := "user://emberquill_settings.cfg"
const MAX_PLAYERS := 4

var settings := {
	"master": 0.85, "music": 0.65, "sfx": 0.9,
	"shake": 1.0, "hitstop": true, "flashes": true, "damage_numbers": true,
	"language": "pt_BR", "fullscreen": false, "rumble": true,
}

var meta := {}
var profiles: Array[PlayerProfile] = []
var run: RunState = null
## Set by Main when it boots.
var main: Node = null
## Deterministic randomness for things that must not depend on frame order.
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	_load_settings()
	_load_meta()
	apply_settings()
	Devices.device_disconnected.connect(_on_device_disconnected)


# --- Players ---------------------------------------------------------------------
func add_player(input: PlayerInput) -> PlayerProfile:
	if profiles.size() >= MAX_PLAYERS or Devices.is_bound(input.device_key()):
		return null
	var p := PlayerProfile.new()
	p.index = _free_index()
	p.input = input
	p.setup_from_meta(meta)
	profiles.append(p)
	profiles.sort_custom(func(a, b): return a.index < b.index)
	Devices.bind(input)
	players_changed.emit()
	return p


func remove_player(p: PlayerProfile) -> void:
	if not profiles.has(p):
		return
	Devices.unbind(p.input)
	profiles.erase(p)
	players_changed.emit()


func _free_index() -> int:
	for i in MAX_PLAYERS:
		var used := false
		for p in profiles:
			if p.index == i:
				used = true
		if not used:
			return i
	return profiles.size()


func profile_for_device(key: String) -> PlayerProfile:
	for p in profiles:
		if p.input.device_key() == key:
			return p
	return null


func living_profiles() -> Array[PlayerProfile]:
	var out: Array[PlayerProfile] = []
	for p in profiles:
		if p.actor and is_instance_valid(p.actor) and not p.actor.downed:
			out.append(p)
	return out


func _on_device_disconnected(input: PlayerInput) -> void:
	# Keep the player in the run; the pause menu tells them to reconnect.
	if main and main.has_method("on_device_lost"):
		main.on_device_lost(input)


# --- Meta progression --------------------------------------------------------------
func default_meta() -> Dictionary:
	return {
		"version": 1,
		"embers": 0,
		"embers_total": 0,
		"runs": 0,
		"wins": 0,
		"best_chapter": 0,
		"kills": 0,
		"upgrades": {},
		"unlocked_glyphs": GlyphDB.starting_pool(),
		"seen_glyphs": [],
		"codex": [],
		"tomes": ["ember", "winter", "storm"],
	}


func add_embers(n: int) -> void:
	meta.embers = int(meta.get("embers", 0)) + n
	meta.embers_total = int(meta.get("embers_total", 0)) + max(n, 0)
	embers_changed.emit()


func upgrade_level(id: String) -> int:
	return int(meta.get("upgrades", {}).get(id, 0))


func mark_seen(glyph_id: String) -> void:
	var seen: Array = meta.get("seen_glyphs", [])
	if not seen.has(glyph_id):
		seen.append(glyph_id)
		meta.seen_glyphs = seen


func save_meta() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(meta, "\t"))


func _load_meta() -> void:
	meta = default_meta()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if data is Dictionary:
		for k in data:
			meta[k] = data[k]
		# Integers come back from JSON as floats.
		for k in ["embers", "embers_total", "runs", "wins", "best_chapter", "kills"]:
			meta[k] = int(meta.get(k, 0))


func reset_meta() -> void:
	meta = default_meta()
	save_meta()
	embers_changed.emit()


# --- Settings ------------------------------------------------------------------------
func set_setting(key: String, value) -> void:
	settings[key] = value
	apply_settings()
	_save_settings()
	settings_changed.emit()


func apply_settings() -> void:
	TranslationServer.set_locale(settings.get("language", "pt_BR"))
	var bus_names := {"Master": "master", "Music": "music", "SFX": "sfx"}
	for bus in bus_names:
		var idx := AudioServer.get_bus_index(bus)
		if idx >= 0:
			var v: float = settings.get(bus_names[bus], 1.0)
			AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(v, 0.0001)))
			AudioServer.set_bus_mute(idx, v <= 0.001)
	if not Engine.is_editor_hint() and DisplayServer.get_name() != "headless":
		var want_fs: bool = settings.get("fullscreen", false)
		var mode := DisplayServer.window_get_mode()
		var is_fs := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		if want_fs != is_fs:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if want_fs else DisplayServer.WINDOW_MODE_WINDOWED)


func _save_settings() -> void:
	var cf := ConfigFile.new()
	for k in settings:
		cf.set_value("settings", k, settings[k])
	cf.save(SETTINGS_PATH)


func _load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(SETTINGS_PATH) != OK:
		var loc := OS.get_locale()
		settings.language = "pt_BR" if loc.begins_with("pt") else "en"
		return
	for k in settings:
		settings[k] = cf.get_value("settings", k, settings[k])

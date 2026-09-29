extends Node
## Sound manager: pooled one-shots (2D for UI, 3D for the world), random
## variants with pitch jitter, and layered adaptive music (calm + combat).

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const POOL_2D := 16
const POOL_3D := 32

var _streams := {}
var _pool_2d: Array[AudioStreamPlayer] = []
var _pool_3d: Array[AudioStreamPlayer3D] = []
var _next_2d := 0
var _next_3d := 0
var _last_played := {}

var _music_calm: AudioStreamPlayer
var _music_combat: AudioStreamPlayer
var _music_id := ""
var _intensity := 0.0
var _intensity_target := 0.0
var _music_duck := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_2D:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_pool_2d.append(p)
	for i in POOL_3D:
		var p := AudioStreamPlayer3D.new()
		p.bus = &"SFX"
		p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED
		p.panning_strength = 0.6
		p.max_polyphony = 1
		add_child(p)
		_pool_3d.append(p)
	_music_calm = AudioStreamPlayer.new()
	_music_combat = AudioStreamPlayer.new()
	for m in [_music_calm, _music_combat]:
		m.bus = &"Music"
		m.volume_db = -80.0
		add_child(m)
	_index_sfx()


## Finds every "name.wav" and "name_N.wav" and groups variants under "name".
func _index_sfx() -> void:
	var dir := DirAccess.open(SFX_DIR)
	if dir == null:
		return
	for f in dir.get_files():
		var file := f.trim_suffix(".import").trim_suffix(".remap")
		if not (file.ends_with(".wav") or file.ends_with(".ogg")):
			continue
		var base := file.get_basename()
		var parts := base.rsplit("_", true, 1)
		var key := base
		if parts.size() == 2 and parts[1].is_valid_int():
			key = parts[0]
		if not _streams.has(key):
			_streams[key] = []
		var path := SFX_DIR + file
		if not (_streams[key] as Array).has(path):
			_streams[key].append(path)


func has_sound(sfx: String) -> bool:
	return _streams.has(sfx)


func _stream(sfx: String) -> AudioStream:
	var list: Array = _streams.get(sfx, [])
	if list.is_empty():
		return null
	var v = list[randi() % list.size()]
	if v is String:
		var s: AudioStream = load(v)
		var i := list.find(v)
		list[i] = s
		return s
	return v


## Throttles identical sounds so 30 simultaneous hits do not become noise.
func _throttled(sfx: String, min_gap_ms: int) -> bool:
	var now := Time.get_ticks_msec()
	if now - int(_last_played.get(sfx, -10000)) < min_gap_ms:
		return true
	_last_played[sfx] = now
	return false


func ui(sfx: String, volume_db := 0.0, pitch := 1.0) -> void:
	var s := _stream(sfx)
	if s == null:
		return
	var p := _pool_2d[_next_2d]
	_next_2d = (_next_2d + 1) % POOL_2D
	p.stream = s
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()


func play(sfx: String, pos = null, volume_db := 0.0, pitch := 1.0, jitter := 0.07, min_gap_ms := 30) -> void:
	if _throttled(sfx, min_gap_ms):
		return
	var s := _stream(sfx)
	if s == null:
		return
	var pitch_final := pitch * randf_range(1.0 - jitter, 1.0 + jitter)
	if pos is Vector3:
		var p := _pool_3d[_next_3d]
		_next_3d = (_next_3d + 1) % POOL_3D
		p.stream = s
		p.global_position = pos
		p.volume_db = volume_db
		p.pitch_scale = pitch_final
		p.play()
	else:
		var p := _pool_2d[_next_2d]
		_next_2d = (_next_2d + 1) % POOL_2D
		p.stream = s
		p.volume_db = volume_db
		p.pitch_scale = pitch_final
		p.play()


# --- Music ---------------------------------------------------------------------------
func music(id: String) -> void:
	if id == _music_id:
		return
	_music_id = id
	var calm_path := MUSIC_DIR + id + "_calm.ogg"
	var combat_path := MUSIC_DIR + id + "_combat.ogg"
	_music_calm.stream = load(calm_path) if ResourceLoader.exists(calm_path) else null
	_music_combat.stream = load(combat_path) if ResourceLoader.exists(combat_path) else null
	for m in [_music_calm, _music_combat]:
		if m.stream is AudioStreamOggVorbis:
			(m.stream as AudioStreamOggVorbis).loop = true
		elif m.stream is AudioStreamWAV:
			(m.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	# Stems start on the same frame so calm and combat stay locked together.
	for m in [_music_calm, _music_combat]:
		if m.stream:
			m.play()
		else:
			m.stop()


func set_intensity(v: float) -> void:
	_intensity_target = clampf(v, 0.0, 1.0)


## Muffles the music (e.g. while a grimoire is open or the game is paused).
func duck(on: bool) -> void:
	_music_duck = 1.0 if on else 0.0


var _duck_level := 0.0


func _process(delta: float) -> void:
	var real_dt := delta / maxf(Engine.time_scale, 0.001)
	_intensity = move_toward(_intensity, _intensity_target, real_dt * 0.5)
	_music_calm.volume_db = linear_to_db(maxf(0.0001, 1.0 - _intensity * 0.35))
	_music_combat.volume_db = linear_to_db(maxf(0.0001, _intensity))
	_duck_level = move_toward(_duck_level, _music_duck, real_dt * 3.0)
	var bus := AudioServer.get_bus_index(&"Music")
	if bus >= 0 and AudioServer.get_bus_effect_count(bus) > 0:
		var lp := AudioServer.get_bus_effect(bus, 0) as AudioEffectLowPassFilter
		if lp:
			lp.cutoff_hz = lerpf(20000.0, 900.0, _duck_level)

extends Node
## Relics: passive treasures. Stat relics change a knight's numbers when
## taken; triggered relics listen to the Events bus.

const DATA := {
	"tallow": {"rarity": 0, "stat": {"max_hp": 20.0}},
	"bookmark": {"rarity": 1, "stat": {"dash_charges": 1.0}},
	"spectacles": {"rarity": 0, "stat": {"crit": 0.12}},
	"inkwell": {"rarity": 1, "stat": {"haste": -0.12}},
	"whetstone": {"rarity": 0, "stat": {"might": 0.15}},
	"boots": {"rarity": 0, "stat": {"speed": 0.12}},
	"gilded_nib": {"rarity": 0, "stat": {"ink_flow": 0.1}},
	"armor": {"rarity": 1, "stat": {"armor": 2.0}},
	"purse": {"rarity": 0, "stat": {"gold_mult": 0.35}},
	"lens": {"rarity": 1, "stat": {"crit_mult": 0.5}},
	"phoenix": {"rarity": 2},
	"broken_seal": {"rarity": 2},
	"coal": {"rarity": 1},
	"amber": {"rarity": 1},
	"thunder_collar": {"rarity": 1},
	"twin_tome": {"rarity": 1, "coop": true},
	"ribbon": {"rarity": 0, "coop": true},
	"candle_stub": {"rarity": 0},
	"vampire_quill": {"rarity": 1},
	"sharp_margins": {"rarity": 1},
	"echo_shell": {"rarity": 2},
	"ink_heart": {"rarity": 1},
	"sealing_wax": {"rarity": 1},
	"wanderer_map": {"rarity": 2},
}

var _seal_ready := {}
var _wax_cd := {}
var _phoenix_used := {}


func _ready() -> void:
	Events.perfect_dodge.connect(_on_perfect_dodge)
	Events.spell_cast.connect(_on_spell_cast)
	Events.enemy_killed.connect(_on_enemy_killed)
	Events.room_cleared.connect(_on_room_cleared)
	Events.melee_hit.connect(_on_melee_hit)
	Events.player_damaged.connect(_on_player_damaged)
	Events.player_downed.connect(_on_player_downed)
	Events.dashed.connect(_on_dashed)


static func title(id: String) -> String:
	return TranslationServer.translate("R_%s" % id.to_upper())


static func desc(id: String) -> String:
	return TranslationServer.translate("R_%s_DESC" % id.to_upper())


static func price(id: String) -> int:
	return [80, 130, 190][int(DATA[id].rarity)]


func give(profile: PlayerProfile, id: String) -> void:
	if profile.relics.has(id):
		return
	profile.relics.append(id)
	var st: Dictionary = DATA[id].get("stat", {})
	for k in st:
		profile.add_stat(k, float(st[k]))
	if id == "ink_heart" and Game.run:
		Game.run.revive_stock += 1
	if profile.actor and is_instance_valid(profile.actor):
		profile.actor.max_hp = profile.stat("max_hp")
		profile.actor.hp = profile.hp


func has(profile: PlayerProfile, id: String) -> bool:
	return profile != null and profile.relics.has(id)


## Extra outgoing damage multiplier from relics (checked by spells and the quill).
func damage_mult(profile: PlayerProfile, target: Node3D) -> float:
	if profile == null:
		return 1.0
	var m := 1.0
	if profile.relics.has("coal") and target and target.status.burning():
		m *= 1.25
	if profile.relics.has("ribbon") and profile.actor:
		for p in Combat.players:
			if p != profile.actor and not p.downed and Combat.flat_dist(p.global_position, profile.actor.global_position) < 5.0:
				m *= 1.15
				break
	return m


func roll_choices(rng: RandomNumberGenerator, n: int, exclude: Array) -> Array[String]:
	var pool: Array[String] = []
	var coop := Game.profiles.size() > 1
	for id in DATA:
		if exclude.has(id):
			continue
		if DATA[id].get("coop", false) and not coop:
			continue
		var w: int = [6, 3, 1][int(DATA[id].rarity)]
		for i in w:
			pool.append(id)
	var out: Array[String] = []
	while out.size() < n and not pool.is_empty():
		var id: String = pool[rng.randi() % pool.size()]
		out.append(id)
		pool.assign(pool.filter(func(x): return x != id))
	return out


# --- hooks ---------------------------------------------------------------------------
func _on_perfect_dodge(p: Node3D) -> void:
	if has(p.profile, "broken_seal"):
		_seal_ready[p.profile.index] = true


func _on_spell_cast(p: Node3D, prog: SpellProgram, page: int) -> void:
	var pr: PlayerProfile = p.profile if p.get("profile") else null
	if pr == null:
		return
	if _seal_ready.get(pr.index, false):
		_seal_ready[pr.index] = false
		Level.current.after(0.22, func():
			if is_instance_valid(p) and not p.downed:
				var c := SpellCast.make(p, pr, prog, p.aim_point)
				c.is_copy = true
				SpellRunner.cast(c, p.global_position, p.aim_dir))
	if has(pr, "echo_shell") and randf() < 0.15:
		Level.current.after(0.34, func():
			if is_instance_valid(p) and not p.downed:
				var c := SpellCast.make(p, pr, prog, p.aim_point)
				c.power_mult = 0.6
				c.is_copy = true
				SpellRunner.cast(c, p.global_position, p.aim_dir))
	for other in Combat.players:
		if other != p and has(other.profile, "twin_tome"):
			for i in 3:
				other.cooldowns[i] = maxf(0.0, other.cooldowns[i] - 0.25)


func _on_enemy_killed(e: Node3D, hit: Hit) -> void:
	if hit == null or hit.profile == null:
		return
	if has(hit.profile, "amber") and e.status.frozen():
		for o in Combat.enemies_near(e.global_position, 2.8):
			o.status.add_chill(2, o.is_boss)
			var h := Hit.make(10.0 * hit.profile.stat("might"), hit.source, o.global_position, "reaction")
			h.no_proc = true
			o.take_hit(h)
		SpellFx.shatter(e.global_position)


func _on_room_cleared() -> void:
	# The Phoenix Quill recharges at the start of every chapter.
	if Game.run and Game.run.page == 0:
		_phoenix_used.clear()
	for p in Combat.players:
		if has(p.profile, "candle_stub") and not p.downed:
			p.heal(p.profile.stat("max_hp") * 0.08)


func _on_melee_hit(p: Node3D, _e: Node3D, _h: Hit) -> void:
	if has(p.profile, "vampire_quill"):
		p.heal(1.0)


func _on_player_damaged(p: Node3D, _h: Hit) -> void:
	var pr: PlayerProfile = p.profile
	if has(pr, "sealing_wax"):
		var now := Time.get_ticks_msec()
		if now - int(_wax_cd.get(pr.index, -99999)) > 5000:
			_wax_cd[pr.index] = now
			p.add_shield(6.0, 3.0)


func _on_player_downed(p: Node3D) -> void:
	var pr: PlayerProfile = p.profile
	if has(pr, "phoenix") and not _phoenix_used.get(pr.index, false):
		_phoenix_used[pr.index] = true
		Level.current.after(0.8, func():
			if is_instance_valid(p) and p.downed:
				p.revive(0.5)
				Fx.text_pop(p.global_position + Vector3.UP * 2.6, tr("R_PHOENIX"), Pal.EMBER_HOT, 44))


func _on_dashed(p: Node3D) -> void:
	if not has(p.profile, "sharp_margins"):
		return
	Level.current.after(0.08, func():
		if is_instance_valid(p):
			for e in Combat.enemies_near(p.global_position, 1.4):
				var h := Hit.make(8.0 * p.profile.stat("might"), p, e.global_position, "melee")
				h.profile = p.profile
				e.take_hit(h)
				Fx.burst(e.global_position + Vector3.UP, "ink", Pal.INK, Pal.INK_SOFT, 6, 0.6))

class_name PlayerProfile
extends RefCounted
## One joined knight: device, grimoire, relics and run-scoped stats.

const BASE_STATS := {
	"max_hp": 60.0,
	"might": 1.0,        # damage multiplier
	"haste": 1.0,        # cooldown multiplier (lower is faster)
	"crit": 0.05,
	"crit_mult": 2.0,
	"speed": 1.0,
	"dash_charges": 2.0,
	"dash_cd": 0.9,
	"ink_flow": 0.12,    # seconds removed from spell cooldowns per quill hit
	"heal_mult": 1.0,
	"armor": 0.0,        # flat damage reduction
	"gold_mult": 1.0,
}

var index := 0
var input: PlayerInput
var tome := "ember"
var grimoire := Grimoire.new()
var relics: Array[String] = []
var stats := BASE_STATS.duplicate()
var hp := 60.0
var shield := 0.0
## The Player node while one exists in the current level.
var actor: Node3D = null
# Run statistics for the chronicle screen.
var kills := 0
var damage_dealt := 0.0
var casts := 0
var perfect_dodges := 0
var revives_given := 0


func flame_color() -> Color:
	return Pal.player_flame(index)


func cloth_color() -> Color:
	return Pal.player_cloth(index)


func display_name() -> String:
	return "%s %s" % [tr("KNIGHT"), Pal.PLAYER_NAMES[index]]


func setup_from_meta(meta: Dictionary) -> void:
	reset_for_run(meta)


## Fresh stats and grimoire for a new expedition, applying Candelabrum upgrades.
func reset_for_run(meta: Dictionary, rng: RandomNumberGenerator = null) -> void:
	var up: Dictionary = meta.get("upgrades", {})
	stats = BASE_STATS.duplicate()
	stats.max_hp += 10.0 * float(up.get("vitality", 0))
	stats.might += 0.06 * float(up.get("might", 0))
	stats.haste -= 0.05 * float(up.get("quickink", 0))
	stats.dash_charges += float(up.get("feather", 0))
	relics.clear()
	grimoire.setup_tome(tome, int(up.get("margins", 0)), rng)
	hp = stats.max_hp
	shield = 0.0
	kills = 0
	damage_dealt = 0.0
	casts = 0
	perfect_dodges = 0
	revives_given = 0


func stat(key: String) -> float:
	return float(stats.get(key, 0.0))


func add_stat(key: String, amount: float) -> void:
	stats[key] = stat(key) + amount
	if key == "max_hp":
		hp = minf(hp + maxf(amount, 0.0), stat("max_hp"))


func has_relic(id: String) -> bool:
	return relics.has(id)


func heal(amount: float) -> float:
	var before := hp
	hp = minf(stat("max_hp"), hp + amount * stat("heal_mult"))
	return hp - before

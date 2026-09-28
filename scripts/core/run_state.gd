class_name RunState
extends RefCounted
## State of one expedition through the Grimoire.

const CHAPTERS := 3
const PAGES_PER_CHAPTER := 6  # combat/special pages before the boss page

var seed := 0
var rng := RandomNumberGenerator.new()
var chapter := 0
## Index of the page inside the chapter; PAGES_PER_CHAPTER means the boss page.
var page := 0
var gold := 0
var embers := 0
var kills := 0
var time := 0.0
var pages_cleared := 0
var revive_stock := 0
var won := false
## The page the knights are about to enter: {"kind": String, "reward": String}
var next_room := {"kind": "combat", "reward": "glyph"}
var history: Array[Dictionary] = []
## Relics already offered/taken this run (no duplicates).
var relics_seen: Array[String] = []


func start(p_seed: int, meta: Dictionary) -> void:
	seed = p_seed
	rng.seed = p_seed
	chapter = 0
	page = 0
	gold = 0
	embers = 0
	kills = 0
	time = 0.0
	pages_cleared = 0
	won = false
	revive_stock = int(meta.get("upgrades", {}).get("reserve", 0))
	next_room = {"kind": "combat", "reward": "glyph"}
	history.clear()
	relics_seen.clear()


func is_boss_page() -> bool:
	return page >= PAGES_PER_CHAPTER


## 0..1 progress used to scale enemy budgets.
func difficulty() -> float:
	return (chapter * (PAGES_PER_CHAPTER + 1) + page) / float(CHAPTERS * (PAGES_PER_CHAPTER + 1))


func chapter_id() -> String:
	return ["grove", "catacombs", "inksea"][clampi(chapter, 0, CHAPTERS - 1)]


## Rolls the exits of the page just cleared: [{"kind", "reward"}, ...].
## Mirrors Hades/Ember Knights: you see the reward before choosing the door.
func roll_doors(team_hp_ratio: float, extra_choice := false) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var next := page + 1
	if next >= PAGES_PER_CHAPTER:
		out.append({"kind": "boss", "reward": "boss"})
		return out
	if next == PAGES_PER_CHAPTER - 1:
		out.append({"kind": "rest", "reward": "heal"})
		out.append({"kind": "shop", "reward": "shop"})
		return out
	var weights := {
		"glyph": 5.0, "relic": 3.0, "gold": 2.0, "page": 1.4,
		"heal": 2.5 if team_hp_ratio < 0.5 else 0.7,
		"shop": 1.0 if next >= 2 else 0.0,
		"elite": 1.2 if next >= 2 else 0.0,
	}
	var n := 3 if extra_choice else 2
	while out.size() < n:
		var total := 0.0
		for k in weights:
			total += float(weights[k])
		if total <= 0.0:
			break
		var roll := rng.randf() * total
		var pick := ""
		for k in weights:
			roll -= float(weights[k])
			if roll <= 0.0:
				pick = k
				break
		if pick == "":
			pick = "glyph"
		weights[pick] = 0.0
		match pick:
			"heal":
				out.append({"kind": "rest", "reward": "heal"})
			"shop":
				out.append({"kind": "shop", "reward": "shop"})
			"elite":
				out.append({"kind": "elite", "reward": "relic"})
			_:
				out.append({"kind": "combat", "reward": pick})
	return out


func advance(door: Dictionary) -> void:
	history.append({"chapter": chapter, "page": page, "kind": next_room.kind})
	pages_cleared += 1
	next_room = door
	if door.kind == "boss":
		page = PAGES_PER_CHAPTER
	else:
		page += 1


func advance_chapter() -> bool:
	chapter += 1
	page = 0
	if chapter >= CHAPTERS:
		won = true
		return false
	next_room = {"kind": "combat", "reward": "glyph"}
	return true

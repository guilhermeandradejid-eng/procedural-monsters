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

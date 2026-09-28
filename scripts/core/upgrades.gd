class_name Upgrades
extends RefCounted
## The Candelabrum: permanent upgrades bought with Embers between runs.

const LIST := {
	"vitality": {"max": 5, "costs": [30, 60, 90, 130, 170]},
	"might": {"max": 5, "costs": [40, 80, 120, 160, 200]},
	"quickink": {"max": 4, "costs": [50, 100, 150, 200]},
	"feather": {"max": 1, "costs": [150]},
	"margins": {"max": 2, "costs": [120, 240]},
	"reserve": {"max": 3, "costs": [100, 200, 300]},
	"lexicon": {"max": 3, "costs": [80, 160, 240]},
	"tome_blank": {"max": 1, "costs": [60]},
}

## Glyphs added to the loot pool by each Lexicon level.
const LEXICON := [
	["orbit", "totem", "blink", "void", "radiant"],
	["meteor", "vortex", "linger", "spiral", "magnet", "chain"],
	["leech", "ward", "sharpen", "on_kill", "pulse"],
]

const ORDER := ["vitality", "might", "quickink", "feather", "margins", "reserve", "lexicon", "tome_blank"]


static func level(id: String) -> int:
	return Game.upgrade_level(id)


static func next_cost(id: String) -> int:
	var lv := level(id)
	var costs: Array = LIST[id].costs
	return -1 if lv >= int(LIST[id].max) else int(costs[lv])


static func buy(id: String) -> bool:
	var cost := next_cost(id)
	if cost < 0 or int(Game.meta.embers) < cost:
		return false
	Game.add_embers(-cost)
	var up: Dictionary = Game.meta.get("upgrades", {})
	up[id] = level(id) + 1
	Game.meta.upgrades = up
	if id == "lexicon":
		var pool: Array = Game.meta.get("unlocked_glyphs", [])
		for g in LEXICON[level(id) - 1]:
			if not pool.has(g):
				pool.append(g)
		Game.meta.unlocked_glyphs = pool
	if id == "tome_blank":
		var tomes: Array = Game.meta.get("tomes", [])
		if not tomes.has("blank"):
			tomes.append("blank")
		Game.meta.tomes = tomes
	Game.save_meta()
	return true


static func title(id: String) -> String:
	return TranslationServer.translate("U_%s" % id.to_upper())


static func desc(id: String) -> String:
	return TranslationServer.translate("U_%s_DESC" % id.to_upper())

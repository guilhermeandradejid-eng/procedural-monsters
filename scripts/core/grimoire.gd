class_name Grimoire
extends RefCounted
## A knight's spellbook: three pages of glyph slots plus a satchel of loose
## glyphs. Pages compile into SpellPrograms whenever they change.

signal changed(page: int)

const PAGE_COUNT := 3
const BASE_SLOTS := 4
const MAX_SLOTS := 8

## Starting books ("tomes") — the equivalent of a starting weapon choice.
const TOMES := {
	"ember": {"pages": [["bolt", "ember"], ["nova", "ember"], []], "satchel": ["split"]},
	"winter": {"pages": [["lance", "frost"], ["mine", "frost"], []], "satchel": ["pierce"]},
	"storm": {"pages": [["chakram", "storm"], ["rain", "storm"], []], "satchel": ["seek"]},
	"blank": {"pages": [[], [], []], "satchel": []},
}

var pages: Array = []
var satchel: Array[String] = []
var programs: Array[SpellProgram] = []


func _init() -> void:
	for i in PAGE_COUNT:
		pages.append(_blank_page(BASE_SLOTS))
		programs.append(SpellProgram.compile([]))


static func _blank_page(n: int) -> Array[String]:
	var p: Array[String] = []
	p.resize(n)
	p.fill("")
	return p


func setup_tome(tome_id: String, extra_slots := 0, rng: RandomNumberGenerator = null) -> void:
	var tome: Dictionary = TOMES.get(tome_id, TOMES["ember"])
	pages.clear()
	for i in PAGE_COUNT:
		var page := _blank_page(BASE_SLOTS + extra_slots)
		var src: Array = tome.pages[i]
		for j in mini(src.size(), page.size()):
			page[j] = src[j]
		pages.append(page)
	satchel.clear()
	for g in tome.satchel:
		satchel.append(g)
	if tome_id == "blank" and rng:
		# The blank tome trades a ready spell for more raw material.
		var pool := ["bolt", "nova", "orb", "wave", "ember", "frost", "storm", "split", "echo", "on_hit"]
		for i in 5:
			satchel.append(pool[rng.randi() % pool.size()])
	compile_all()


func capacity(page: int) -> int:
	return (pages[page] as Array).size()


func slot(page: int, idx: int) -> String:
	var p: Array = pages[page]
	return p[idx] if idx >= 0 and idx < p.size() else ""


func set_slot(page: int, idx: int, id: String) -> void:
	pages[page][idx] = id
	compile(page)


## Moves a glyph from the satchel into a page slot. The previous occupant goes back to the satchel.
func place_from_satchel(satchel_idx: int, page: int, idx: int) -> void:
	if satchel_idx < 0 or satchel_idx >= satchel.size():
		return
	var id: String = satchel[satchel_idx]
	satchel.remove_at(satchel_idx)
	var prev := slot(page, idx)
	if prev != "":
		satchel.insert(mini(satchel_idx, satchel.size()), prev)
	set_slot(page, idx, id)


func lift_to_satchel(page: int, idx: int) -> void:
	var prev := slot(page, idx)
	if prev == "":
		return
	satchel.append(prev)
	set_slot(page, idx, "")


func swap_slots(page_a: int, idx_a: int, page_b: int, idx_b: int) -> void:
	var a := slot(page_a, idx_a)
	var b := slot(page_b, idx_b)
	pages[page_a][idx_a] = b
	pages[page_b][idx_b] = a
	compile(page_a)
	if page_b != page_a:
		compile(page_b)


func add_glyph(id: String) -> void:
	satchel.append(id)
	changed.emit(-1)


func expand(page: int) -> bool:
	if capacity(page) >= MAX_SLOTS:
		return false
	(pages[page] as Array).append("")
	compile(page)
	return true


func compile(page: int) -> void:
	programs[page] = SpellProgram.compile(pages[page])
	changed.emit(page)


func compile_all() -> void:
	for i in PAGE_COUNT:
		programs[i] = SpellProgram.compile(pages[i])
	changed.emit(-1)


func program(page: int) -> SpellProgram:
	return programs[page]


func glyph_count() -> int:
	var n := satchel.size()
	for p in pages:
		for g in p:
			if g != "":
				n += 1
	return n


func to_dict() -> Dictionary:
	return {"pages": pages.duplicate(true), "satchel": satchel.duplicate()}

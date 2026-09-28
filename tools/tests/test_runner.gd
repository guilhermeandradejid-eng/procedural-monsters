extends Node
## Headless test runner: `godot --headless --path . res://tools/tests/test_runner.tscn`
## Exits with code 0 when every check passes, 1 otherwise.

var failures := 0
var checks := 0


func _ready() -> void:
	await get_tree().process_frame
	test_compiler_basics()
	test_fusions()
	test_names()
	test_fuzz_compile(3000)
	print("\n%d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures > 0 else 0)


func check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		push_error("FAIL: " + msg)
		print("FAIL: ", msg)


func test_compiler_basics() -> void:
	var p := SpellProgram.compile(["bolt", "ember", "split", "on_hit", "nova", "frost", "echo"])
	check(p.clauses().size() == 2, "two clauses from one link")
	check(p.root.forms == ["bolt"], "root form is bolt")
	check(p.root.element == "ember", "root element ember")
	check(p.root.mod("split") == 1, "split stacked once")
	check(p.root.link == "on_hit", "link on_hit")
	check(p.root.child.element == "frost", "payload frost")
	check(p.root.child.power < p.root.power, "payload weaker than root")
	check(p.cooldown > 0.3 and p.cooldown < 14.0, "cooldown in range: %f" % p.cooldown)

	var implicit := SpellProgram.compile(["ember", "ember", "", "grow"])
	check(implicit.root.forms == ["bolt"] and implicit.root.implicit_form, "implicit bolt")
	check(implicit.root.intensity == 2, "ember intensity 2")
	check(implicit.has_note("implicit_form"), "implicit note")

	var dangling := SpellProgram.compile(["nova", "then"])
	check(dangling.root.child == null and dangling.root.link == "", "dangling link removed")
	check(dangling.has_note("dangling_link"), "dangling note")

	var blank := SpellProgram.compile(["", "", ""])
	check(blank.empty, "blank program empty")

	var deep := SpellProgram.compile(["bolt", "on_hit", "bolt", "on_hit", "bolt", "on_hit", "bolt", "on_hit", "bolt"])
	check(deep.depth() == GlyphDB.MAX_DEPTH + 1, "depth capped at %d, got %d" % [GlyphDB.MAX_DEPTH + 1, deep.depth()])
	check(deep.has_note("too_deep"), "too deep note")

	var multi := SpellProgram.compile(["bolt", "nova", "storm"])
	check(multi.root.forms.size() == 2, "multicast forms")

	var same_a := SpellProgram.compile(["bolt", "", "ember"])
	var same_b := SpellProgram.compile(["", "bolt", "ember", ""])
	check(same_a.seed == same_b.seed, "seed ignores blank slots")


func test_fusions() -> void:
	var seen := {}
	for a in Elem.BASE:
		for b in Elem.BASE:
			if a == b:
				continue
			var r := Elem.resolve([a, b])
			check(Elem.PALETTES.has(r.key), "palette for fusion %s" % r.key)
			seen[r.key] = true
			check(Elem.resolve([b, a]).key == r.key, "fusion symmetric %s+%s" % [a, b])
	check(seen.size() == 15, "15 fusions, got %d" % seen.size())


func test_names() -> void:
	for loc in ["pt_BR", "en"]:
		TranslationServer.set_locale(loc)
		var p := SpellProgram.compile(["bolt", "ember", "split", "on_hit", "nova", "frost", "on_end", "rain"])
		var n := SpellNamer.name_program(p, loc)
		var s := SpellNamer.sentence(p, loc)
		print("[%s] %s — %s" % [loc, n, s])
		check(n.length() > 3, "name not empty (%s)" % loc)
		check(s.ends_with("."), "sentence ends with period (%s)" % loc)


func test_fuzz_compile(n: int) -> void:
	var ids := GlyphDB.all_ids()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var names := {}
	for i in n:
		var len := rng.randi_range(0, 8)
		var src: Array = []
		for j in len:
			src.append("" if rng.randf() < 0.15 else ids[rng.randi() % ids.size()])
		var p := SpellProgram.compile(src)
		check(p.root != null, "root exists")
		check(p.cooldown >= SpellProgram.MIN_COOLDOWN and p.cooldown <= SpellProgram.MAX_COOLDOWN, "cooldown clamp")
		check(p.depth() <= GlyphDB.MAX_DEPTH + 1, "depth limit")
		for c in p.clauses():
			check(not c.forms.is_empty(), "every clause has a form")
			check(Elem.PALETTES.has(c.element), "known element %s" % c.element)
		names[p.display_name()] = true
	print("fuzz: %d programs, %d distinct names" % [n, names.size()])

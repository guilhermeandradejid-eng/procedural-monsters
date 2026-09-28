class_name SigilBank
extends Node
## Bakes sigils into textures with a small pool of SubViewports (GPU drawn,
## refreshed once). The 3D magic circles use these, so the circle on the floor
## is exactly the sigil inked in the grimoire.

const SIZE := 256
const POOL := 40

var _entries := {}
var _clock := 0


class SigilDrawer:
	extends Node2D
	var spec := {}

	func _draw() -> void:
		if spec.is_empty():
			return
		var c := Vector2(SigilBank.SIZE, SigilBank.SIZE) * 0.5
		SigilArt.draw(self, spec, c, SigilBank.SIZE * 0.42, Color.WHITE, 1.0, 3.2)


func for_program(p: SpellProgram) -> Texture2D:
	return _fetch("p%d" % p.seed, func(): return SigilArt.spec(p))


func for_clause(c: SpellClause) -> Texture2D:
	return _fetch("c%d" % c.seed, func(): return SigilArt.spec_clause(c))


func _fetch(key: String, make_spec: Callable) -> Texture2D:
	_clock += 1
	if _entries.has(key):
		_entries[key].used = _clock
		return _entries[key].vp.get_texture()
	var vp: SubViewport = null
	var drawer: SigilDrawer = null
	if _entries.size() >= POOL:
		var oldest := ""
		var oldest_t := 1 << 62
		for k in _entries:
			if _entries[k].used < oldest_t:
				oldest_t = _entries[k].used
				oldest = k
		vp = _entries[oldest].vp
		drawer = _entries[oldest].drawer
		_entries.erase(oldest)
	else:
		vp = SubViewport.new()
		vp.size = Vector2i(SIZE, SIZE)
		vp.transparent_bg = true
		vp.disable_3d = true
		vp.msaa_2d = Viewport.MSAA_4X
		vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
		add_child(vp)
		drawer = SigilDrawer.new()
		vp.add_child(drawer)
	drawer.spec = make_spec.call()
	drawer.queue_redraw()
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	_entries[key] = {"vp": vp, "drawer": drawer, "used": _clock}
	return vp.get_texture()

class_name SigilBank
extends Node
## Bakes sigils into textures with a small pool of SubViewports (GPU drawn,
## refreshed once). The 3D magic circles use these, so the circle on the floor
## is exactly the sigil inked in the grimoire.

const SIZE := 256

## Texture size and pool capacity (the icon bank uses smaller textures).
var tex_size := 256
var pool := 48
var _entries := {}
var _clock := 0


class SigilDrawer:
	extends Node2D
	var spec := {}
	var px := 256.0

	func _draw() -> void:
		if spec.is_empty():
			return
		var c := Vector2(px, px) * 0.5
		if spec.has("glyph"):
			var g := px * 0.82
			Quill.draw_strokes(self, GlyphArt.strokes(spec.glyph), Rect2(c - Vector2(g, g) * 0.5, Vector2(g, g)), px * 0.055, Color.WHITE, 0.55, 0.4, hash(spec.glyph))
			return
		if spec.has("icon"):
			var s := px * 0.62
			Quill.stroke(self, Quill.arc_points(c, px * 0.46, 0.0, TAU + 0.05, 64), px * 0.02, Color.WHITE, 0.1)
			Quill.stroke(self, Quill.arc_points(c, px * 0.41, 0.0, TAU + 0.05, 64), px * 0.008, Color.WHITE, 0.1)
			Quill.draw_strokes(self, GlyphArt.strokes(spec.icon), Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s)), px * 0.035, Color.WHITE, 0.55)
			return
		SigilArt.draw(self, spec, c, px * 0.42, Color.WHITE, 1.0, px * 0.0125)


func for_program(p: SpellProgram) -> Texture2D:
	return _fetch("p%d" % p.seed, func(): return SigilArt.spec(p))


func for_clause(c: SpellClause) -> Texture2D:
	return _fetch("c%d" % c.seed, func(): return SigilArt.spec_clause(c))


## A framed icon (reward types, glyphs) baked like a sigil.
func for_icon(id: String) -> Texture2D:
	return _fetch("i" + id, func(): return {"icon": id})


## A bare glyph drawing (no frame), for tiles in the grimoire.
func for_glyph(id: String) -> Texture2D:
	return _fetch("g" + id, func(): return {"glyph": id})


func _fetch(key: String, make_spec: Callable) -> Texture2D:
	_clock += 1
	if _entries.has(key):
		_entries[key].used = _clock
		return _entries[key].vp.get_texture()
	var vp: SubViewport = null
	var drawer: SigilDrawer = null
	if _entries.size() >= pool:
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
		vp.size = Vector2i(tex_size, tex_size)
		vp.transparent_bg = true
		vp.disable_3d = true
		vp.msaa_2d = Viewport.MSAA_4X
		vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
		add_child(vp)
		drawer = SigilDrawer.new()
		drawer.px = tex_size
		vp.add_child(drawer)
	drawer.spec = make_spec.call()
	drawer.queue_redraw()
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	_entries[key] = {"vp": vp, "drawer": drawer, "used": _clock}
	return vp.get_texture()

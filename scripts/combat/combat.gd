class_name Combat
extends RefCounted
## Spatial queries on the ground plane. The game plays on XZ, so most checks
## are cheap circle/segment tests against registered actors instead of
## physics areas; walls use real raycasts.

const LAYER_WORLD := 1
const LAYER_PLAYERS := 2
const LAYER_ENEMIES := 4

static var enemies: Array[Node3D] = []
static var players: Array[Node3D] = []


static func flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


static func flat_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


static func register_enemy(e: Node3D) -> void:
	if not enemies.has(e):
		enemies.append(e)


static func unregister_enemy(e: Node3D) -> void:
	enemies.erase(e)


static func register_player(p: Node3D) -> void:
	if not players.has(p):
		players.append(p)


static func unregister_player(p: Node3D) -> void:
	players.erase(p)


static func _alive(a: Node3D) -> bool:
	return is_instance_valid(a) and a.is_inside_tree() and not a.get("dead")


static func enemies_near(pos: Vector3, r: float) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for e in enemies:
		if _alive(e) and e.targetable() and flat_dist(e.global_position, pos) <= r + e.radius:
			out.append(e)
	return out


static func nearest_enemy(pos: Vector3, max_r := 999.0, exclude: Array = []) -> Node3D:
	var best: Node3D = null
	var best_d := max_r
	for e in enemies:
		if not _alive(e) or not e.targetable() or exclude.has(e):
			continue
		var d := flat_dist(e.global_position, pos)
		if d < best_d:
			best_d = d
			best = e
	return best


## Nearest enemy inside a cone around `dir` (used for aim assist and seeking).
static func enemy_in_cone(pos: Vector3, dir: Vector3, max_r: float, cos_half: float, exclude: Array = []) -> Node3D:
	var best: Node3D = null
	var best_score := -INF
	var fd := flat(dir).normalized()
	for e in enemies:
		if not _alive(e) or not e.targetable() or exclude.has(e):
			continue
		var to := flat(e.global_position - pos)
		var d := to.length()
		if d > max_r or d < 0.001:
			continue
		var c := fd.dot(to / d)
		if c < cos_half:
			continue
		var score := c * 2.0 - d / max_r
		if score > best_score:
			best_score = score
			best = e
	return best


static func players_near(pos: Vector3, r: float, include_downed := false) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for p in players:
		if not is_instance_valid(p) or not p.is_inside_tree():
			continue
		if p.downed and not include_downed:
			continue
		if flat_dist(p.global_position, pos) <= r + p.radius:
			out.append(p)
	return out


static func nearest_player(pos: Vector3, max_r := 999.0) -> Node3D:
	var best: Node3D = null
	var best_d := max_r
	for p in players:
		if not is_instance_valid(p) or p.downed or not p.targetable():
			continue
		var d := flat_dist(p.global_position, pos)
		if d < best_d:
			best_d = d
			best = p
	return best


## Distance from point p to segment ab on the ground plane.
static func seg_dist(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ap := Vector2(p.x - a.x, p.z - a.z)
	var ab := Vector2(b.x - a.x, b.z - a.z)
	var l2 := ab.length_squared()
	var t := 0.0 if l2 < 0.0001 else clampf(ap.dot(ab) / l2, 0.0, 1.0)
	return (ap - ab * t).length()


static func enemies_on_segment(a: Vector3, b: Vector3, width: float) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for e in enemies:
		if _alive(e) and e.targetable() and seg_dist(e.global_position, a, b) <= width + e.radius:
			out.append(e)
	return out


static func players_on_segment(a: Vector3, b: Vector3, width: float) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for p in players:
		if is_instance_valid(p) and not p.downed and p.targetable() and seg_dist(p.global_position, a, b) <= width + p.radius:
			out.append(p)
	return out


## Raycast against world geometry only. Returns {} when the path is clear.
static func ray(world: World3D, from: Vector3, to: Vector3) -> Dictionary:
	if world == null:
		return {}
	var q := PhysicsRayQueryParameters3D.create(from, to, LAYER_WORLD)
	q.collide_with_areas = false
	return world.direct_space_state.intersect_ray(q)

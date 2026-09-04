class_name TargetingSystem
extends Object
## Static spatial helpers for target queries. Uses a uniform grid registered
## by the EnemyManager (Phase 5) to avoid O(n) global scans per weapon per
## frame. Phase 3 fallback: linear scan over a provided node list, called at
## weapon-cadence (a few times/second), not per-enemy-per-frame.

const CELL_SIZE := 8.0

static func nearest(from: Vector3, candidates: Array, max_dist: float = 40.0) -> Node3D:
	var best: Node3D = null
	var best_d2 := max_dist * max_dist
	for c in candidates:
		if not is_instance_valid(c):
			continue
		var d2: float = from.distance_squared_to(c.global_position)
		if d2 < best_d2:
			best_d2 = d2
			best = c
	return best

static func lowest_health(candidates: Array) -> Node3D:
	var best: Node3D = null
	var best_hp := INF
	for c in candidates:
		if not is_instance_valid(c) or not c.has_method("get_health_ratio"):
			continue
		var hp: float = c.get_health_ratio()
		if hp < best_hp:
			best_hp = hp
			best = c
	return best

static func random_of(candidates: Array) -> Node3D:
	if candidates.is_empty():
		return null
	return candidates[randi() % candidates.size()]

class_name TargetingSystem
extends Object
## Static spatial helpers for target queries. Uses a uniform grid registered
## by the EnemyManager (Phase 5) to avoid O(n) global scans per weapon per
## frame. Phase 3 fallback: linear scan over a provided node list, called at
## weapon-cadence (a few times/second), not per-enemy-per-frame.

const CELL_SIZE := 8.0
## Dot-product threshold for "in front of the camera" (view-cone proxy).
const IN_FRONT_DOT := 0.15

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

## Nearest target the player can actually SEE: prefers enemies in front of
## the camera; falls back to any nearest candidate if none qualify.
static func nearest_visible(from: Vector3, candidates: Array, max_dist: float, camera: Camera3D) -> Node3D:
	if camera == null:
		return nearest(from, candidates, max_dist)
	var cam_forward := -camera.global_transform.basis.z
	var best_front: Node3D = null
	var best_front_d2 := max_dist * max_dist
	var best_any: Node3D = null
	var best_any_d2 := max_dist * max_dist
	for c in candidates:
		if not is_instance_valid(c):
			continue
		var d2: float = from.distance_squared_to(c.global_position)
		if d2 < best_any_d2:
			best_any_d2 = d2
			best_any = c
		var to_c: Vector3 = c.global_position - from
		to_c.y = 0.0
		if to_c.length_squared() < 0.01:
			continue
		if cam_forward.dot(to_c.normalized()) > IN_FRONT_DOT and d2 < best_front_d2:
			best_front_d2 = d2
			best_front = c
	return best_front if best_front != null else best_any

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

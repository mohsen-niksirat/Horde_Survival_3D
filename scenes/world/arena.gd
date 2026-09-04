extends Node3D
## Arena environment script. Holds spawn-point helpers used by spawning
## systems (Phase 5+).

const HALF_SIZE := 60.0
const SPAWN_RING_MIN := 35.0
const SPAWN_RING_MAX := 45.0

## Returns a random spawn position on a ring around a center point,
## clamped inside the arena.
func get_spawn_position(around: Vector3) -> Vector3:
	var angle := randf() * TAU
	var dist := randf_range(SPAWN_RING_MIN, SPAWN_RING_MAX)
	var pos := around + Vector3(cos(angle), 0, sin(angle)) * dist
	pos.x = clampf(pos.x, -HALF_SIZE + 2.0, HALF_SIZE - 2.0)
	pos.z = clampf(pos.z, -HALF_SIZE + 2.0, HALF_SIZE - 2.0)
	pos.y = 0.0
	return pos

func is_inside_bounds(pos: Vector3, margin: float = 1.0) -> bool:
	return absf(pos.x) <= HALF_SIZE - margin and absf(pos.z) <= HALF_SIZE - margin

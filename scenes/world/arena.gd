extends Node3D
## Arena environment script. Holds spawn-point helpers used by spawning
## systems (Phase 5+) and instantiates the V4 decoration layer.

const DECOR_SCRIPT := preload("res://scenes/world/arena_decor.gd")
const HALF_SIZE := 60.0
## Spawn ring: close enough that spawned enemies are on/near screen
## (camera sees ~25-35m ahead), far enough to avoid pop-in in the face.
const SPAWN_RING_MIN := 22.0
const SPAWN_RING_MAX := 30.0

func _ready() -> void:
	var decor := Node3D.new()
	decor.name = "ArenaDecor"
	decor.set_script(DECOR_SCRIPT)
	add_child(decor)

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

extends SceneTree
## Task A1 validation: player spawn is clear of the central beacon, lands
## on the ground, camera is attached and no immediate clipping.

var failures := 0

func _initialize() -> void:
	var main_ps: PackedScene = load("res://scenes/main/Main.tscn")
	var main := main_ps.instantiate()
	root.add_child(main)
	for i in range(10):
		await process_frame
		await physics_frame

	var player: CharacterBody3D = main.get_node("World/Player")
	var beacon: Node3D = main.get_node("World/Beacon")

	# --- Spawn distance from beacon (horizontal XZ) ---
	var spawn_xz := Vector2(player.global_position.x, player.global_position.z)
	_check(spawn_xz.length() >= 10.0, "player spawns >= 10m from arena center (dist=%.1f)" % spawn_xz.length())

	# --- No overlap with beacon cylinder (radius 1.8) + player capsule 0.45 ---
	var clearance := spawn_xz.length() - 1.8 - 0.45
	_check(clearance > 0.5, "clearance from beacon > 0.5m (%.1f)" % clearance)

	# --- Player settled on the ground (no clipping through floor) ---
	_check(player.is_on_floor(), "player is on the floor after settling")
	_check(player.global_position.y < 2.0, "player at ground height (y=%.2f)" % player.global_position.y)

	# --- Camera attached and reasonable ---
	var cam: Camera3D = main.get_node("World/Player/CameraRig/SpringArm3D/Camera3D")
	_check(cam != null and cam.current, "player camera is current")
	var dist := cam.global_position.distance_to(player.global_position)
	_check(dist > 2.0 and dist < 16.0, "camera distance sane (%.1f m)" % dist)

	# --- Spawn inside arena bounds ---
	var arena: Node3D = main.get_node("World")
	_check(arena.is_inside_bounds(player.global_position), "spawn inside arena bounds")

	if failures == 0:
		print("TASK_A1_PASS")
	else:
		print("TASK_A1_FAIL failures=", failures)
	quit(0 if failures == 0 else 1)

func _check(cond: bool, label: String) -> void:
	if cond:
		print("OK: ", label)
	else:
		push_error("FAIL: " + label)
		failures += 1

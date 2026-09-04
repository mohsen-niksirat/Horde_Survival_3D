extends SceneTree
## Phase 1 smoke test: load and instantiate all scenes, verify autoloads exist.

func _initialize() -> void:
	var errors := 0

	# Autoload check
	for autoload_name in ["EventBus", "RunManager", "GameManager", "InputManager", "PoolManager", "SaveManager", "AudioManager", "PerformanceManager"]:
		if not root.has_node(autoload_name):
			push_error("Missing autoload: " + autoload_name)
			errors += 1
		else:
			print("OK autoload: ", autoload_name)

	# Scene instantiation check
	for path in [
		"res://scenes/bootstrap/Boot.tscn",
		"res://scenes/menu/MainMenu.tscn",
		"res://scenes/world/Arena.tscn",
		"res://scenes/player/Player.tscn",
		"res://scenes/main/Main.tscn",
	]:
		var ps: PackedScene = load(path)
		if ps == null:
			push_error("Failed to load scene: " + path)
			errors += 1
			continue
		var node := ps.instantiate()
		root.add_child(node)
		await process_frame
		if not is_instance_valid(node):
			push_error("Scene freed itself: " + path)
			errors += 1
		else:
			print("OK scene: ", path)
			node.queue_free()
			await process_frame

	# Arena helper check
	var arena_ps: PackedScene = load("res://scenes/world/Arena.tscn")
	var arena := arena_ps.instantiate()
	root.add_child(arena)
	await process_frame
	var spawn: Vector3 = arena.get_spawn_position(Vector3.ZERO)
	if not arena.is_inside_bounds(spawn):
		push_error("Arena spawn position out of bounds")
		errors += 1
	else:
		print("OK arena spawn: ", spawn)
	arena.queue_free()

	if errors == 0:
		print("PHASE1_SMOKE_PASS")
	else:
		print("PHASE1_SMOKE_FAIL errors=", errors)
	quit(0 if errors == 0 else 1)

extends SceneTree
## V4 validation: arena decoration layer builds (grass, trees, rocks, wall
## pillars) with shared materials, and arena helpers still work.

var failures := 0

func _initialize() -> void:
	var main_ps: PackedScene = load("res://scenes/main/Main.tscn")
	var main := main_ps.instantiate()
	root.add_child(main)
	for i in range(4):
		await process_frame
		await physics_frame

	var decor: Node3D = main.get_node_or_null("World/ArenaDecor")
	_check(decor != null, "decor layer exists")

	_check(decor.get_node_or_null("Grass") != null and decor.get_node("Grass").get_child_count() >= 90, "grass tufts scattered (%d)" % (decor.get_node("Grass").get_child_count() if decor.get_node_or_null("Grass") else 0))
	_check(decor.get_node_or_null("Trees") != null and decor.get_node("Trees").get_child_count() >= 14, "trees placed (%d)" % (decor.get_node("Trees").get_child_count() if decor.get_node_or_null("Trees") else 0))
	_check(decor.get_node_or_null("Rocks") != null and decor.get_node("Rocks").get_child_count() >= 18, "rocks scattered (%d)" % (decor.get_node("Rocks").get_child_count() if decor.get_node_or_null("Rocks") else 0))
	_check(decor.get_node_or_null("WallPillars") != null and decor.get_node("WallPillars").get_child_count() >= 40, "wall pillars + caps (%d)" % (decor.get_node("WallPillars").get_child_count() if decor.get_node_or_null("WallPillars") else 0))

	# --- Props keep combat space open: nothing decorative inside 6m of center ---
	var too_close := 0
	for tree in decor.get_node("Trees").get_children():
		if tree.position.length() < 6.0:
			too_close += 1
	_check(too_close == 0, "no trees near spawn beacon")

	# --- Arena helpers intact ---
	var arena: Node3D = main.get_node("World")
	var spawn: Vector3 = arena.get_spawn_position(Vector3.ZERO)
	_check(arena.is_inside_bounds(spawn), "spawn helper still bounds-checked")

	# --- Decor doesn't break spawning (quick wave sanity) ---
	var em: Node = main.get_node("EnemyManager")
	var game_manager := root.get_node("GameManager")
	game_manager.state = game_manager.State.PLAYING
	main.get_node("WaveManager").stop()
	em.clear_all()
	var test_player: CharacterBody3D = main.get_node("World/Player")
	test_player.experience.xp_to_next = 999999.0
	test_player.experience.current_xp = 0.0
	em.queue_spawn(load("res://data/enemies/basic_drone.tres"), Vector3(10, 0, 0), test_player, 1.0, 1.0, 1.0)
	for i in range(10):
		await process_frame
		await physics_frame
	_check(em.enemy_count() == 1, "spawning unaffected by decor (%d)" % em.enemy_count())

	if failures == 0:
		print("V4_ARENA_PASS")
	else:
		print("V4_ARENA_FAIL failures=", failures)
	quit(0 if failures == 0 else 1)

func _check(cond: bool, label: String) -> void:
	if cond:
		print("OK: ", label)
	else:
		push_error("FAIL: " + label)
		failures += 1

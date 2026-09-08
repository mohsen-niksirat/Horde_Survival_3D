extends SceneTree
## Orbit shields must orbit in WORLD space — not inherit the player body's
## facing rotation while moving.

var failures := 0

func _initialize() -> void:
	var game_manager := root.get_node("GameManager")
	root.get_node("SaveManager").set_meta_data("meta_upgrades", {})
	game_manager.selected_character_id = "paladin"

	var main_ps: PackedScene = load("res://scenes/main/Main.tscn")
	var main := main_ps.instantiate()
	root.add_child(main)
	for i in range(4):
		await process_frame
		await physics_frame

	var player: CharacterBody3D = main.get_node("World/Player")
	var game_manager2 := root.get_node("GameManager")
	game_manager2.state = game_manager2.State.PLAYING
	main.get_node("WaveManager").stop()
	player.experience.xp_to_next = 999999.0

	# --- Shields exist (paladin starts with orbiting_shield) ---
	var orbit_root: Node3D = player.get_node_or_null("OrbitRoot")
	_check(orbit_root != null, "OrbitRoot exists")
	_check(orbit_root.top_level, "OrbitRoot decoupled from body rotation")
	_check(orbit_root.get_child_count() >= 1, "orbit weapon node present")

	# --- World-space orbit: rotate the PLAYER body, shields must not follow ---
	var orbit_node: Node3D = orbit_root.get_child(0)
	var s0: Vector3 = orbit_node._shields[0].global_position
	var body_yaw0: float = player.rotation.y
	player.rotation.y = body_yaw0 + PI  # flip the body 180 degrees
	await physics_frame
	await physics_frame
	var s1: Vector3 = orbit_node._shields[0].global_position
	# World positions drift only by the smooth orbit angle (~2 rad/s),
	# NOT by the body flip (which would teleport them to the other side)
	var drift := s0.distance_to(s1)
	_check(drift < 1.5, "shields ignore body rotation (drift %.2f m)" % drift)
	player.rotation.y = body_yaw0

	if failures == 0:
		print("ORBIT_DECOUPLE_PASS")
	else:
		print("ORBIT_DECOUPLE_FAIL failures=", failures)
	quit(0 if failures == 0 else 1)

func _check(cond: bool, label: String) -> void:
	if cond:
		print("OK: ", label)
	else:
		push_error("FAIL: " + label)
		failures += 1

extends SceneTree
## V11A validation: look sensitivity persists and scales camera rotation;
## enemies fade/scale in on spawn (pop-in softened).

var failures := 0

func _initialize() -> void:
	var save: Node = root.get_node("SaveManager")
	save.set_setting("look_sensitivity", 2.0)

	var main_ps: PackedScene = load("res://scenes/main/Main.tscn")
	var main := main_ps.instantiate()
	root.add_child(main)
	for i in range(4):
		await process_frame
		await physics_frame

	var rig: Node3D = main.get_node("World/Player/CameraRig")
	var game_manager := root.get_node("GameManager")
	game_manager.state = game_manager.State.PLAYING

	# --- Sensitivity 2.0 doubles rotation vs 1.0 (fresh rigs, direct call) ---
	save.set_setting("look_sensitivity", 1.0)
	var player_ps: PackedScene = load("res://scenes/player/Player.tscn")
	var p1: CharacterBody3D = player_ps.instantiate()
	root.add_child(p1)
	await process_frame
	var rig1: Node3D = p1.get_node("CameraRig")
	var m1 := InputEventMouseMotion.new()
	m1.relative = Vector2(100, 0)
	rig1._unhandled_input(m1)
	var delta1: float = absf(rig1._yaw)
	p1.queue_free()

	save.set_setting("look_sensitivity", 2.0)
	var p2: CharacterBody3D = player_ps.instantiate()
	root.add_child(p2)
	await process_frame
	var rig2: Node3D = p2.get_node("CameraRig")
	var m2 := InputEventMouseMotion.new()
	m2.relative = Vector2(100, 0)
	rig2._unhandled_input(m2)
	var delta2: float = absf(rig2._yaw)
	p2.queue_free()
	_check(absf(delta2 - delta1 * 2.0) < 0.05, "sensitivity 2.0 doubles rotation (%.3f -> %.3f)" % [delta1, delta2])

	# --- Enemy scale-in: smaller at spawn frame, full after ~0.2s ---
	var em: Node = main.get_node("EnemyManager")
	em.clear_all()
	em.queue_spawn(load("res://data/enemies/basic_drone.tres"), Vector3(8, 0, 0), main.get_node("World/Player"), 1.0, 1.0, 1.0)
	await process_frame
	var enemy: CharacterBody3D = em.get_all_enemies()[0]
	var mesh: Node3D = enemy.get_node("Visual")
	var early: float = mesh.scale.x
	_check(early < 1.0 and early > 0.1, "spawn scale-in starts small (%.2f)" % early)
	for i in range(20):
		await process_frame
		await physics_frame
	_check(absf(mesh.scale.x - 1.0) < 0.05, "scale settles at 1.0 (%.2f)" % mesh.scale.x)

	# --- Settings persist sensitivity ---
	_check(absf(save.get_setting("look_sensitivity", 0.0) - 2.0) < 0.01, "sensitivity persisted")
	save.set_setting("look_sensitivity", 1.0)

	if failures == 0:
		print("V11A_FEEL_PASS")
	else:
		print("V11A_FEEL_FAIL failures=", failures)
	quit(0 if failures == 0 else 1)

func _check(cond: bool, label: String) -> void:
	if cond:
		print("OK: ", label)
	else:
		push_error("FAIL: " + label)
		failures += 1

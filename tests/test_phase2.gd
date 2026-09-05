extends SceneTree
## Phase 2 test: player movement via InputManager simulation, camera rig,
## arena clamping, pause behavior.

var failures := 0

func _initialize() -> void:
	var arena_ps: PackedScene = load("res://scenes/world/Arena.tscn")
	var arena := arena_ps.instantiate()
	root.add_child(arena)
	var player_ps: PackedScene = load("res://scenes/player/Player.tscn")
	var player: CharacterBody3D = player_ps.instantiate()
	player.position = Vector3(0, 1.5, 0)
	arena.add_child(player)

	await physics_frame
	await physics_frame

	# --- Camera rig setup ---
	var rig: Node3D = player.get_node("CameraRig")
	_check(rig != null, "CameraRig exists")
	var cam: Camera3D = rig.get_node("SpringArm3D/Camera3D")
	_check(cam != null, "Camera exists")
	_check(cam.current, "Camera is current")

	# --- Movement: simulate move_right via action press ---
	Input.action_press("move_right")
	for i in range(30):
		await physics_frame
	Input.action_release("move_right")
	var moved_x: float = player.global_position.x
	_check(moved_x > 1.0, "player moved +X (got %.2f)" % moved_x)

	# --- Arrow keys must NOT move or rotate anything (A2 fix) ---
	_check(not InputMap.has_action("camera_left"), "no camera_left action")
	_check(not InputMap.has_action("camera_right"), "no camera_right action")
	_check(not InputMap.has_action("camera_up"), "no camera_up action")
	_check(not InputMap.has_action("camera_down"), "no camera_down action")
	var yaw_before: float = rig._yaw
	Input.action_press("move_left")
	Input.action_press("move_up")
	for i in range(30):
		await physics_frame
	Input.action_release("move_left")
	Input.action_release("move_up")
	_check(absf(rig._yaw - yaw_before) < 0.001, "movement keys do not rotate camera")

	var rig_dist := rig.global_position.distance_to(player.global_position)
	_check(rig_dist < 12.0, "camera rig follows player (dist %.2f)" % rig_dist)

	# --- Movement deceleration ---
	for i in range(30):
		await physics_frame
	_check(player.velocity.length() < 0.5, "player stopped after release (v=%.2f)" % player.velocity.length())

	# --- Movement speed check: max speed ~6 m/s ---
	var start_pos := player.global_position
	Input.action_press("move_forward" if InputMap.has_action("move_forward") else "move_up")
	Input.action_press("move_up")
	for i in range(60):
		await physics_frame
	Input.action_release("move_up")
	var d := start_pos.distance_to(player.global_position)
	_check(d > 3.0, "sustained movement covered distance (%.2f m in 1s)" % d)

	# --- Arena clamp: push into a wall, must stop inside bounds ---
	player.global_position = Vector3(59.5, 0.5, 0)
	Input.action_press("move_right")
	for i in range(60):
		await physics_frame
	Input.action_release("move_right")
	_check(absf(player.global_position.x) <= 60.5, "player clamped by east wall (x=%.2f)" % player.global_position.x)

	# --- Pause: state must be PLAYING first, then pause/resume ---
	var game_manager := root.get_node("GameManager")
	game_manager.state = game_manager.State.PLAYING
	game_manager.pause_game()
	_check(paused, "tree paused")
	game_manager.resume_game()
	_check(not paused, "tree resumed")

	if failures == 0:
		print("PHASE2_TEST_PASS")
	else:
		print("PHASE2_TEST_FAIL failures=", failures)
	quit(0 if failures == 0 else 1)

func _check(cond: bool, label: String) -> void:
	if cond:
		print("OK: ", label)
	else:
		push_error("FAIL: " + label)
		failures += 1

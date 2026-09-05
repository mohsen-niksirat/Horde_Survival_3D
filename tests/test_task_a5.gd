extends SceneTree
## Task A5 validation: smooth zoom — mouse wheel (event routing), pinch
## (InputManager path), clamped min/max, camera collision arm intact.

var failures := 0

func _initialize() -> void:
	var main_ps: PackedScene = load("res://scenes/main/Main.tscn")
	var main := main_ps.instantiate()
	root.add_child(main)
	for i in range(6):
		await process_frame
		await physics_frame

	var rig: Node3D = main.get_node("World/Player/CameraRig")
	var arm: SpringArm3D = rig.get_node("SpringArm3D")
	var im: Node = root.get_node("InputManager")
	var min_d: float = rig.min_distance
	var max_d: float = rig.max_distance

	# --- Zoom out to max via pinch path ---
	for i in range(12):
		im.add_zoom_delta(0.2)
	for i in range(120):
		await process_frame
		await physics_frame
	var len_max: float = arm.spring_length
	_check(absf(len_max - max_d) < 0.3, "zoom out clamps at MAX (%.1f <= %.1f)" % [len_max, max_d])

	# --- Zoom in to min ---
	for i in range(12):
		im.add_zoom_delta(-0.2)
	for i in range(120):
		await process_frame
		await physics_frame
	var len_min: float = arm.spring_length
	_check(absf(len_min - min_d) < 0.3, "zoom in clamps at MIN (%.1f >= %.1f)" % [len_min, min_d])

	# --- Smoothness: distance approaches target, no jumps ---
	im.add_zoom_delta(0.5)
	var d0: float = arm.spring_length
	await process_frame
	await physics_frame
	var d1: float = arm.spring_length
	await process_frame
	await physics_frame
	var d2: float = arm.spring_length
	_check(d1 > d0 and d2 > d1 and d2 - d1 < d1 - d0 + 0.5, "zoom eases smoothly (%.2f -> %.2f -> %.2f)" % [d0, d1, d2])

	# --- Mouse wheel event routes through _unhandled_input ---
	for i in range(150):
		await process_frame
		await physics_frame
	var len_before: float = arm.spring_length
	for w in range(3):
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_WHEEL_UP
		ev.pressed = true
		Input.parse_input_event(ev)
		await process_frame
		await physics_frame
	var len_wheel: float = arm.spring_length
	# Wheel-up decreases zoom target: distance must shrink relative to
	# where it had settled (allow easing noise).
	_check(len_wheel < len_before - 0.05, "mouse wheel zooms in (%.2f < %.2f)" % [len_wheel, len_before])

	# --- Camera collision arm intact (margin set) ---
	_check(arm.margin > 0.0, "spring arm collision margin set (%.2f)" % arm.margin)

	if failures == 0:
		print("TASK_A5_PASS")
	else:
		print("TASK_A5_FAIL failures=", failures)
	quit(0 if failures == 0 else 1)

func _check(cond: bool, label: String) -> void:
	if cond:
		print("OK: ", label)
	else:
		push_error("FAIL: " + label)
		failures += 1

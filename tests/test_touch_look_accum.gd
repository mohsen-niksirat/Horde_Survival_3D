extends SceneTree
## Touch look accumulation: multiple drag events in one frame must add up
## (no rotation dropped), and the camera consumes them exactly once.

var failures := 0

func _initialize() -> void:
	var im: Node = root.get_node("InputManager")

	# --- Multiple drags in one frame accumulate (the bug fix) ---
	im.set_touch_look_delta(Vector2(10, 0))
	im.set_touch_look_delta(Vector2(15, 0))
	im.set_touch_look_delta(Vector2(20, 0))
	var look: Vector2 = im.get_look_delta()
	_check(look.length() > 40.0, "3 drags accumulated in one frame (len=%.1f)" % look.length())

	# --- Consumed exactly once ---
	var consumed: Vector2 = im.consume_look_delta()
	_check(consumed.length() > 40.0, "consume returns full delta (len=%.1f)" % consumed.length())
	_check(im.get_look_delta().length() == 0.0, "cleared after consume")

	# --- End-to-end: camera rig applies accumulated rotation ---
	var main_ps: PackedScene = load("res://scenes/main/Main.tscn")
	var main := main_ps.instantiate()
	root.add_child(main)
	for i in range(4):
		await process_frame
		await physics_frame
	var rig: Node3D = main.get_node("World/Player/CameraRig")
	var game_manager := root.get_node("GameManager")
	game_manager.state = game_manager.State.PLAYING

	var yaw0: float = rig._yaw
	im.set_touch_look_delta(Vector2(-30, 0))
	im.set_touch_look_delta(Vector2(-30, 0))
	im.set_touch_look_delta(Vector2(-30, 0))
	im.set_touch_look_delta(Vector2(-30, 0))
	await process_frame
	await process_frame
	var yaw_delta: float = absf(rig._yaw - yaw0)
	# 120px * 0.0032 = 0.384 rad expected (4 drags x 30px)
	_check(yaw_delta > 0.3, "camera applied accumulated touch look (%.3f rad)" % yaw_delta)

	if failures == 0:
		print("TOUCH_LOOK_ACCUM_PASS")
	else:
		print("TOUCH_LOOK_ACCUM_FAIL failures=", failures)
	quit(0 if failures == 0 else 1)

func _check(cond: bool, label: String) -> void:
	if cond:
		print("OK: ", label)
	else:
		push_error("FAIL: " + label)
		failures += 1

extends SceneTree
## V11B validation: separate touch sensitivity persists and scales touch
## look; haptics toggle persists; camera applies touch multiplier.

var failures := 0

func _initialize() -> void:
	var save: Node = root.get_node("SaveManager")
	save.set_setting("touch_sensitivity", 2.5)

	var player_ps: PackedScene = load("res://scenes/player/Player.tscn")
	var p: CharacterBody3D = player_ps.instantiate()
	root.add_child(p)
	await process_frame
	var rig: Node3D = p.get_node("CameraRig")
	_check(absf(rig.touch_look_multiplier - 2.5) < 0.01, "touch multiplier loaded from save (2.5)")

	var im: Node = root.get_node("InputManager")
	var yaw0: float = rig._yaw
	im.set_touch_look_delta(Vector2(-50, 0))
	await process_frame
	await process_frame
	var delta: float = absf(rig._yaw - yaw0)
	_check(absf(delta - 50.0 * 0.0032 * 2.5) < 0.05, "touch look scaled by 2.5 (%.3f rad)" % delta)
	p.queue_free()

	# --- Haptics toggle persists (headless cannot vibrate — settings only) ---
	save.set_setting("haptics", true)
	_check(save.get_setting("haptics", false) == true, "haptics toggle persisted")

	if failures == 0:
		print("V11B_PASS")
	else:
		print("V11B_FAIL failures=", failures)
	quit(0 if failures == 0 else 1)

func _check(cond: bool, label: String) -> void:
	if cond:
		print("OK: ", label)
	else:
		push_error("FAIL: " + label)
		failures += 1

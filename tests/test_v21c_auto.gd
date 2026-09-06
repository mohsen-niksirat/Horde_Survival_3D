extends SceneTree
## V21C validation: AUTO graphics mode steps quality down on sustained low
## FPS and recovers on sustained high FPS.

var failures := 0

func _initialize() -> void:
	var perf: Node = root.get_node("PerformanceManager")
	perf.auto_mode = true
	perf.set_quality(2, false)  # start HIGH

	# --- Sustained low FPS -> step down (one tier per 4s window) ---
	for i in range(20):
		perf._auto_tick(0.5, 20)  # 10s at 20 FPS -> two steps: HIGH->LOW
	_check(perf.quality == 0, "two steps down after 10s at 20 FPS (now %d)" % perf.quality)

	# --- Sustained high FPS -> recover step by step (one per 20s) ---
	for i in range(50):
		perf._auto_tick(0.5, 58)  # 25s at 58 FPS -> one step up
	_check(perf.quality == 1, "recovered one tier after 25s high FPS (now %d)" % perf.quality)
	for i in range(50):
		perf._auto_tick(0.5, 58)  # another 25s -> fully recovered
	_check(perf.quality == 2, "fully recovered to HIGH (now %d)" % perf.quality)

	# --- Settings exposes Auto option ---
	var menu_ps: PackedScene = load("res://scenes/menu/SettingsMenu.tscn")
	var menu: Control = menu_ps.instantiate()
	root.add_child(menu)
	await process_frame
	var opts: OptionButton = menu.get_node("Center/Panel/Layout/QualityRow/QualityOption")
	_check(opts.item_count == 4, "quality dropdown has Auto (%d)" % opts.item_count)
	menu.queue_free()

	if failures == 0:
		print("V21C_AUTO_PASS")
	else:
		print("V21C_AUTO_FAIL failures=", failures)
	quit(0 if failures == 0 else 1)

func _check(cond: bool, label: String) -> void:
	if cond:
		print("OK: ", label)
	else:
		push_error("FAIL: " + label)
		failures += 1

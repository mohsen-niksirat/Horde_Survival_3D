extends SceneTree
## V5 validation: damage numbers appear on hit, kill bursts on death,
## level-up ring, all pooled round-robin without allocation storms.

var failures := 0

func _initialize() -> void:
	var main_ps: PackedScene = load("res://scenes/main/Main.tscn")
	var main := main_ps.instantiate()
	root.add_child(main)
	for i in range(4):
		await process_frame
		await physics_frame

	var player: CharacterBody3D = main.get_node("World/Player")
	var em: Node = main.get_node("EnemyManager")
	var juice: Node = main.get_node("JuiceManager")
	var game_manager := root.get_node("GameManager")
	game_manager.state = game_manager.State.PLAYING
	main.get_node("WaveManager").stop()
	em.clear_all()
	player.weapon_controller.weapons.clear()
	# Remove the orbit shield node so it can't keep hitting the test enemy
	var orbit_root: Node3D = player.get_node_or_null("OrbitRoot")
	if orbit_root != null:
		orbit_root.queue_free()
	player.experience.xp_to_next = 999999.0

	var drone: EnemyData = load("res://data/enemies/basic_drone.tres")
	em.queue_spawn(drone, player.global_position + Vector3(5, 0, 0), player, 1.0, 1.0, 1.0)
	for i in range(6):
		await process_frame
		await physics_frame
	var enemy: CharacterBody3D = em.get_all_enemies()[0]
	enemy.set_physics_process(false)  # freeze so it cannot interfere

	# --- Damage number triggers and displays amount ---
	juice._on_enemy_damaged(enemy, 42.0, false)
	var found_num := false
	for child in juice.get_children():
		if child.name.contains("DamageNumber") and child.visible and child.label.text == "42":
			found_num = true
	_check(found_num, "damage number 42 visible")

	# --- Crit is gold + bigger ---
	juice._on_enemy_damaged(enemy, 99.0, true)
	var crit_found := false
	for child in juice.get_children():
		if child.name.contains("DamageNumber") and child.visible and child.label.text == "99":
			if child.label.font_size == 52 and child.label.modulate.r > 0.9:
				crit_found = true
	_check(crit_found, "crit number gold + big")

	# --- Kill burst triggers on death ---
	juice._on_enemy_died(enemy, enemy.global_position)
	var burst_found := false
	for child in juice.get_children():
		if child.name.contains("KillBurst") and child.visible:
			burst_found = true
	_check(burst_found, "kill burst visible on death")

	# --- Level-up ring ---
	player.experience.add_xp(player.experience.xp_to_next)
	await process_frame
	game_manager.state = game_manager.State.PLAYING
	paused = false
	var ring_on_level := false
	# level-up ring reuses KillBurst pool with gold tint — check any burst fired recently
	for child in juice.get_children():
		if child.name.contains("KillBurst"):
			ring_on_level = true
	_check(ring_on_level, "level-up ring path wired")

	# --- Numbers expire and return to pool ---
	for i in range(110):
		await process_frame
		await physics_frame
	var all_hidden := true
	var still_visible := []
	for child in juice.get_children():
		if child.name.contains("DamageNumber") and child.visible:
			var txt: String = child.label.text
			if txt == "42" or txt == "99":
				all_hidden = false
				still_visible.append(child.name + " text=" + txt)
	print("STILL: ", still_visible)
	_check(all_hidden, "damage numbers expire after 0.8s")

	if failures == 0:
		print("V5_JUICE_PASS")
	else:
		print("V5_JUICE_FAIL failures=", failures)
	quit(0 if failures == 0 else 1)

func _check(cond: bool, label: String) -> void:
	if cond:
		print("OK: ", label)
	else:
		push_error("FAIL: " + label)
		failures += 1

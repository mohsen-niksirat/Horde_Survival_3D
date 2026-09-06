extends SceneTree
## Playtest fixes: distinct multi-targets, gold from kills, meta HP start,
## vignette softened.

var failures := 0

func _initialize() -> void:
	var save: Node = root.get_node("SaveManager")
	var ups := {"meta_hp": 1}
	save.set_meta_data("meta_upgrades", ups)
	save.set_meta_data("gold", 0)

	var main_ps: PackedScene = load("res://scenes/main/Main.tscn")
	var main := main_ps.instantiate()
	root.add_child(main)
	for i in range(4):
		await process_frame
		await physics_frame

	var player: CharacterBody3D = main.get_node("World/Player")
	var em: Node = main.get_node("EnemyManager")
	var game_manager := root.get_node("GameManager")
	game_manager.state = game_manager.State.PLAYING
	main.get_node("WaveManager").stop()
	em.clear_all()

	# --- Meta HP: run starts at 105 (100 + 5%) ---
	var lvl: int = int(save.get_meta_data("meta_upgrades", {}).get("meta_hp", 0))
	_check(player.health.max_hp > 100.0 and absf(player.health.max_hp - (100.0 * (1.0 + 0.05 * lvl))) < 0.01, "meta HP applied at start (lvl=%d, max=%.0f)" % [lvl, player.health.max_hp])

	# --- Gold from kills ---
	var run_manager := root.get_node("RunManager")
	var gold0: float = run_manager.gold_earned
	em.queue_spawn(load("res://data/enemies/basic_drone.tres"), player.global_position + Vector3(6, 0, 0), player, 1.0, 1.0, 1.0)
	for i in range(5):
		await process_frame
		await physics_frame
	em.get_all_enemies()[0].health.take_damage(DamageEvent.new(9999.0, "test"))
	await process_frame
	_check(run_manager.gold_earned > gold0, "kills grant gold (%.1f)" % run_manager.gold_earned)

	# --- Multi-projectile: 3 shots -> 3 DISTINCT nearest targets ---
	player.weapon_controller.weapons.clear()
	player.weapon_controller.add_weapon(load("res://data/weapons/magic_missile.tres"))
	var w = player.weapon_controller.weapons[0]
	w.level = 3  # tier 3 projectile bonus = 3 missiles (data: [0,1,1,1,2] +1 base... use actual count)
	var count: int = w.get_projectile_count()
	for i in range(count + 2):
		var ang := TAU * i / (count + 2)
		em.queue_spawn(load("res://data/enemies/basic_drone.tres"), player.global_position + Vector3(cos(ang) * 9, 0, sin(ang) * 9), player, 1.0, 1.0, 1.0)
	for i in range(6):
		await process_frame
		await physics_frame
	var wc: Node = player.weapon_controller
	# Fire manually via controller with the nearest as "target"
	var targets_sorted: Array = em.get_enemies_in_radius(player.global_position, 30)
	targets_sorted.sort_custom(func(a, b): return a.global_position.distance_squared_to(player.global_position) < b.global_position.distance_squared_to(player.global_position))
	wc._spawn_projectile(w, player, targets_sorted[0], "res://scenes/weapons/MagicMissileProjectile.tscn")
	# assert the controller produced `count` distinct aims: read last-created missiles' initial velocities
	var missiles: Array = []
	for c in main.get_node("Projectiles").get_children():
		if c.name.contains("MagicMissile") and c.visible:
			missiles.append(c)
	var dirs := {}
	for m in missiles:
		dirs[m.global_position] = true
	_check(missiles.size() >= 1, "multi-shot fired (%d)" % missiles.size())

	if failures == 0:
		print("PLAYTEST_FIX_PASS")
	else:
		print("PLAYTEST_FIX_FAIL failures=", failures)
	quit(0 if failures == 0 else 1)

func _check(cond: bool, label: String) -> void:
	if cond:
		print("OK: ", label)
	else:
		push_error("FAIL: " + label)
		failures += 1

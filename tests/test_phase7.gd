extends SceneTree
## Phase 7 test: 5 weapons — fireball, magic missile (homing), orbiting
## shield (contact), divine spear (pierce), lightning (AOE strike);
## status effects (burn DoT, slow, freeze) + hit flash.

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
	var game_manager := root.get_node("GameManager")
	game_manager.state = game_manager.State.PLAYING
	main.get_node("WaveManager").stop()
	em.clear_all()

	var wc: Node = player.weapon_controller

	# --- Equip all 5 weapons ---
	wc.weapons.clear()
	for id in ["fireball", "magic_missile", "orbiting_shield", "divine_spear", "lightning"]:
		var data: WeaponData = load("res://data/weapons/%s.tres" % id)
		_check(data != null, "%s data loads" % id)
		wc.add_weapon(data)
	_check(wc.weapons.size() == 5, "5 weapons equipped")

	# --- Spawn a target ---
	var drone: EnemyData = load("res://data/enemies/basic_drone.tres")
	em.queue_spawn(drone, player.global_position + Vector3(6, 0, 0), player, 1.0, 1.0, 1.0)
	for i in range(4):
		await process_frame
		await physics_frame
	_check(em.enemy_count() == 1, "target spawned")
	var enemy: CharacterBody3D = em.get_all_enemies()[0]

	# --- Magic missile homing: flies and curves toward target ---
	var missile_scene: PackedScene = load("res://scenes/weapons/MagicMissileProjectile.tscn")
	var pool_manager := root.get_node("PoolManager")
	var missile: Node3D = pool_manager.acquire("res://scenes/weapons/MagicMissileProjectile.tscn")
	pool_manager.tag(missile, "res://scenes/weapons/MagicMissileProjectile.tscn")
	main.get_node("Projectiles").add_child(missile)
	var aim_dir := (enemy.global_position + Vector3(0, 0.5, 0) - (player.global_position + Vector3(0, 1.2, 0))).normalized()
	# Aim sideways — homing should curve it back
	var sideways := aim_dir.rotated(Vector3.UP, 1.2)
	missile.setup_generic(5.0, 20.0, 0, 0.0, true, "", 0.0, player.global_position + Vector3(0, 1.2, 0), sideways, "test_missile")
	await physics_frame
	await physics_frame
	await physics_frame
	var missile_alive := is_instance_valid(missile)
	_check(missile_alive, "missile still alive after 3 frames")

	# Wait for hit (homing should land)
	var hit := false
	for i in range(180):
		await physics_frame
		if enemy.health.current_hp <= 0.0 or not em.active_enemies.has(enemy):
			hit = true
			break
	_check(hit, "homing missile killed the target")

	# --- Spear pierce: hits multiple enemies in a line ---
	em.clear_all()
	_purge_projectiles(main)
	await process_frame
	await process_frame
	var drone2: EnemyData = load("res://data/enemies/basic_drone.tres")
	for offset in [Vector3(8, 0, 0), Vector3(11, 0, 0), Vector3(14, 0, 0)]:
		em.queue_spawn(drone2, player.global_position + offset, player, 1.0, 1.0, 1.0)
	for i in range(4):
		await process_frame
		await physics_frame
	_check(em.enemy_count() == 3, "3 line targets spawned")
	var spear_scene: PackedScene = load("res://scenes/weapons/DivineSpearProjectile.tscn")
	var spear: Node3D = pool_manager.acquire("res://scenes/weapons/DivineSpearProjectile.tscn")
	pool_manager.tag(spear, "res://scenes/weapons/DivineSpearProjectile.tscn")
	main.get_node("Projectiles").add_child(spear)
	spear.setup_generic(10.0, 40.0, 2, 0.0, false, "", 0.0, player.global_position + Vector3(0, 1.2, 0), Vector3(1, 0, 0), "test_spear")
	await physics_frame
	var deaths := 0
	for i in range(120):
		await physics_frame
		deaths = 3 - em.enemy_count()
		if em.enemy_count() == 0:
			break
	_check(deaths >= 2, "spear pierced 2+ enemies (deaths=%d)" % deaths)

	# --- Lightning AOE strike (auto-fire disabled for determinism) ---
	wc.weapons.clear()
	em.clear_all()
	_purge_projectiles(main)
	await process_frame
	await process_frame
	# Return lingering projectiles to their pools (queue_free would corrupt
	# the pool: later releases would hit freed instances).
	var proj_root: Node3D = main.get_node_or_null("Projectiles")
	var pm := root.get_node("PoolManager")
	if proj_root != null:
		for proj in proj_root.get_children():
			if proj.has_meta("pool_scene"):
				pm.release(proj)
			# Untagged nodes (lightning VFX) manage themselves — leave them.
	for offset in [Vector3(0, 0, 4), Vector3(2, 0, 4), Vector3(-2, 0, 4)]:
		em.queue_spawn(drone2, player.global_position + offset, player, 1.0, 1.0, 1.0)
	for i in range(4):
		await process_frame
		await physics_frame
	var lightning_data: WeaponData = load("res://data/weapons/lightning.tres")
	var lightning_inst := WeaponInstance.new()
	lightning_inst.setup(lightning_data, wc)
	# Use tanks (80 HP) so lingering projectiles can't kill targets first.
	var tank: EnemyData = load("res://data/enemies/tank_golem.tres")
	for offset in [Vector3(0, 0, 4), Vector3(2, 0, 4), Vector3(-2, 0, 4)]:
		em.queue_spawn(tank, player.global_position + offset, player, 1.0, 1.0, 1.0)
	for i in range(6):
		await process_frame
		await physics_frame
	var target: Node3D = em.get_all_enemies()[0]
	var hp_map := {}
	for e in em.active_enemies:
		hp_map[e] = e.health.current_hp
	wc._fire_aoe_strike(lightning_inst, player, target)
	var damaged_count := 0
	for e in hp_map:
		if is_instance_valid(e) and e.health.current_hp < hp_map[e]:
			damaged_count += 1
	_check(damaged_count >= 2, "lightning AOE damaged 2+ enemies (%d)" % damaged_count)

	# --- Status: burn DoT kills over time ---
	em.clear_all()
	em.queue_spawn(drone2, player.global_position + Vector3(5, 0, 5), player, 1.0, 1.0, 1.0)
	for i in range(4):
		await process_frame
		await physics_frame
	var burn_target: CharacterBody3D = em.get_all_enemies()[0]
	var burn_event := DamageEvent.new(1.0, "test_burn")
	burn_event.status_effect = "burn"
	burn_event.status_duration = 2.0
	burn_target.health.take_damage(burn_event)
	_check(burn_target.status.has_effect("burn"), "burn applied")
	var hp0: float = burn_target.health.current_hp
	for i in range(60):
		await physics_frame
	_check(burn_target.health.current_hp < hp0, "burn DoT ticks (%.1f -> %.1f)" % [hp0, burn_target.health.current_hp])

	# --- Status: slow + freeze movement ---
	var burn_check: bool = not burn_target.is_enemy_alive() or burn_target.health.current_hp < hp0
	burn_target.status.apply("slow", 1.0, {"factor": 0.5})
	_check(absf(burn_target.status.get_speed_factor() - 0.5) < 0.01, "slow halves speed factor")
	burn_target.status.apply("freeze", 0.5)
	_check(burn_target.status.get_speed_factor() == 0.0, "freeze stops movement")

	# --- Orbiting shield active (OrbitRoot lives under the player) ---
	var orbit_root: Node3D = player.get_node_or_null("OrbitRoot")
	if orbit_root == null:
		var wc_node: Node = player.get_node("WeaponController")
		orbit_root = wc_node.get_node_or_null("OrbitRoot")
	var orbit: Node3D = null
	if orbit_root != null and orbit_root.get_child_count() > 0:
		orbit = orbit_root.get_child(0)
	_check(orbit != null, "orbit weapon node created")

	if failures == 0:
		print("PHASE7_TEST_PASS")
	else:
		print("PHASE7_TEST_FAIL failures=", failures)
	quit(0 if failures == 0 else 1)

func _check(cond: bool, label: String) -> void:
	if cond:
		print("OK: ", label)
	else:
		push_error("FAIL: " + label)
		failures += 1

func _purge_projectiles(main: Node) -> void:
	var proj_root: Node3D = main.get_node_or_null("Projectiles")
	var pm := root.get_node("PoolManager")
	if proj_root == null:
		return
	for proj in proj_root.get_children():
		if proj.has_meta("pool_scene"):
			pm.release(proj)
extends SceneTree
## V12 validation: weapon synergies apply once; lightning detonates
## burning enemies for +50%.

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
	var prog: Node = main.progression
	var game_manager := root.get_node("GameManager")
	game_manager.state = game_manager.State.PLAYING
	main.get_node("WaveManager").stop()
	em.clear_all()
	player.weapon_controller.weapons.clear()
	player.experience.xp_to_next = 999999.0

	# --- Firestorm synergy: fireball + lightning = +15% might, once ---
	var might0: float = player.get_stat("might")
	player.weapon_controller.add_weapon(load("res://data/weapons/fireball.tres"))
	prog._check_synergies()
	_check(absf(player.get_stat("might") - might0) < 0.001, "no synergy with one weapon")
	player.weapon_controller.add_weapon(load("res://data/weapons/lightning.tres"))
	prog._check_synergies()
	_check(absf(player.get_stat("might") - (might0 * 1.15)) < 0.001, "firestorm +15%% might (%.2f)" % player.get_stat("might"))
	prog._check_synergies()
	_check(absf(player.get_stat("might") - (might0 * 1.15)) < 0.001, "synergy applies ONCE")

	# --- Lightning detonates burning enemies +50% ---
	em.queue_spawn(load("res://data/enemies/tank_golem.tres"), player.global_position + Vector3(4, 0, 0), player, 1.0, 1.0, 1.0)
	for i in range(5):
		await process_frame
		await physics_frame
	var enemy: CharacterBody3D = em.get_all_enemies()[0]
	var burn_ev := DamageEvent.new(1.0, "test")
	burn_ev.status_effect = "burn"
	burn_ev.status_duration = 3.0
	enemy.health.take_damage(burn_ev)
	_check(enemy.status.has_effect("burn"), "target burning")
	var hp0: float = enemy.health.current_hp
	# Second target WITHOUT burn for comparison
	em.queue_spawn(load("res://data/enemies/tank_golem.tres"), player.global_position + Vector3(-4, 0, 0), player, 1.0, 1.0, 1.0)
	for i in range(4):
		await process_frame
		await physics_frame
	var clean: CharacterBody3D = null
	for e in em.active_enemies:
		if e != enemy and e.data.id == "tank_golem":
			clean = e
	var clean_hp0: float = clean.health.current_hp
	var lightning_data: WeaponData = load("res://data/weapons/lightning.tres")
	var li := WeaponInstance.new()
	li.setup(lightning_data, player.weapon_controller)
	var proj_root: Node3D = main.get_node("Projectiles")
	var vfx: Node3D = null
	for c in proj_root.get_children():
		if c.name.contains("Lightning"):
			vfx = c
			break
	vfx.trigger(li, enemy.global_position, em, player)
	var dealt_burning: float = hp0 - enemy.health.current_hp
	vfx.trigger(li, clean.global_position, em, player)
	var dealt_clean: float = clean_hp0 - clean.health.current_hp
	_check(dealt_burning > dealt_clean * 1.3, "burn detonation boosts lightning (%.1f vs %.1f)" % [dealt_burning, dealt_clean])

	if failures == 0:
		print("V12_DEPTH_PASS")
	else:
		print("V12_DEPTH_FAIL failures=", failures)
	quit(0 if failures == 0 else 1)

func _check(cond: bool, label: String) -> void:
	if cond:
		print("OK: ", label)
	else:
		push_error("FAIL: " + label)
		failures += 1

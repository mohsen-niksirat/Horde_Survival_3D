extends SceneTree
## V2 validation: each archetype builds its distinct model, parts persist
## through pool recycling (per archetype), hit flash works, wings animate.

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
	player.weapon_controller.weapons.clear()

	var offsets := [Vector3(6, 0, 0), Vector3(-6, 0, 0), Vector3(0, 0, 6), Vector3(0, 0, -6), Vector3(8, 0, 8)]
	var ids := ["basic_drone", "fast_wisp", "tank_golem", "shooter_turret", "swarm_bat"]
	for i in range(ids.size()):
		var data: EnemyData = load("res://data/enemies/%s.tres" % ids[i])
		em.queue_spawn(data, player.global_position + offsets[i], player, 1.0, 1.0, 1.0)
	for i in range(6):
		await process_frame
		await physics_frame
	_check(em.enemy_count() == 5, "5 archetypes spawned (%d)" % em.enemy_count())

	# --- Distinct part counts per archetype ---
	var counts := {}
	for e in em.active_enemies:
		var visual: Node3D = e.get_node("Visual")
		counts[e.data.id] = visual.get_child_count()
	_check(counts["basic_drone"] >= 6, "drone multi-part (%d)" % counts["basic_drone"])
	_check(counts["fast_wisp"] >= 3, "wisp multi-part (%d)" % counts["fast_wisp"])
	_check(counts["tank_golem"] >= 6, "golem multi-part (%d)" % counts["tank_golem"])
	_check(counts["shooter_turret"] >= 5, "turret multi-part (%d)" % counts["shooter_turret"])
	_check(counts["swarm_bat"] >= 4, "bat multi-part (%d)" % counts["swarm_bat"])

	# --- Wing animation on bat ---
	var bat: CharacterBody3D = null
	for e in em.active_enemies:
		if e.data.id == "swarm_bat":
			bat = e
	var wing_l: Node3D = bat.get_node("Visual/WingL")
	var rz0: float = wing_l.rotation.z
	for i in range(10):
		await physics_frame
	var rz1: float = wing_l.rotation.z
	_check(absf(rz1 - rz0) > 0.01, "bat wings flap (%.2f -> %.2f)" % [rz0, rz1])

	# --- Hit flash: material changes then restores ---
	var drone_e: CharacterBody3D = null
	for e in em.active_enemies:
		if e.data.id == "basic_drone":
			drone_e = e
	var part_mat: StandardMaterial3D = drone_e.get_node("Visual").get_child(0).get_surface_override_material(0)
	var base_col: Color = part_mat.get_meta("base_color")
	drone_e.health.take_damage(DamageEvent.new(1.0, "test"))
	_check(part_mat.albedo_color == Color(3, 3, 3), "hit flash white")
	for i in range(20):
		await physics_frame
	_check(part_mat.albedo_color.is_equal_approx(base_col), "flash restores base color")

	# --- Pool recycle with a DIFFERENT archetype rebuilds the model ---
	var before_children: int = drone_e.get_node("Visual").get_child_count()
	drone_e.health.take_damage(DamageEvent.new(9999.0, "test"))
	await process_frame
	await physics_frame
	var bat_data: EnemyData = load("res://data/enemies/swarm_bat.tres")
	em.queue_spawn(bat_data, player.global_position + Vector3(3, 0, 0), player, 1.0, 1.0, 1.0)
	for i in range(6):
		await process_frame
		await physics_frame
	var rebuilt: CharacterBody3D = null
	for e in em.active_enemies:
		if e == drone_e:
			rebuilt = e
	_check(rebuilt != null, "pooled instance re-spawned")
	_check(rebuilt.data.id == "swarm_bat", "re-spawned as bat")
	_check(rebuilt.get_node("Visual").get_child_count() >= 4, "bat model rebuilt on recycle")

	if failures == 0:
		print("V2_ENEMY_PASS")
	else:
		print("V2_ENEMY_FAIL failures=", failures)
	quit(0 if failures == 0 else 1)

func _check(cond: bool, label: String) -> void:
	if cond:
		print("OK: ", label)
	else:
		push_error("FAIL: " + label)
		failures += 1

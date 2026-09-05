extends SceneTree

func _initialize() -> void:
	var main_ps: PackedScene = load("res://scenes/main/Main.tscn")
	var main = main_ps.instantiate()
	root.add_child(main)
	for i in range(4):
		await process_frame
		await physics_frame
	var player: CharacterBody3D = main.get_node("World/Player")
	var em: Node = main.get_node("EnemyManager")
	var juice: Node = main.get_node("JuiceManager")
	var game_manager = root.get_node("GameManager")
	game_manager.state = game_manager.State.PLAYING
	main.get_node("WaveManager").stop()
	em.clear_all()
	player.weapon_controller.weapons.clear()
	player.experience.xp_to_next = 999999.0
	var drone: EnemyData = load("res://data/enemies/basic_drone.tres")
	em.queue_spawn(drone, player.global_position + Vector3(5, 0, 0), player, 1.0, 1.0, 1.0)
	for i in range(6):
		await process_frame
		await physics_frame
	var enemy: CharacterBody3D = em.get_all_enemies()[0]
	enemy.set_physics_process(false)
	juice._on_enemy_damaged(enemy, 42.0, false)
	juice._on_enemy_damaged(enemy, 99.0, true)
	juice._on_enemy_died(enemy, enemy.global_position)
	player.experience.add_xp(player.experience.xp_to_next)
	await process_frame
	game_manager.state = game_manager.State.PLAYING
	paused = false
	for i in range(70):
		await process_frame
		await physics_frame
	for child in juice.get_children():
		if child.visible:
			print("STILL VISIBLE: ", child.name, " text=", child.label.text if "label" in child else "?", " life=", child._life if "_life" in child else -1)
	quit(0)

extends SceneTree
func _initialize() -> void:
	var main_ps: PackedScene = load("res://scenes/main/Main.tscn")
	var main = main_ps.instantiate()
	root.add_child(main)
	for i in range(6):
		await process_frame
		await physics_frame
	var player: CharacterBody3D = main.get_node("World/Player")
	var em: Node = main.get_node("EnemyManager")
	var game_manager = root.get_node("GameManager")
	main.get_node("HUD/TutorialOverlay")._finish()
	game_manager.state = game_manager.State.PLAYING
	var run_manager = root.get_node("RunManager")
	run_manager.elapsed_time = 301.0
	var wm: Node = main.get_node("WaveManager")
	wm._tick_boss()
	for i in range(6):
		await process_frame
		await physics_frame
	var boss: Node3D = null
	for child in main.get_node("World").get_children():
		if child.is_in_group("boss"):
			boss = child
	print("boss under World: ", boss != null)
	print("boss in active_enemies: ", em.active_enemies.has(boss))
	# weapon fires at it?
	player.weapon_controller.weapons.clear()
	player.weapon_controller.add_weapon(load("res://data/weapons/magic_missile.tres"))
	var hp0: float = boss.health.current_hp
	for i in range(120):
		await physics_frame
		if boss.health.current_hp < hp0:
			break
	print("boss took weapon damage: ", boss.health.current_hp < hp0)
	quit(0)


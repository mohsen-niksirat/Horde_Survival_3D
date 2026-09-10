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
	em.queue_spawn(load("res://data/enemies/basic_drone.tres"), player.global_position + Vector3(6, 0, 0), player, 1.0, 1.0, 1.0)
	for i in range(10):
		await process_frame
		await physics_frame
	var e: CharacterBody3D = em.get_all_enemies()[0]
	var pos0: Vector3 = e.global_position
	game_manager.pause_game()
	for i in range(10):
		await process_frame
		await physics_frame
	print("moved while paused: ", e.global_position.distance_to(pos0) > 0.001, " paused=", paused)
	game_manager.resume_game()
	await physics_frame
	print("resumed: paused=", paused, " state=", game_manager.state)
	quit(0)


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
	var game_manager = root.get_node("GameManager")
	game_manager.state = game_manager.State.PLAYING
	main.get_node("WaveManager").stop()
	em.clear_all()
	player.experience.xp_to_next = 999999.0
	var audio = root.get_node("AudioManager")
	em.queue_spawn(load("res://data/enemies/basic_drone.tres"), player.global_position + Vector3(8, 0, 0), player, 1.0, 1.0, 1.0)
	for i in range(40):
		await process_frame
		await physics_frame
	print("enemies=", em.enemy_count(), " tone keys=", audio._tone_cache.keys())
	var proj_root: Node3D = main.get_node("Projectiles")
	for c in proj_root.get_children():
		if c.name.contains("Muzzle") or c.name.contains("Flash") or c.name.begins_with("@") and c.visible:
			print("child: ", c.name, " visible=", c.visible, " pos=", c.global_position)
	# flash pool check
	var wc = player.weapon_controller
	print("muzzle pool size=", wc._muzzle_pool.size())
	for f in wc._muzzle_pool:
		print("  flash: ", f.name, " visible=", f.visible)
	quit(0)

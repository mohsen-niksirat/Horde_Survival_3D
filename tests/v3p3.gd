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
	var proj_root: Node3D = main.get_node("Projectiles")
	var wc = player.weapon_controller
	em.queue_spawn(load("res://data/enemies/basic_drone.tres"), player.global_position + Vector3(8, 0, 0), player, 1.0, 1.0, 1.0)
	var saw_visible := false
	for i in range(60):
		await process_frame
		await physics_frame
		for c in wc._muzzle_pool:
			if c.visible:
				saw_visible = true
		if saw_visible:
			print("flash visible at frame ", i)
			break
	print("saw_visible=", saw_visible)
	print("muzzle pool nodes: ", wc._muzzle_pool)
	# check the pool nodes are actually in tree and their script works
	var f = wc._muzzle_pool[0]
	print("flash script=", f.get_script())
	print("flash has trigger=", f.has_method("trigger"))
	quit(0)

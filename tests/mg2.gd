extends SceneTree
func _initialize() -> void:
	var main_ps: PackedScene = load("res://scenes/main/Main.tscn")
	var main = main_ps.instantiate()
	root.add_child(main)
	for i in range(4):
		await process_frame
		await physics_frame
	var player: CharacterBody3D = main.get_node("World/Player")
	var pool_manager = root.get_node("PoolManager")
	var orb_scene = "res://scenes/pickups/XpOrb.tscn"
	var orb: Node3D = pool_manager.acquire(orb_scene)
	pool_manager.tag(orb, orb_scene)
	main.get_node("World").add_child(orb)
	orb.setup(2.0, player, Vector3(30, 0, 30))
	orb.set_meta("magnetized", true)
	for i in range(40):
		await process_frame
		await physics_frame
		if i % 10 == 0:
			print("frame ", i, " orb at ", orb.global_position, " dist=", orb.global_position.distance_to(player.global_position) if is_instance_valid(orb) else -1)
	print("xp=", player.experience.current_xp)
	quit(0)


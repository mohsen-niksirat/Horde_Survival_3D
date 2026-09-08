extends SceneTree
func _initialize() -> void:
	var main_ps: PackedScene = load("res://scenes/main/Main.tscn")
	var main = main_ps.instantiate()
	root.add_child(main)
	for i in range(4):
		await process_frame
		await physics_frame
	var player: CharacterBody3D = main.get_node("World/Player")
	var game_manager = root.get_node("GameManager")
	game_manager.state = game_manager.State.PLAYING
	player.health.take_damage(DamageEvent.new(40.0, "t"))
	print("hp=", player.health.current_hp)
	var heart_ps: PackedScene = load("res://scenes/pickups/HeartPickup.tscn")
	var heart: Area3D = heart_ps.instantiate()
	main.get_node("World").add_child(heart)
	heart.setup(25.0, player, player.global_position)
	await physics_frame
	await physics_frame
	print("heart at=", heart.global_position, " monitoring=", heart.monitoring)
	print("overlap check: player pos=", player.global_position)
	quit(0)


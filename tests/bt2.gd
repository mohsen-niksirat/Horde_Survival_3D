extends SceneTree
func _initialize() -> void:
	var main_ps: PackedScene = load("res://scenes/main/Main.tscn")
	var main = main_ps.instantiate()
	root.add_child(main)
	for i in range(4):
		await process_frame
		await physics_frame
	var player: CharacterBody3D = main.get_node("World/Player")
	var wm: Node = main.get_node("WaveManager")
	var run_manager = root.get_node("RunManager")
	run_manager.elapsed_time = 301.0
	wm._tick_boss()
	for i in range(6):
		await process_frame
		await physics_frame
	var boss: Node3D = null
	for child in main.get_node("World").get_children():
		if child.is_in_group("boss"):
			boss = child
	print("boss under World: ", boss != null)
	print("boss is_in_group enemies: ", boss != null and boss.is_in_group("enemies"))
	print("boss health: ", boss.health if boss else "null")
	quit(0)


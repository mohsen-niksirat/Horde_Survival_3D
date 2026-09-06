extends SceneTree
## V13 validation: 3 character .tres load; selecting a character applies
## its starting weapon + stat modifiers at run start.

var failures := 0

func _initialize() -> void:
	var game_manager := root.get_node("GameManager")

	# --- Resources load ---
	for id in ["mage", "paladin", "rogue"]:
		var c: CharacterData = load("res://data/characters/%s.tres" % id)
		_check(c != null and c.starting_weapon_id != "", "character loads: " + id)

	# --- Paladin: orbiting shield + 30% HP ---
	game_manager.selected_character_id = "paladin"
	var main_ps: PackedScene = load("res://scenes/main/Main.tscn")
	var main := main_ps.instantiate()
	root.add_child(main)
	for i in range(4):
		await process_frame
		await physics_frame
	var player: CharacterBody3D = main.get_node("World/Player")
	_check(player.weapon_controller.weapons[0].data.id == "orbiting_shield", "paladin starts with shield")
	_check(absf(player.health.max_hp - 130.0) < 0.01, "paladin +30 HP (max=%.0f)" % player.health.max_hp)
	var orbit_root: Node3D = player.get_node_or_null("OrbitRoot")
	_check(orbit_root != null and orbit_root.get_child_count() > 0, "paladin orbit node spawned")
	main.queue_free()
	await process_frame

	# --- Rogue: divine spear + 20% HP ---
	game_manager.selected_character_id = "rogue"
	var main2 := main_ps.instantiate()
	root.add_child(main2)
	for i in range(4):
		await process_frame
		await physics_frame
	var p2: CharacterBody3D = main2.get_node("World/Player")
	_check(p2.weapon_controller.weapons[0].data.id == "divine_spear", "rogue starts with spear")
	_check(absf(p2.health.max_hp - 80.0) < 0.01, "rogue -20 HP (max=%.0f)" % p2.health.max_hp)
	main2.queue_free()

	if failures == 0:
		print("V13_CHARS_PASS")
	else:
		print("V13_CHARS_FAIL failures=", failures)
	quit(0 if failures == 0 else 1)

func _check(cond: bool, label: String) -> void:
	if cond:
		print("OK: ", label)
	else:
		push_error("FAIL: " + label)
		failures += 1

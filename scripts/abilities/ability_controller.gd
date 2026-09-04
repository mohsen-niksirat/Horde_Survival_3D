extends Node
## AbilityController: cooldown-tracked active abilities bound to input
## actions. Per-run node owned by the player.

var abilities: Array = []           # [{data, cooldown_left}]
var _player: CharacterBody3D
var _enemy_manager: Node
var _projectile_root: Node3D

func setup(p_player: CharacterBody3D, p_enemy_manager: Node, p_projectile_root: Node3D) -> void:
	_player = p_player
	_enemy_manager = p_enemy_manager
	_projectile_root = p_projectile_root
	for path in ["res://data/abilities/meteor_strike.tres", "res://data/abilities/time_freeze.tres"]:
		if ResourceLoader.exists(path):
			abilities.append({"data": load(path), "cooldown_left": 0.0})

func _process(delta: float) -> void:
	if _player == null or not _player.is_player_alive():
		return
	for entry in abilities:
		entry["cooldown_left"] = maxf(entry["cooldown_left"] - delta, 0.0)
		if entry["cooldown_left"] == 0.0 and InputManager.is_action_just_pressed(entry["data"].input_action):
			entry["cooldown_left"] = entry["data"].cooldown
			_execute(entry["data"])

func get_cooldown_ratio(id: String) -> float:
	for entry in abilities:
		if entry["data"].id == id:
			var cd: float = entry["data"].cooldown
			return entry["cooldown_left"] / cd if cd > 0.0 else 0.0
	return 1.0

func _execute(data: AbilityData) -> void:
	match data.id:
		"meteor_strike":
			_meteor_strike(data)
		"time_freeze":
			_time_freeze(data)

func _meteor_strike(data: AbilityData) -> void:
	var enemies: Array = _enemy_manager.get_enemies_in_radius(_player.global_position, 20.0, 1)
	if enemies.is_empty():
		# Refund: nothing to hit
		return
	var target: Node3D = enemies[0]
	var center := target.global_position
	var hits: Array = _enemy_manager.get_enemies_in_radius(center, data.area)
	var might: float = _player.get_stat("might")
	for enemy in hits:
		var event := DamageEvent.new(data.damage * might, "meteor")
		event.status_effect = data.status_effect
		event.status_duration = 3.0
		enemy.health.take_damage(event)
		EventBus.enemy_damaged.emit(enemy, event.final_amount, false)
	# VFX: lightning strike reuse at larger scale
	var vfx_scene: PackedScene = load("res://scenes/weapons/LightningStrike.tscn")
	var vfx := vfx_scene.instantiate()
	_projectile_root.add_child(vfx)
	vfx.scale = Vector3(2.5, 2.5, 2.5)
	vfx.global_position = Vector3(center.x, 0, center.z)
	vfx.visible = true
	vfx.trigger(data, center, _enemy_manager, _player)

func _time_freeze(data: AbilityData) -> void:
	for enemy in _enemy_manager.active_enemies:
		if is_instance_valid(enemy):
			enemy.status.apply("freeze", data.duration)

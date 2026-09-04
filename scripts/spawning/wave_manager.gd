extends Node
## WaveManager: threat-budget spawning over a difficulty timeline.
## Owns SpawnManager duties (this is small enough to stay one system until
## modes require separate spawn strategies).

const CULL_DISTANCE := 75.0

var arena: Node3D
var player: Node3D
var enemy_manager: Node

var archetype_data: Dictionary = {}
var _spawn_timer: float = 0.0
var _active: bool = false

func setup(p_arena: Node3D, p_player: Node3D, p_enemy_manager: Node) -> void:
	arena = p_arena
	player = p_player
	enemy_manager = p_enemy_manager
	_load_archetypes()
	_active = true

func _load_archetypes() -> void:
	for id in ["basic_drone", "fast_wisp", "tank_golem", "swarm_bat", "shooter_turret"]:
		var path := "res://data/enemies/%s.tres" % id
		if ResourceLoader.exists(path):
			archetype_data[id] = load(path)

func stop() -> void:
	_active = false

func _process(delta: float) -> void:
	if not _active or player == null or not is_instance_valid(player):
		return
	if GameManager.state != GameManager.State.PLAYING and GameManager.state != GameManager.State.BOSS:
		return

	var minutes := RunManager.elapsed_time / 60.0
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = DifficultyManager.spawn_interval(minutes)
		_spawn_wave(minutes)

	_cull_far_enemies()

func _spawn_wave(minutes: float) -> void:
	# Population control first
	var cap: int = PerformanceManager.enemy_cap()
	var current: int = enemy_manager.enemy_count()
	if current >= cap:
		return
	var room: int = cap - current

	# Threat budget for this wave
	var budget: float = DifficultyManager.threat_budget(minutes)
	var level: int = player.experience.level if player.has_method("get") and "experience" in player else 1
	var difficulty := DifficultyManager.difficulty_multiplier(level, minutes)
	var hp_s := DifficultyManager.hp_scale(difficulty)
	var dmg_s := DifficultyManager.damage_scale(difficulty)
	var spd_s := DifficultyManager.speed_scale(difficulty)

	var allowed: Array = DifficultyManager.allowed_archetypes(minutes)
	var spawned := 0
	for i in range(24):
		if budget <= 0.0 or spawned >= room:
			break
		var data: EnemyData = _pick_archetype(allowed)
		if data == null:
			break
		if data.threat_cost > budget and spawned > 0:
			break
		var pos: Vector3 = arena.get_spawn_position(player.global_position)
		enemy_manager.queue_spawn(data, pos, player, hp_s, dmg_s, spd_s)
		budget -= data.threat_cost
		spawned += 1

func _pick_archetype(allowed: Array) -> EnemyData:
	var pool: Array = []
	var total_weight := 0.0
	for id in allowed:
		if archetype_data.has(id):
			var data: EnemyData = archetype_data[id]
			pool.append(data)
			total_weight += data.spawn_weight
	if pool.is_empty():
		return null
	var roll := randf() * total_weight
	for data in pool:
		roll -= data.spawn_weight
		if roll <= 0.0:
			return data
	return pool[0]

func _cull_far_enemies() -> void:
	# Recycle enemies too far from the player (arena is bounded anyway).
	var cull2 := CULL_DISTANCE * CULL_DISTANCE
	for enemy in enemy_manager.active_enemies.duplicate():
		if is_instance_valid(enemy) and enemy.global_position.distance_squared_to(player.global_position) > cull2:
			enemy_manager.release_enemy(enemy)

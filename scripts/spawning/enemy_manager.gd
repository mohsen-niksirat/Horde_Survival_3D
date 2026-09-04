extends Node
## Enemy registry: owns the active enemy list, the Enemy scene pool, and
## lookup queries for targeting. Created per-run by Main.

signal enemy_registered(enemy: Node)
signal enemy_released(enemy: Node)

const ENEMY_SCENE := "res://scenes/enemies/Enemy.tscn"

var active_enemies: Array = []
var _spawn_queue: Array = []

## Queue a spawn (deferred to next frame to keep spawner cheap).
func queue_spawn(data: EnemyData, position: Vector3, player: Node3D, hp_scale: float, dmg_scale: float, spd_scale: float) -> void:
	_spawn_queue.append({
		"data": data,
		"position": position,
		"player": player,
		"hp": hp_scale,
		"dmg": dmg_scale,
		"spd": spd_scale,
	})

func _process(_delta: float) -> void:
	if _spawn_queue.is_empty():
		return
	var queue := _spawn_queue
	_spawn_queue = []
	for req in queue:
		_spawn_now(req)

func _spawn_now(req: Dictionary) -> void:
	var enemy := PoolManager.acquire(ENEMY_SCENE)
	PoolManager.tag(enemy, ENEMY_SCENE)
	get_parent().add_child(enemy)
	enemy.global_position = req["position"]
	enemy.setup(req["data"], req["player"], req["hp"], req["dmg"], req["spd"])
	enemy.died.connect(_on_enemy_died.bind(enemy))
	active_enemies.append(enemy)
	PerformanceManager.active_enemies = active_enemies.size()
	enemy_registered.emit(enemy)

func _on_enemy_died(_enemy: Node, enemy: Node) -> void:
	release_enemy(enemy)

func release_enemy(enemy: Node) -> void:
	active_enemies.erase(enemy)
	PerformanceManager.active_enemies = active_enemies.size()
	enemy_released.emit(enemy)
	enemy.despawn()
	PoolManager.release(enemy)

## --- Queries (used by TargetingSystem at weapon cadence) ---

func get_enemies_in_radius(center: Vector3, radius: float, max_count: int = 0) -> Array:
	var out := []
	var r2 := radius * radius
	for e in active_enemies:
		if not is_instance_valid(e):
			continue
		if e.global_position.distance_squared_to(center) <= r2:
			out.append(e)
			if max_count > 0 and out.size() >= max_count:
				break
	return out

func get_all_enemies() -> Array:
	return active_enemies

func enemy_count() -> int:
	return active_enemies.size()

func clear_all() -> void:
	for e in active_enemies.duplicate():
		if is_instance_valid(e):
			release_enemy(e)
	_spawn_queue.clear()

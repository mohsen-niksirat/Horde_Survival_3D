extends Node3D
## Dragon Welp: the MVP pet. Follows the player with an orbit offset and
## auto-fires a small fireball at the nearest enemy. Architecture supports
## more pets later (each a Node3D with follow + behavior).

const FIRE_COOLDOWN := 2.0
const FOLLOW_SPEED := 10.0

@export var pet_color: Color = Color(1.0, 0.44, 0.26)

var level: int = 1
var _player: Node3D
var _enemy_manager: Node
var _projectile_root: Node3D
var _fire_timer: float = 1.5
var _angle: float = 0.0
var _base_offset: Vector3 = Vector3(1.6, 1.2, 1.2)

func setup(p_player: Node3D, p_enemy_manager: Node, p_projectile_root: Node3D, p_level: int = 1) -> void:
	_player = p_player
	_enemy_manager = p_enemy_manager
	_projectile_root = p_projectile_root
	level = p_level
	_angle = randf() * TAU

func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_angle += delta * 1.2
	var target := _player.global_position + _base_offset + Vector3(cos(_angle) * 0.5, 0, sin(_angle) * 0.5)
	global_position = global_position.lerp(target, 1.0 - exp(-FOLLOW_SPEED * delta))

	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = FIRE_COOLDOWN / maxf(level, 1.0)
		_fire()

func _fire() -> void:
	var enemies: Array = _enemy_manager.get_enemies_in_radius(global_position, 14.0, 1)
	if enemies.is_empty():
		return
	var target: Node3D = enemies[0]
	var might: float = 1.0
	if _player.has_method("get_stat"):
		might = _player.get_stat("might")
	var proj_scene := "res://scenes/weapons/MagicMissileProjectile.tscn"
	var proj: Node3D = PoolManager.acquire(proj_scene)
	PoolManager.tag(proj, proj_scene)
	_projectile_root.add_child(proj)
	var dir := (target.global_position + Vector3(0, 0.5, 0) - global_position).normalized()
	proj.setup_generic(8.0 * might * (1.0 + 0.5 * level), 16.0, 0, 0.0, true, "", 0.0, global_position, dir, "pet_dragon")

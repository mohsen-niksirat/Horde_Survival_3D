extends Node
## WeaponController: owns equipped WeaponInstances, ticks them, and is the
## combat bridge that spawns projectiles and applies damage.

const FIREBALL_SCENE := "res://scenes/weapons/FireballProjectile.tscn"

var weapons: Array = []

var _player: CharacterBody3D
var _enemy_manager: Node
var _projectile_root: Node3D

func setup(player: CharacterBody3D, enemy_manager: Node, projectile_root: Node3D) -> void:
	_player = player
	_enemy_manager = enemy_manager
	_projectile_root = projectile_root

func add_weapon(weapon_data: WeaponData) -> void:
	var inst := WeaponInstance.new()
	inst.setup(weapon_data, self)
	weapons.append(inst)

func _process(delta: float) -> void:
	if _player == null or not _player.is_player_alive():
		return
	for w in weapons:
		w.tick(delta, _player, _enemy_manager)

## Called by WeaponInstance when its cooldown elapses and a target exists.
func fire_weapon(weapon: WeaponInstance, player: Node3D, target: Node3D) -> void:
	match weapon.data.type:
		"projectile":
			_fire_projectile(weapon, player, target)
		"aoe":
			_fire_aoe(weapon, player, target)
		_:
			_fire_projectile(weapon, player, target)

func _fire_projectile(weapon: WeaponInstance, player: Node3D, target: Node3D) -> void:
	var count := weapon.get_projectile_count()
	var spawn_pos := player.global_position + Vector3(0, 1.2, 0)
	var might: float = 1.0
	if player.has_method("get_stat"):
		might = player.get_stat("might")
	for i in range(count):
		var proj := PoolManager.acquire(FIREBALL_SCENE)
		PoolManager.tag(proj, FIREBALL_SCENE)
		_projectile_root.add_child(proj)
		# Spread multiple projectiles slightly
		var aim := target.global_position + Vector3(0, 0.5, 0) - spawn_pos
		if i > 0:
			var spread := deg_to_rad(8.0 * i) * (1 if i % 2 == 1 else -1)
			aim = aim.rotated(Vector3.UP, spread)
		proj.setup(weapon, weapon.get_damage() * might, weapon.get_area() * player.get_stat("area_mult") if player.has_method("get_stat") else weapon.get_area(), weapon.get_crit_chance(), weapon.data, spawn_pos, aim.normalized())
	PerformanceManager.active_projectiles = _projectile_root.get_child_count()

func _fire_aoe(weapon: WeaponInstance, player: Node3D, target: Node3D) -> void:
	# Phase 7: ground AOE strikes (Lightning)
	pass

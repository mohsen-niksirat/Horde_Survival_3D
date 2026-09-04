extends Node
## WeaponController: owns equipped WeaponInstances, ticks them, and is the
## combat bridge that spawns projectiles/orbits/strikes and applies damage.

const SCENE_MAGIC_MISSILE := "res://scenes/weapons/MagicMissileProjectile.tscn"
const SCENE_SPEAR := "res://scenes/weapons/DivineSpearProjectile.tscn"
const SCENE_LIGHTNING_VFX := "res://scenes/weapons/LightningStrike.tscn"
const LIGHTNING_VFX_POOL := 6

var weapons: Array = []

var _player: CharacterBody3D
var _enemy_manager: Node
var _projectile_root: Node3D
var _orbit_root: Node3D
var _lightning_pool: Array = []
var _lightning_idx: int = 0

func setup(player: CharacterBody3D, enemy_manager: Node, projectile_root: Node3D) -> void:
	_player = player
	_enemy_manager = enemy_manager
	_projectile_root = projectile_root
	_orbit_root = Node3D.new()
	_orbit_root.name = "OrbitRoot"
	_player.add_child(_orbit_root)
	_prewarm_lightning()

func _prewarm_lightning() -> void:
	var scene: PackedScene = load(SCENE_LIGHTNING_VFX)
	for i in range(LIGHTNING_VFX_POOL):
		var vfx := scene.instantiate()
		vfx.visible = false
		_projectile_root.add_child(vfx)
		_lightning_pool.append(vfx)

func add_weapon(weapon_data: WeaponData) -> void:
	var inst := WeaponInstance.new()
	inst.setup(weapon_data, self)
	weapons.append(inst)
	if weapon_data.type == "orbit":
		var orbit := Node3D.new()
		orbit.name = "Orbiting_%s" % weapon_data.id
		orbit.set_script(load("res://scenes/weapons/orbiting_shield_weapon.gd"))
		_orbit_root.add_child(orbit)
		orbit.setup(inst, _player)

func _process(delta: float) -> void:
	if _player == null or not _player.is_player_alive():
		return
	for w in weapons:
		if w.data.type == "orbit":
			continue  # orbit weapon self-updates
		w.tick(delta, _player, _enemy_manager)

## Called by WeaponInstance when its cooldown elapses and a target exists.
func fire_weapon(weapon: WeaponInstance, player: Node3D, target: Node3D) -> void:
	match weapon.data.type:
		"projectile":
			_fire_projectile(weapon, player, target)
		"pierce":
			_fire_pierce(weapon, player, target)
		"aoe":
			_fire_aoe_strike(weapon, player, target)
		"orbit":
			pass  # handled by orbit node
		_:
			_fire_projectile(weapon, player, target)

func _fire_projectile(weapon: WeaponInstance, player: Node3D, target: Node3D) -> void:
	_spawn_projectile(weapon, player, target, weapon.data.projectile_scene)

func _fire_pierce(weapon: WeaponInstance, player: Node3D, target: Node3D) -> void:
	_spawn_projectile(weapon, player, target, weapon.data.projectile_scene)

func _spawn_projectile(weapon: WeaponInstance, player: Node3D, target: Node3D, scene_path: String) -> void:
	var count := weapon.get_projectile_count()
	var spawn_pos := player.global_position + Vector3(0, 1.2, 0)
	var might: float = player.get_stat("might")
	var area_mult: float = player.get_stat("area_mult")
	var pool_manager: Node = get_node("/root/PoolManager")
	for i in range(count):
		var proj: Node3D = pool_manager.acquire(scene_path)
		pool_manager.tag(proj, scene_path)
		_projectile_root.add_child(proj)
		var aim := target.global_position + Vector3(0, 0.5, 0) - spawn_pos
		if i > 0:
			var spread := deg_to_rad(8.0 * i) * (1 if i % 2 == 1 else -1)
			aim = aim.rotated(Vector3.UP, spread)
		if proj.has_method("setup_fireball"):
			proj.setup_fireball(weapon, weapon.get_damage() * might, weapon.get_area() * area_mult, weapon.get_crit_chance(), weapon.data, spawn_pos, aim.normalized())
		else:
			proj.setup_generic(
				weapon.get_damage() * might,
				weapon.data.projectile_speed,
				weapon.data.pierce,
				weapon.get_crit_chance(),
				weapon.data.homing,
				weapon.data.status_effect,
				weapon.data.status_duration,
				spawn_pos,
				aim.normalized(),
				weapon.data.id
			)
			if proj is Area3D:
				proj.rotation.y = atan2(aim.x, aim.z)
	PerformanceManager.active_projectiles = _projectile_root.get_child_count()

func _fire_aoe_strike(weapon: WeaponInstance, player: Node3D, target: Node3D) -> void:
	# Round-robin pooled lightning VFX
	var vfx: Node3D = _lightning_pool[_lightning_idx]
	_lightning_idx = (_lightning_idx + 1) % _lightning_pool.size()
	vfx.trigger(weapon, target.global_position, _enemy_manager, player)

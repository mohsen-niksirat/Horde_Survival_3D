extends Node
## WeaponController: owns equipped WeaponInstances, ticks them, and is the
## combat bridge that spawns projectiles/orbits/strikes and applies damage.

const SCENE_MAGIC_MISSILE := "res://scenes/weapons/MagicMissileProjectile.tscn"
const SCENE_SPEAR := "res://scenes/weapons/DivineSpearProjectile.tscn"
const SCENE_LIGHTNING_VFX := "res://scenes/weapons/LightningStrike.tscn"
const SCENE_MUZZLE_FLASH := "res://scenes/vfx/MuzzleFlash.tscn"
const LIGHTNING_VFX_POOL := 6
const MUZZLE_POOL := 4
## Muzzle position relative to the player (staff orb height)
const MUZZLE_HEIGHT := 1.2
## Visual color per weapon id (flash tint)
const WEAPON_FLASH_COLORS := {
	"fireball": Color(1.0, 0.5, 0.15),
	"magic_missile": Color(0.55, 0.75, 1.0),
	"holy_bible": Color(1.0, 0.9, 0.4),
	"divine_spear": Color(1.0, 0.85, 0.4),
	"lightning": Color(0.65, 0.8, 1.0),
	"hellfire": Color(1.0, 0.35, 0.1),
}

var weapons: Array = []

var _player: CharacterBody3D
var _enemy_manager: Node
var _projectile_root: Node3D
var _orbit_root: Node3D
var _lightning_pool: Array = []
var _lightning_idx: int = 0
var _muzzle_pool: Array = []
var _muzzle_idx: int = 0

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
	var flash_scene: PackedScene = load(SCENE_MUZZLE_FLASH)
	for i in range(MUZZLE_POOL):
		var flash := flash_scene.instantiate()
		flash.visible = false
		_projectile_root.add_child(flash)
		_muzzle_pool.append(flash)

func add_weapon(weapon_data: WeaponData) -> void:
	var inst := WeaponInstance.new()
	inst.setup(weapon_data, self)
	weapons.append(inst)
	if weapon_data.type == "orbit":
		# Recreate the orbit container if it was freed (restart/cleanup)
		if _orbit_root == null or not is_instance_valid(_orbit_root) or not _orbit_root.is_inside_tree():
			_orbit_root = Node3D.new()
			_orbit_root.name = "OrbitRoot"
			_player.add_child(_orbit_root)
		var orbit := Node3D.new()
		orbit.name = "Orbiting_%s" % weapon_data.id
		orbit.set_script(load("res://scenes/weapons/orbiting_shield_weapon.gd"))
		_orbit_root.add_child(orbit)
		orbit.setup(inst, _player)

func _process(delta: float) -> void:
	if _player == null or not _player.is_player_alive():
		return
	var start := Time.get_ticks_usec()
	for w in weapons:
		if w.data.type == "orbit":
			continue  # orbit weapon self-updates
		w.tick(delta, _player, _enemy_manager)
	PerformanceManager.report_system_time("weapons", Time.get_ticks_usec() - start)

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
	_play_fire_sfx(weapon.data.id)

func _fire_projectile(weapon: WeaponInstance, player: Node3D, target: Node3D) -> void:
	_spawn_projectile(weapon, player, target, weapon.data.projectile_scene)

func _fire_pierce(weapon: WeaponInstance, player: Node3D, target: Node3D) -> void:
	_spawn_projectile(weapon, player, target, weapon.data.projectile_scene)

func _spawn_projectile(weapon: WeaponInstance, player: Node3D, target: Node3D, scene_path: String) -> void:
	var count := weapon.get_projectile_count()
	var spawn_pos := player.global_position + Vector3(0, MUZZLE_HEIGHT, 0)
	var might: float = player.get_stat("might")
	var area_mult: float = player.get_stat("area_mult")
	var pool_manager: Node = get_node("/root/PoolManager")
	var aim := target.global_position + Vector3(0, 0.5, 0) - spawn_pos
	for i in range(count):
		var proj: Node3D = pool_manager.acquire(scene_path)
		pool_manager.tag(proj, scene_path)
		_projectile_root.add_child(proj)
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
	_muzzle_flash(player, aim.normalized(), weapon.data.id)
	PerformanceManager.active_projectiles = _projectile_root.get_child_count()

## Quick light burst at the staff orb, tinted per weapon.
func _muzzle_flash(player: Node3D, dir: Vector3, weapon_id: String) -> void:
	if _muzzle_pool.is_empty():
		return
	var flash: Node3D = _muzzle_pool[_muzzle_idx]
	_muzzle_idx = (_muzzle_idx + 1) % _muzzle_pool.size()
	flash.global_position = player.global_position + Vector3(0.38, MUZZLE_HEIGHT + 0.55, 0)
	flash.trigger(flash.global_position, dir)
	var tint: Color = WEAPON_FLASH_COLORS.get(weapon_id, Color(1, 0.9, 0.5))
	var core: MeshInstance3D = flash.get_node_or_null("Core")
	if core != null and core.get_surface_override_material(0) != null:
		var mat: StandardMaterial3D = core.get_surface_override_material(0)
		mat.albedo_color = Color(tint.r, tint.g, tint.b, 0.9)
		mat.emission = tint

## Distinct fire sound per weapon id.
func _play_fire_sfx(weapon_id: String) -> void:
	match weapon_id:
		"fireball", "hellfire":
			AudioManager.play_tone("shoot_fireball", 170.0, 0.1, "saw", -8.0)
		"magic_missile", "holy_bible":
			AudioManager.play_tone("shoot_missile", 880.0, 0.07, "sine", -12.0)
		"divine_spear":
			AudioManager.play_tone("shoot_spear", 480.0, 0.12, "square", -10.0)
		"lightning":
			AudioManager.play_tone("shoot_lightning", 100.0, 0.14, "noise", -6.0)
		_:
			AudioManager.play_game_sfx("weapon_fire")

func _fire_aoe_strike(weapon: WeaponInstance, player: Node3D, target: Node3D) -> void:
	# Round-robin pooled lightning VFX
	var vfx: Node3D = _lightning_pool[_lightning_idx]
	_lightning_idx = (_lightning_idx + 1) % _lightning_pool.size()
	vfx.trigger(weapon, target.global_position, _enemy_manager, player)

extends CharacterBody3D
## Horde enemy: chase steering, contact damage, death → XP drop.
## Spawned/recycled through PoolManager. Driven by EnemyData resource.

signal died(enemy: Node)

const GRAVITY := 25.0

var data: EnemyData
var health: Node
var status: Node
var elite: Node = null
var hp_scale: float = 1.0
var dmg_scale: float = 1.0
var spd_scale: float = 1.0
var base_spd_scale: float = 1.0
var xp_mult: float = 1.0
var gold_mult: float = 1.0
var dmg_mult: float = 1.0

var _player: Node3D
var _attack_timer: float = 0.0
var _wobble_seed: float = 0.0
var _alive: bool = false
var _mesh: MeshInstance3D
var _mat: StandardMaterial3D

func _ready() -> void:
	add_to_group("enemies")
	health = $HealthComponent
	health.died.connect(_on_died)
	health.damaged.connect(_on_damaged)
	status = $StatusComponent
	status.setup(self)
	_mesh = $Mesh
	_mat = _mesh.get_surface_override_material(0)
	if _mat == null:
		_mat = StandardMaterial3D.new()
		_mesh.set_surface_override_material(0, _mat)

func _on_damaged(event: DamageEvent) -> void:
	# Apply status from the damage pipeline
	if event.status_effect != "":
		status.apply(event.status_effect, event.status_duration)
	# Hit flash
	if data != null:
		_mat.albedo_color = Color(3, 3, 3)
		var tween := create_tween()
		tween.tween_property(_mat, "albedo_color", _base_color(), 0.12)

func _base_color() -> Color:
	return Color(1.0, 0.8, 0.2) if elite != null else data.color

func setup(p_data: EnemyData, p_player: Node3D, p_hp_scale: float, p_dmg_scale: float, p_spd_scale: float) -> void:
	data = p_data
	_player = p_player
	hp_scale = p_hp_scale
	dmg_scale = p_dmg_scale
	spd_scale = p_spd_scale
	base_spd_scale = p_spd_scale
	xp_mult = 1.0
	gold_mult = 1.0
	dmg_mult = 1.0
	_wobble_seed = randf() * TAU

	# Reset pooled state from a previous life
	elite = null
	health.damage_interceptor = Callable()
	status.clear_all()

	health.set_scaled(data.max_hp, data.armor, hp_scale)
	_mat.albedo_color = data.color
	var s: float = data.scale * (1.15 if hp_scale >= 3.0 else 1.0)
	_mesh.scale = Vector3(s, s, s)

	_attack_timer = randf_range(0.0, data.attack_cooldown)
	_alive = true

## Promote this enemy to an elite with the given abilities.
func make_elite(p_abilities: Array) -> void:
	if elite != null:
		return
	health.set_scaled(data.max_hp, data.armor, hp_scale * 3.0)
	dmg_mult = 2.0
	xp_mult = 10.0
	gold_mult = 5.0
	_mesh.scale *= 1.3
	# Golden tint for elite identity
	_mat.albedo_color = Color(1.0, 0.8, 0.2)
	elite = $EliteComponent
	elite.setup(self, _player, get_parent().get_parent().get_enemy_manager() if get_parent().get_parent().has_method("get_enemy_manager") else get_parent().get_parent(), p_abilities)

func _physics_process(delta: float) -> void:
	if not _alive or _player == null or not is_instance_valid(_player):
		return
	var _start := Time.get_ticks_usec()

	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()

	if dist > 0.01:
		var dir := to_player / dist
		# Movement behavior variants
		match data.movement_type:
			"wobble":
				var wobble := Vector3.UP.cross(dir).normalized()
				dir = (dir + wobble * sin(Time.get_ticks_msec() / 1000.0 * 8.0 + _wobble_seed) * 0.4).normalized()
			"sine":
				var sway := Vector3.UP.cross(dir).normalized()
				dir = (dir + sway * sin(Time.get_ticks_msec() / 1000.0 * 3.0 + _wobble_seed) * 0.3).normalized()
			"stationary":
				dir = Vector3.ZERO

		var speed: float = data.move_speed * spd_scale * status.get_speed_factor()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		move_and_slide()

		# Face player
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 8.0 * delta)

	# Contact attack
	_attack_timer -= delta
	if dist <= data.attack_range * 1.5 and _attack_timer <= 0.0:
		_attack_timer = data.attack_cooldown
		if _player.has_method("take_contact_damage"):
			_player.take_contact_damage(data.damage * dmg_scale * dmg_mult, global_position)
			if elite != null:
				elite.on_hit_player()
	# Aggregate AI time into the performance overlay (cheap u64 add)
	PerformanceManager.report_system_time("enemy_ai", Time.get_ticks_usec() - _start)

func get_health_ratio() -> float:
	return health.get_ratio()

func is_enemy_alive() -> bool:
	return _alive and health.is_alive()

func _on_died() -> void:
	if not _alive:
		return
	_alive = false
	if elite != null:
		elite.on_death()
	EventBus.enemy_died.emit(self, global_position)
	died.emit(self)
	# Death shrink effect happens while the pooled node leaves the tree
	if _mesh != null:
		var tween := create_tween()
		tween.tween_property(_mesh, "scale", Vector3(0.01, 0.01, 0.01), 0.18)
		tween.tween_callback(func(): _mesh.scale = Vector3.ONE)

## Called by the pool manager flow (or spawner) when recycled.
func despawn() -> void:
	_alive = false
	velocity = Vector3.ZERO

extends CharacterBody3D
## Horde enemy: chase steering, contact damage, death → XP drop.
## Spawned/recycled through PoolManager. Driven by EnemyData resource.

signal died(enemy: Node)

const GRAVITY := 25.0

var data: EnemyData
var health: Node
var status: Node
var hp_scale: float = 1.0
var dmg_scale: float = 1.0
var spd_scale: float = 1.0

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
		tween.tween_property(_mat, "albedo_color", data.color, 0.12)

func setup(p_data: EnemyData, p_player: Node3D, p_hp_scale: float, p_dmg_scale: float, p_spd_scale: float) -> void:
	data = p_data
	_player = p_player
	hp_scale = p_hp_scale
	dmg_scale = p_dmg_scale
	spd_scale = p_spd_scale
	_wobble_seed = randf() * TAU

	health.set_scaled(data.max_hp, data.armor, hp_scale)
	_mat.albedo_color = data.color
	var s: float = data.scale * (1.15 if hp_scale >= 3.0 else 1.0)
	_mesh.scale = Vector3(s, s, s)

	_attack_timer = randf_range(0.0, data.attack_cooldown)
	_alive = true

func _physics_process(delta: float) -> void:
	if not _alive or _player == null or not is_instance_valid(_player):
		return

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
			_player.take_contact_damage(data.damage * dmg_scale, global_position)

func get_health_ratio() -> float:
	return health.get_ratio()

func is_enemy_alive() -> bool:
	return _alive and health.is_alive()

func _on_died() -> void:
	if not _alive:
		return
	_alive = false
	EventBus.enemy_died.emit(self, global_position)
	died.emit(self)

## Called by the pool manager flow (or spawner) when recycled.
func despawn() -> void:
	_alive = false
	velocity = Vector3.ZERO

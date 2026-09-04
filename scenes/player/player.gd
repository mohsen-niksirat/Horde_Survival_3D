extends CharacterBody3D
## Third-person player: components drive movement, health, XP.
## Movement is camera-relative; the body rotates toward its velocity.

const CONTACT_INVINCIBILITY := 0.5

@onready var movement: Node = $MovementComponent
@onready var camera_rig: Node3D = $CameraRig
@onready var mesh: MeshInstance3D = $Mesh
@onready var health: Node = $HealthComponent
@onready var experience: Node = $ExperienceComponent

var _face_yaw: float = 0.0
var _bob_time: float = 0.0
var _base_mesh_y: float = 0.0
var _base_hp: float = 100.0

func _ready() -> void:
	add_to_group("player")
	movement.setup(self)
	_base_mesh_y = mesh.position.y
	_face_yaw = rotation.y
	camera_rig.set_target(self)
	health.setup(_base_hp)
	health.died.connect(_on_died)
	experience.leveled_up.connect(_on_leveled_up)
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.xp_collected.connect(_on_xp_collected)

func _on_xp_collected(amount: float) -> void:
	experience.add_xp(amount)

func _physics_process(delta: float) -> void:
	if not health.is_alive():
		return
	var input_vec := InputManager.get_move_vector()
	var basis: Basis = camera_rig.get_move_basis()
	var dir := (basis * Vector3(input_vec.x, 0, input_vec.y))
	var move2 := Vector2(dir.x, dir.z)

	movement.tick(delta, move2)

	if move2.length_squared() > 0.04:
		var target_yaw := atan2(move2.x, move2.y)
		_face_yaw = lerp_angle(_face_yaw, target_yaw, 12.0 * delta)
	rotation.y = _face_yaw

	var speed: float = movement.get_current_speed()
	if speed > 0.5:
		_bob_time += delta * speed * 1.6
		mesh.position.y = _base_mesh_y + absf(sin(_bob_time)) * 0.08
		mesh.rotation.x = lerpf(mesh.rotation.x, 0.08, 6.0 * delta)
	else:
		_bob_time = 0.0
		mesh.position.y = lerpf(mesh.position.y, _base_mesh_y, 8.0 * delta)
		mesh.rotation.x = lerpf(mesh.rotation.x, 0.0, 8.0 * delta)

func get_pickup_radius() -> float:
	return movement.get_max_speed() * 0.5 + 2.5

## Called by enemies on contact attacks.
func take_contact_damage(amount: float, from_position: Vector3) -> void:
	if health.invincible_timer > 0.0 or not health.is_alive():
		return
	var event := DamageEvent.new(amount, "contact")
	health.take_damage(event)
	EventBus.player_damaged.emit(amount)
	# Knockback push away from the attacker
	var push := (global_position - from_position)
	push.y = 0.0
	if push.length() > 0.01:
		push = push.normalized() * 2.0
		velocity += push
	# Short invincibility window between contact hits
	health.set_invincible(CONTACT_INVINCIBILITY)
	camera_rig.add_shake(0.08)

func _on_enemy_died(enemy: Node, position: Vector3) -> void:
	RunManager.register_kill()
	_drop_xp(enemy, position)

func _drop_xp(enemy: Node, position: Vector3) -> void:
	var data: EnemyData = enemy.data
	if data == null:
		return
	var orb_scene := "res://scenes/pickups/XpOrb.tscn"
	var orb_count := 1
	if data.xp >= 10.0:
		orb_count = 3
	elif data.xp >= 3.0:
		orb_count = 2
	var per_orb: float = data.xp / orb_count
	for i in range(orb_count):
		var orb := PoolManager.acquire(orb_scene)
		PoolManager.tag(orb, orb_scene)
		get_parent().add_child(orb)
		orb.setup(per_orb, self, position)

func _on_leveled_up(new_level: int) -> void:
	# Phase 6 replaces this with the full upgrade-choice flow.
	GameManager.open_level_up()
	await get_tree().create_timer(0.1, true, false, true).timeout
	GameManager.close_level_up()

func _on_died() -> void:
	EventBus.player_died.emit()
	GameManager.game_over(false)

func is_player_alive() -> bool:
	return health.is_alive()

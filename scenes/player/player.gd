extends CharacterBody3D
## Third-person player: components drive movement; camera rig follows.
## Movement is camera-relative; the body rotates toward its velocity.

@onready var movement: Node = $MovementComponent
@onready var camera_rig: Node3D = $CameraRig
@onready var mesh: MeshInstance3D = $Mesh

var _face_yaw: float = 0.0
var _bob_time: float = 0.0
var _base_mesh_y: float = 0.0

func _ready() -> void:
	movement.setup(self)
	_base_mesh_y = mesh.position.y
	_face_yaw = rotation.y
	camera_rig.set_target(self)

func _physics_process(delta: float) -> void:
	var input_vec := InputManager.get_move_vector()
	# Camera-relative direction
	var basis: Basis = camera_rig.get_move_basis()
	var dir := (basis * Vector3(input_vec.x, 0, input_vec.y))
	var move2 := Vector2(dir.x, dir.z)

	movement.tick(delta, move2)

	# Face movement direction
	if move2.length_squared() > 0.04:
		var target_yaw := atan2(move2.x, move2.y)
		_face_yaw = lerp_angle(_face_yaw, target_yaw, 12.0 * delta)
	rotation.y = _face_yaw

	# Procedural run bob (placeholder animation until rigged model)
	var speed: float = movement.get_current_speed()
	if speed > 0.5:
		_bob_time += delta * speed * 1.6
		mesh.position.y = _base_mesh_y + absf(sin(_bob_time)) * 0.08
		mesh.rotation.x = lerpf(mesh.rotation.x, 0.08, 6.0 * delta)
	else:
		_bob_time = 0.0
		mesh.position.y = lerpf(mesh.position.y, _base_mesh_y, 8.0 * delta)
		mesh.rotation.x = lerpf(mesh.rotation.x, 0.0, 8.0 * delta)

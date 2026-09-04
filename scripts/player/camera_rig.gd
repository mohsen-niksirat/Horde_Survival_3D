extends Node3D
## Third-person camera rig: yaw orbit, pitch clamp, spring-arm collision,
## dynamic zoom, and shake. Optimized for horde readability (player sits
## slightly below screen center; distance adapts to movement).

@export var target_path: NodePath
@export var distance: float = 8.0
@export var min_distance: float = 6.0
@export var max_distance: float = 10.0
@export var height: float = 2.2
@export var pitch_min_deg: float = -62.0
@export var pitch_max_deg: float = -18.0
@export var default_pitch_deg: float = -38.0
@export var yaw_sensitivity: float = 0.0032
@export var pitch_sensitivity: float = 0.0028
@export var position_smoothing: float = 8.0
@export var zoom_speed: float = 2.0

@export var shake_enabled: bool = true

var _target: Node3D
var _yaw: float = 0.0
var _pitch: float
var _current_distance: float
var _desired_distance: float
var _shake_amount: float = 0.0
var _shake_decay: float = 6.0

@onready var _spring_arm: SpringArm3D = $SpringArm3D
@onready var _camera: Camera3D = $SpringArm3D/Camera3D

func _ready() -> void:
	_pitch = deg_to_rad(default_pitch_deg)
	_current_distance = distance
	_desired_distance = distance
	_spring_arm.spring_length = distance
	if target_path != NodePath():
		_target = get_node(target_path)
	if _target:
		global_position = _target.global_position + Vector3(0, height, 0)

func set_target(target: Node3D) -> void:
	_target = target
	if _target:
		global_position = _target.global_position + Vector3(0, height, 0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * yaw_sensitivity
		_pitch -= event.relative.y * pitch_sensitivity
		_pitch = clampf(_pitch, deg_to_rad(pitch_min_deg), deg_to_rad(pitch_max_deg))

func _process(delta: float) -> void:
	if _target == null:
		return

	# Gamepad/arrow-key camera via InputManager's look delta
	var look := InputManager.get_look_delta()
	if look.length_squared() > 0.01:
		_yaw -= look.x * yaw_sensitivity
		_pitch -= look.y * pitch_sensitivity
		_pitch = clampf(_pitch, deg_to_rad(pitch_min_deg), deg_to_rad(pitch_max_deg))

	# Follow target smoothly (flat + height)
	var goal := _target.global_position + Vector3(0, height, 0)
	global_position = global_position.lerp(goal, 1.0 - exp(-position_smoothing * delta))

	# Dynamic zoom: closer when idle, farther when moving
	var target_moving := false
	if _target is CharacterBody3D:
		var v: Vector3 = _target.velocity
		target_moving = Vector2(v.x, v.z).length() > 1.0
	_desired_distance = min_distance if target_moving else max_distance
	_current_distance = lerpf(_current_distance, _desired_distance, 1.0 - exp(-zoom_speed * delta))
	_spring_arm.spring_length = _current_distance

	# Apply orbit
	rotation = Vector3(0, _yaw, 0)
	_spring_arm.rotation.x = _pitch

	# Shake
	if _shake_amount > 0.001:
		var offset := Vector3(
			randf_range(-1, 1) * _shake_amount,
			randf_range(-1, 1) * _shake_amount,
			0.0
		)
		_camera.h_offset = offset.x
		_camera.v_offset = offset.y
		_shake_amount = maxf(0.0, _shake_amount - _shake_amount * _shake_decay * delta)
	else:
		_camera.h_offset = 0.0
		_camera.v_offset = 0.0

func add_shake(amount: float) -> void:
	if not shake_enabled or not SaveManager.get_setting("screen_shake", true):
		return
	_shake_amount = minf(_shake_amount + amount, 0.6)

func get_move_basis() -> Basis:
	# Camera-relative movement basis (yaw only, flattened)
	return Basis(Vector3.UP, _yaw)

func get_yaw() -> float:
	return _yaw

extends CharacterBody3D
## Phase 1 placeholder player: falls to ground and can walk with WASD.
## Phase 2 replaces this with the full component-based third-person controller.

const SPEED := 6.0
const ACCEL := 12.0
const GRAVITY := 25.0

@onready var _mesh: MeshInstance3D = $Mesh

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	var input_vec := InputManager.get_move_vector()
	var target := Vector3(input_vec.x, 0, input_vec.y) * SPEED
	velocity.x = move_toward(velocity.x, target.x, ACCEL * delta * SPEED)
	velocity.z = move_toward(velocity.z, target.z, ACCEL * delta * SPEED)
	move_and_slide()

	# Face movement direction
	var flat := Vector2(velocity.x, velocity.z)
	if flat.length() > 0.5:
		rotation.y = lerp_angle(rotation.y, atan2(flat.x, flat.y), 10.0 * delta)

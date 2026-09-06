extends Area3D
## HeartPickup: rare drop that heals the player on contact. Pooled.

const GRAVITY := 18.0

var heal_amount: float = 20.0
var _player: Node3D
var _life: float = 0.0
var _vertical_velocity: float = 3.0
var _settled: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func setup(heal: float, p_player: Node3D, spawn_pos: Vector3) -> void:
	heal_amount = heal
	_player = p_player
	_life = 0.0
	_settled = false
	_vertical_velocity = 3.0
	global_position = spawn_pos + Vector3(randf_range(-0.5, 0.5), 0.8, randf_range(-0.5, 0.5))

func _process(delta: float) -> void:
	_life += delta
	if _life > 25.0:
		PoolManager.release(self)
		return
	_mesh_spin(delta)
	if not _settled:
		_vertical_velocity -= GRAVITY * delta
		global_position.y += _vertical_velocity * delta
		if global_position.y <= 0.5:
			global_position.y = 0.5
			_settled = true

@onready var _mesh: MeshInstance3D = $Mesh
func _mesh_spin(_delta: float) -> void:
	_mesh.rotation.y += 2.5 * _delta

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_method("take_contact_damage") == false:
		return
	body.health.heal(heal_amount)
	AudioManager.play_game_sfx("relic_pickup")
	set_deferred("monitoring", false)
	PoolManager.release(self)

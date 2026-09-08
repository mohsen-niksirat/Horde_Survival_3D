extends Area3D
## MagnetDrop: rare pickup — on contact, every XP shard on the map flies
## to the player. Pooled. Purple magnet gem.

const GRAVITY := 18.0

var _player: Node3D
var _life: float = 0.0
var _vertical_velocity: float = 3.0
var _settled: bool = false
var _mesh: MeshInstance3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_mesh = $Mesh

func setup(p_player: Node3D, spawn_pos: Vector3) -> void:
	_player = p_player
	_life = 0.0
	_settled = false
	_vertical_velocity = 3.0
	global_position = spawn_pos + Vector3(randf_range(-0.5, 0.5), 0.8, randf_range(-0.5, 0.5))
	set_deferred("monitoring", true)

func _process(delta: float) -> void:
	_life += delta
	if _life > 30.0:
		PoolManager.release(self)
		return
	_mesh.rotation.y += 3.0 * delta
	if not _settled:
		_vertical_velocity -= GRAVITY * delta
		global_position.y += _vertical_velocity * delta
		if global_position.y <= 0.5:
			global_position.y = 0.5
			_settled = true

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	set_deferred("monitoring", false)
	# Collect every XP shard on the map instantly (simpler + deterministic
	# versus long cross-map flight paths)
	var world: Node = body.get_parent()
	if world == null:
		return
	for shard in world.get_children():
		if is_instance_valid(shard) and shard.scene_file_path == "res://scenes/pickups/XpOrb.tscn" and shard.visible:
			EventBus.xp_collected.emit(shard.value)
			shard.set_deferred("monitoring", false)
			PoolManager.release(shard)
	AudioManager.play_game_sfx("xp_pickup")
	PoolManager.release(self)

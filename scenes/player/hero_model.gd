extends Node3D
## V1 hero model: stylized hooded mage built from primitives.
## Attaches to the Player node and provides mesh parts + procedural
## idle/run/staff-sway animation driven by the player's velocity.

@onready var root: Node3D = $"../Root"
@onready var robe: MeshInstance3D = $"../Root/Robe"
@onready var torso: MeshInstance3D = $"../Root/Torso"
@onready var hood: MeshInstance3D = $"../Root/Hood"
@onready var shoulder_l: MeshInstance3D = $"../Root/ShoulderL"
@onready var shoulder_r: MeshInstance3D = $"../Root/ShoulderR"
@onready var staff: Node3D = $"../Root/Staff"
@onready var orb: MeshInstance3D = $"../Root/Staff/Orb"

var _bob_time: float = 0.0
var _move_speed: float = 0.0

func _ready() -> void:
	pass

## Called every frame by the player with its current planar speed.
func animate(delta: float, speed: float) -> void:
	_move_speed = speed
	if speed > 0.5:
		# Run: quick bob + forward lean + staff swing
		_bob_time += delta * speed * 1.5
		var bob := absf(sin(_bob_time)) * 0.09
		root.position.y = bob
		root.rotation.x = lerpf(root.rotation.x, 0.1, 8.0 * delta)
		staff.rotation.z = lerpf(staff.rotation.z, -0.35 + sin(_bob_time * 2.0) * 0.12, 8.0 * delta)
	else:
		# Idle: slow breathing bob + staff sway
		_bob_time += delta * 2.0
		root.position.y = sin(_bob_time) * 0.03
		root.rotation.x = lerpf(root.rotation.x, 0.0, 6.0 * delta)
		staff.rotation.z = lerpf(staff.rotation.z, -0.3 + sin(_bob_time * 0.7) * 0.06, 4.0 * delta)
	# Orb pulse
	var pulse := 1.0 + sin(_bob_time * 2.5) * 0.08
	orb.scale = Vector3(pulse, pulse, pulse)

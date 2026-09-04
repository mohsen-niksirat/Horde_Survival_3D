class_name EnemyData
extends Resource
## Data-driven enemy definition (data/enemies/*.tres).

@export_group("Identity")
@export var id: String = "basic_drone"
@export var display_name: String = "Basic Drone"
@export var color: Color = Color(0.69, 0.745, 0.776)
@export var scale: float = 1.0

@export_group("Stats")
@export var max_hp: float = 15.0
@export var damage: float = 8.0
@export var move_speed: float = 3.0
@export var armor: float = 0.0

@export_group("Behavior")
@export_enum("chase", "wobble", "sine", "stationary", "kite") var movement_type: String = "chase"
@export var attack_range: float = 1.6
@export var attack_cooldown: float = 1.0

@export_group("Rewards")
@export var xp: float = 1.0
@export var gold: float = 0.5

@export_group("Spawning")
@export var spawn_weight: float = 10.0
@export var threat_cost: float = 1.0

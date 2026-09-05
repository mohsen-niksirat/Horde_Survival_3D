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
## Ghost-like phasing: periodic untargetable windows.
@export var phase_interval: float = 0.0   # 0 = never phases
@export var phase_duration: float = 1.0
## Splitter: spawn copies of this archetype id on death.
@export var splits_into: String = ""
@export var split_count: int = 0
## Healer: heals nearby allies (radius > 0 enables it).
@export var heal_radius: float = 0.0
@export var heal_pct: float = 0.0
@export var heal_cooldown: float = 2.0
## Mage-like ranged attack: fires boss projectiles at the player.
@export var ranged_attack: bool = false
@export var ranged_cooldown: float = 2.5
@export var ranged_damage: float = 10.0

@export_group("Rewards")
@export var xp: float = 1.0
@export var gold: float = 0.5

@export_group("Spawning")
@export var spawn_weight: float = 10.0
@export var threat_cost: float = 1.0

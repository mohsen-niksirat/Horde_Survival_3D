class_name WeaponData
extends Resource
## Data-driven weapon definition (data/weapons/*.tres).

@export_group("Identity")
@export var id: String = "fireball"
@export var display_name: String = "Fireball"
@export_enum("projectile", "orbit", "aoe", "pierce") var type: String = "projectile"

@export_group("Stats")
@export var base_damage: float = 20.0
@export var base_cooldown: float = 2.0
@export var projectile_count: int = 1
@export var projectile_speed: float = 18.0
@export var area: float = 2.2
@export var pierce: int = 0
@export var crit_chance: float = 0.05
@export var crit_mult: float = 2.0
@export var max_range: float = 30.0

@export_group("Status")
@export var status_effect: String = ""
@export var status_duration: float = 0.0
@export var status_damage: float = 0.0

@export_group("Tier Effects (1-5)")
## Per-tier multiplier overrides applied by WeaponInstance on level up.
@export var tier_damage_mult: Array[float] = [1.0, 1.0, 1.2, 1.2, 1.44]
@export var tier_cooldown_mult: Array[float] = [1.0, 0.95, 0.95, 0.9, 0.9]
@export var tier_projectile_bonus: Array[int] = [0, 1, 1, 1, 2]
@export var tier_area_mult: Array[float] = [1.0, 1.0, 1.3, 1.3, 1.69]

@export_group("Refs")
@export var projectile_scene: String = "res://scenes/weapons/FireballProjectile.tscn"

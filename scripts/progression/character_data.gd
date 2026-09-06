class_name CharacterData
extends Resource
## Playable character definition.

@export var id: String = "mage"
@export var display_name: String = "Mage"
@export var description: String = "Balanced spellslinger"
@export var color: Color = Color(0.42, 0.71, 1.0)
@export var starting_weapon_id: String = "fireball"
## Stat modifiers applied at run start (percent).
@export var max_hp_pct: float = 0.0
@export var move_speed_pct: float = 0.0
@export var might_pct: float = 0.0

class_name AbilityData
extends Resource
## Active ability definition (data/abilities/*.tres).

@export var id: String = "meteor_strike"
@export var display_name: String = "Meteor Strike"
@export var description: String = "Devastating AOE blast on the nearest enemy"
@export var cooldown: float = 25.0
@export var damage: float = 80.0
@export var area: float = 6.0
@export var duration: float = 0.0  # for timed effects like freeze
@export var status_effect: String = ""
@export var input_action: String = "ability_1"

## Interface parity with WeaponInstance for shared VFX helpers.
func get_damage() -> float:
	return damage

func get_area() -> float:
	return area

func get_crit_chance() -> float:
	return 0.0

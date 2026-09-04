class_name RelicData
extends Resource
## Map pickup relic: modifiers + optional special effect id.

@export var id: String = "crown"
@export var display_name: String = "Crown of Wisdom"
@export var rarity: String = "common"  # common/uncommon/rare/legendary
@export var description: String = "+25% XP gain"
## Array of Dictionaries: { "stat": String, "flat": float, "percent": float }
@export var modifiers: Array[Dictionary] = []
@export var special: String = ""  # "", "revive_once", "invuln_on_kill"

func rarity_weight() -> int:
	match rarity:
		"uncommon": return 30
		"rare": return 15
		"legendary": return 5
		_: return 50

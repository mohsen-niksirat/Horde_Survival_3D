class_name UpgradeOption
extends RefCounted
## One choice card on the level-up screen.

enum Kind { NEW_WEAPON, WEAPON_TIER, PASSIVE, HEAL, EVOLVE }

var kind: int = Kind.HEAL
var title: String = ""
var description: String = ""
var rarity: String = "common"   # common/rare/epic/legendary
var target: Resource = null     # WeaponData or PassiveData
var current_level: int = 0
var next_level: int = 0

func rarity_color() -> Color:
	match rarity:
		"rare": return Color(0.42, 0.71, 1.0)
		"epic": return Color(0.69, 0.61, 0.85)
		"legendary": return Color(1.0, 0.84, 0.0)
		_: return Color(0.69, 0.745, 0.776)

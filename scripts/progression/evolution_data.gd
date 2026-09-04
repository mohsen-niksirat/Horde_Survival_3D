class_name EvolutionData
extends Resource
## Weapon evolution recipe: weapon at tier 5 + maxed required passive.

@export var id: String = "hellfire"
@export var display_name: String = "Hellfire"
@export var base_weapon_id: String = "fireball"
@export var required_passive_id: String = "spinach"
@export var evolved_weapon: WeaponData

static func is_available(evolutions: Array, weapon_controller: Node, passive_levels: Dictionary) -> EvolutionData:
	for evo in evolutions:
		var data: EvolutionData = evo
		# Weapon at tier 5?
		var found := false
		for w in weapon_controller.weapons:
			if w.data.id == data.base_weapon_id and w.level >= 5:
				found = true
				break
		if not found:
			continue
		# Passive maxed?
		if passive_levels.get(data.required_passive_id, 0) >= _passive_max(data.required_passive_id):
			return data
	return null

static var _passive_cache: Dictionary = {}

static func _passive_max(id: String) -> int:
	if not _passive_cache.has(id):
		var path := "res://data/passives/%s.tres" % id
		if ResourceLoader.exists(path):
			var p = load(path)
			_passive_cache[id] = p.max_level
		else:
			_passive_cache[id] = 5
	return _passive_cache[id]

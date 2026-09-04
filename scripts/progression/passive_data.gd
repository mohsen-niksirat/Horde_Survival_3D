class_name PassiveData
extends Resource
## Passive upgrade item granting modifiers via StatBlock.

@export var id: String = "spinach"
@export var display_name: String = "Spinach"
@export var description: String = "+10% damage per level"
@export var max_level: int = 5
## Array of Dictionaries: { "stat": String, "flat": float, "percent": float }
@export var modifiers: Array[Dictionary] = []

func apply_per_level(stats: StatBlock, levels: int = 1) -> void:
	for m in modifiers:
		for i in range(levels):
			stats.add_modifier(m.get("stat", ""), m.get("flat", 0.0), m.get("percent", 0.0))

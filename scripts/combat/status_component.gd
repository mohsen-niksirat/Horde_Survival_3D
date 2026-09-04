extends Node
## StatusComponent: data-driven status effects (burn DoT, slow, freeze).
## Attached to enemies. Effects stored as dicts and expire cleanly —
## re-applied from base each tick (reference-game decay-bug guard).

signal effect_applied(effect_id: String)
signal effect_expired(effect_id: String)

## burn: {damage_per_sec, remaining}
## slow: {factor, remaining}   (factor < 1, e.g. 0.5 = half speed)
## freeze: {remaining}         (factor 0)
var _effects: Dictionary = {}

var base_move_speed: float = 3.0
var _root: Node

func setup(root: Node) -> void:
	_root = root

func _process(delta: float) -> void:
	if _effects.is_empty():
		return
	var expired: Array = []
	for id in _effects:
		var eff: Dictionary = _effects[id]
		eff["remaining"] -= delta
		if id == "burn" and _root != null and _root.health != null and _root.health.is_alive():
			var dmg := DamageEvent.new(eff["damage_per_sec"] * delta, "burn")
			_root.health.take_damage(dmg)
		if eff["remaining"] <= 0.0:
			expired.append(id)
	for id in expired:
		_effects.erase(id)
		effect_expired.emit(id)

## Apply or refresh a status effect.
func apply(id: String, duration: float, params: Dictionary = {}) -> void:
	var had := _effects.has(id)
	match id:
		"burn":
			_effects[id] = {"damage_per_sec": params.get("damage_per_sec", 8.0), "remaining": duration}
		"slow":
			_effects[id] = {"factor": params.get("factor", 0.5), "remaining": duration}
		"freeze":
			_effects[id] = {"factor": 0.0, "remaining": duration}
	if not had:
		effect_applied.emit(id)

func get_speed_factor() -> float:
	var factor := 1.0
	for id in _effects:
		factor = minf(factor, _effects[id].get("factor", 1.0))
	return factor

func has_effect(id: String) -> bool:
	return _effects.has(id)

func clear_all() -> void:
	_effects.clear()

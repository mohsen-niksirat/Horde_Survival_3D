class_name DamageEvent
extends RefCounted
## Single damage packet flowing through the combat pipeline.
## Created by weapons/hazards, consumed by HealthComponent.

var amount: float = 0.0
var final_amount: float = 0.0
var source_id: String = ""
var is_crit: bool = false
var status_effect: String = ""
var status_duration: float = 0.0
var knockback: float = 0.0
var position: Vector3 = Vector3.ZERO

func _init(p_amount: float, p_source: String = "", p_crit: bool = false) -> void:
	amount = p_amount
	source_id = p_source
	is_crit = p_crit

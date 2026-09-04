extends Node3D
## LightningStrike VFX: one-shot bolt + ground ring, AOE damage on spawn.
## Auto-recycles after its lifetime.

const LIFETIME := 0.35

var _life: float = 0.0
var _active: bool = false

func _ready() -> void:
	visible = false

## weapon_like: WeaponInstance or AbilityData — needs get_damage/get_area/get_crit_chance
func trigger(weapon_like, target_pos: Vector3, enemy_manager: Node, player: Node3D) -> void:
	global_position = target_pos
	_life = 0.0
	_active = true
	visible = true

	# AOE damage in the strike area
	var radius: float = weapon_like.get_area()
	var hits: Array = enemy_manager.get_enemies_in_radius(global_position, radius)
	var might: float = 1.0
	if player.has_method("get_stat"):
		might = player.get_stat("might")
	for enemy in hits:
		var is_crit: bool = randf() < weapon_like.get_crit_chance()
		var event := DamageEvent.new(weapon_like.get_damage() * might * (2.0 if is_crit else 1.0), "lightning", is_crit)
		enemy.health.take_damage(event)
		EventBus.enemy_damaged.emit(enemy, event.final_amount, is_crit)

func _process(delta: float) -> void:
	if not _active:
		return
	_life += delta
	scale = Vector3.ONE * (1.0 + _life * 2.0)
	if _life > LIFETIME:
		_active = false
		visible = false
		scale = Vector3.ONE

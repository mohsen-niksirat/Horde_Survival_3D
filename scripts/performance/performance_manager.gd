extends Node
## Performance budgets and quality tiers. Owns entity/particle caps and
## dynamic degradation decisions.

signal quality_changed(tier: int)

enum Quality { LOW, MEDIUM, HIGH }

## Entity budgets per quality tier.
const ENEMY_CAPS := {Quality.LOW: 100, Quality.MEDIUM: 160, Quality.HIGH: 240}
const PROJECTILE_CAPS := {Quality.LOW: 80, Quality.MEDIUM: 120, Quality.HIGH: 180}
const PARTICLE_CAPS := {Quality.LOW: 50, Quality.MEDIUM: 90, Quality.HIGH: 140}
const DAMAGE_NUMBER_CAPS := {Quality.LOW: 20, Quality.MEDIUM: 30, Quality.HIGH: 40}

var quality: int = Quality.MEDIUM

## Live counters (updated by spawners/pools each frame or on change).
var active_enemies: int = 0
var active_projectiles: int = 0
var active_particles: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var saved: int = SaveManager.get_setting("quality", Quality.MEDIUM)
	set_quality(saved, false)

func set_quality(tier: int, save: bool = true) -> void:
	quality = clampi(tier, Quality.LOW, Quality.HIGH)
	if save:
		SaveManager.set_setting("quality", quality)
	quality_changed.emit(quality)

func enemy_cap() -> int:
	return ENEMY_CAPS[quality]

func projectile_cap() -> int:
	return PROJECTILE_CAPS[quality]

func particle_cap() -> int:
	return PARTICLE_CAPS[quality]

func damage_number_cap() -> int:
	return DAMAGE_NUMBER_CAPS[quality]

## Debug overlay data (Phase 10/11 will render this).
func get_debug_info() -> String:
	return "FPS: %d | Enemies: %d | Projectiles: %d | Particles: %d" % [
		Engine.get_frames_per_second(),
		active_enemies,
		active_projectiles,
		active_particles,
	]

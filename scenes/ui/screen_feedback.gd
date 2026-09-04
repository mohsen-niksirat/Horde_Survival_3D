extends Control
## ScreenFeedback: low-HP vignette pulse + level-up flash + boss warning.
## Pure visuals, driven by EventBus; respects the screen_shake-quality-style
## settings (tied to show_particles-style toggles later).

@onready var vignette: ColorRect = $Vignette
@onready var flash: ColorRect = $Flash

var _player: Node

func bind_player(player: Node) -> void:
	_player = player
	EventBus.player_leveled_up.connect(_on_level_up)
	EventBus.boss_spawned.connect(_on_boss_spawned)
	vignette.modulate.a = 0.0
	flash.modulate.a = 0.0

func _process(delta: float) -> void:
	# Low-HP pulsing vignette (<30%)
	if _player != null and is_instance_valid(_player) and _player.health.is_alive():
		var ratio: float = _player.health.get_ratio()
		if ratio < 0.3:
			var intensity: float = (0.3 - ratio) / 0.3
			vignette.modulate.a = 0.25 + intensity * 0.3 + sin(Time.get_ticks_msec() / 1000.0 * 6.0) * 0.1
		else:
			vignette.modulate.a = maxf(vignette.modulate.a - delta * 2.0, 0.0)
	else:
		vignette.modulate.a = maxf(vignette.modulate.a - delta * 2.0, 0.0)
	flash.modulate.a = maxf(flash.modulate.a - delta * 2.5, 0.0)

func _on_level_up(_level: int) -> void:
	flash.color = Color(1, 0.95, 0.7)
	flash.modulate.a = 0.45

func _on_boss_spawned(_boss: Node) -> void:
	flash.color = Color(1, 0.45, 0.2)
	flash.modulate.a = 0.5

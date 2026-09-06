extends Node
## Performance budgets and quality tiers. Owns entity/particle caps,
## dynamic degradation decisions, and the profiling stats shown in the
## F3 debug overlay.

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

## Per-system frame-time rolling stats (milliseconds, ~10-frame average).
## Systems report via report_system_time() in their own _process.
var _system_times: Dictionary = {}   # name -> {total_usec, frames}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var saved = SaveManager.get_setting("quality", -1)
	if int(saved) >= Quality.LOW and int(saved) <= Quality.HIGH:
		quality = int(saved)
	else:
		# V10 auto-detection: mobile web / touch devices default to MEDIUM
		quality = Quality.MEDIUM if DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") else Quality.HIGH
	quality_changed.emit(quality)

## V10: shadows are the first thing to drop on LOW tier.
func _process(_delta: float) -> void:
	var root := get_tree().root
	var suns := root.find_children("*", "DirectionalLight3D", true, false)
	for sun in suns:
		if sun is DirectionalLight3D:
			sun.shadow_enabled = quality != Quality.LOW

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

## Add one frame's elapsed microseconds for a named system.
## Call report_system_time(name, end - start) once per _process tick.
func report_system_time(name: String, elapsed_usec: int) -> void:
	if not _system_times.has(name):
		_system_times[name] = {"total": 0, "frames": 0}
	var stat: Dictionary = _system_times[name]
	stat["total"] += elapsed_usec
	stat["frames"] += 1
	# Rolling window: reset every ~10 frames to keep the average recent
	if stat["frames"] >= 10:
		stat["total"] = int(stat["total"] / float(stat["frames"]))
		stat["frames"] = 1

func get_system_avg_ms(name: String) -> float:
	if not _system_times.has(name):
		return 0.0
	var stat: Dictionary = _system_times[name]
	if stat["frames"] == 0:
		return 0.0
	return stat["total"] / float(stat["frames"]) / 1000.0

## Debug overlay data (multi-line; F3 toggles it).
func get_debug_info() -> String:
	var lines: Array[String] = []
	lines.append("FPS: %d | frame: %.2f ms | physics: %.2f ms" % [
		Engine.get_frames_per_second(),
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
	])
	lines.append("draw calls: %d | primitives: %dk | objects: %d " % [
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000.0),
		Performance.get_monitor(Performance.OBJECT_COUNT),
	])
	lines.append("enemies: %d | projectiles: %d | particles: %d" % [
		active_enemies, active_projectiles, active_particles,
	])
	# Per-system averages (only reported ones)
	var sys_lines: Array[String] = []
	for name in _system_times:
		sys_lines.append("%s: %.2f ms" % [name, get_system_avg_ms(name)])
	if not sys_lines.is_empty():
		lines.append(" | ".join(sys_lines))
	return "\n".join(lines)

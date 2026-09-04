extends Node3D
## Root game orchestrator: owns per-run systems (enemy manager), global input
## routing, mouse capture, and the debug overlay.

const ENEMY_MANAGER := preload("res://scripts/spawning/enemy_manager.gd")
const WAVE_MANAGER := preload("res://scripts/spawning/wave_manager.gd")

@onready var player: CharacterBody3D = $World/Player
@onready var touch_controls: Control = $HUD/TouchControls
@onready var debug_label: Label = $HUD/DebugLabel

var enemy_manager: Node
var wave_manager: Node
var projectile_root: Node3D
var _debug_enabled: bool = false

func _ready() -> void:
	RunManager.start_run()
	GameManager.change_state(GameManager.State.PLAYING)

	enemy_manager = Node.new()
	enemy_manager.set_script(ENEMY_MANAGER)
	enemy_manager.name = "EnemyManager"
	add_child(enemy_manager)

	# Projectile container + weapon binding
	projectile_root = Node3D.new()
	projectile_root.name = "Projectiles"
	add_child(projectile_root)
	player.bind_combat(enemy_manager, projectile_root)

	# Horde spawning (Phase 5)
	wave_manager = Node.new()
	wave_manager.set_script(WAVE_MANAGER)
	wave_manager.name = "WaveManager"
	add_child(wave_manager)
	wave_manager.setup($World, player, enemy_manager)

	if DisplayServer.is_touchscreen_available():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		touch_controls.visible = true
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		touch_controls.visible = false

	debug_label.visible = false

func get_enemy_manager() -> Node:
	return enemy_manager

func _unhandled_input(event: InputEvent) -> void:
	if InputManager.is_pause_just_pressed():
		_toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F3:
			_debug_enabled = not _debug_enabled
			debug_label.visible = _debug_enabled
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton and event.pressed:
		if not DisplayServer.is_touchscreen_available() and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			if GameManager.state == GameManager.State.PLAYING:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _toggle_pause() -> void:
	if GameManager.state == GameManager.State.PLAYING or GameManager.state == GameManager.State.BOSS:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		GameManager.pause_game()
	elif GameManager.state == GameManager.State.PAUSED:
		GameManager.resume_game()
		if not DisplayServer.is_touchscreen_available():
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(_delta: float) -> void:
	if _debug_enabled:
		debug_label.text = PerformanceManager.get_debug_info()

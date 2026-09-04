extends Node3D
## Root game orchestrator: owns per-run systems and routes global input.

func _ready() -> void:
	# Fresh per-run state.
	RunManager.start_run()
	GameManager.change_state(GameManager.State.PLAYING)

func _unhandled_input(_event: InputEvent) -> void:
	if InputManager.is_pause_just_pressed():
		_toggle_pause()

func _toggle_pause() -> void:
	if GameManager.state == GameManager.State.PLAYING or GameManager.state == GameManager.State.BOSS:
		GameManager.pause_game()
	elif GameManager.state == GameManager.State.PAUSED:
		GameManager.resume_game()

extends Control
## Pause overlay: shown while GameManager.State == PAUSED.
## Resume / Restart / Main Menu.

@onready var resume_button: Button = $Center/Panel/Layout/ResumeButton
@onready var restart_button: Button = $Center/Panel/Layout/RestartButton
@onready var menu_button: Button = $Center/Panel/Layout/MenuButton

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	resume_button.pressed.connect(_on_resume)
	restart_button.pressed.connect(_on_restart)
	menu_button.pressed.connect(_on_menu)
	EventBus.game_state_changed.connect(_on_state_changed)

func _on_state_changed(new_state: int, _old: int) -> void:
	visible = new_state == GameManager.State.PAUSED

func _on_resume() -> void:
	GameManager.resume_game()

func _on_restart() -> void:
	GameManager.start_game()

func _on_menu() -> void:
	GameManager.goto_menu()

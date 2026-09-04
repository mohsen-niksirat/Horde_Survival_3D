extends Control
## Boot scene: loading text, then straight to the main menu.
## Web builds get a "Click to Play" gate (user gesture unlocks audio +
## enables fullscreen-friendly input) — desktop skips it.

@onready var click_label: Label = $ClickLabel

var _waiting_for_click: bool = false

func _ready() -> void:
	await get_tree().process_frame
	AudioManager.apply_saved_volumes()
	if OS.get_name() == "Web":
		click_label.visible = true
		_waiting_for_click = true
	else:
		_go_menu()

func _input(event: InputEvent) -> void:
	if not _waiting_for_click:
		return
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed):
		_waiting_for_click = false
		click_label.visible = false
		_go_menu()

func _go_menu() -> void:
	GameManager.goto_menu()

extends Control
## Boot scene: minimal loading, then straight to the main menu.

func _ready() -> void:
	# Give autoloads one frame to initialize fully.
	await get_tree().process_frame
	GameManager.goto_menu()

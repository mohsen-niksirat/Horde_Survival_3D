extends Control
## Main menu: Play, Characters, Weapons, Achievements, Settings, How to Play.
## MVP keeps locked sections as functional placeholders.

@onready var play_button: Button = $Center/Layout/PlayButton
@onready var characters_button: Button = $Center/Layout/CharactersButton
@onready var weapons_button: Button = $Center/Layout/WeaponsButton
@onready var achievements_button: Button = $Center/Layout/AchievementsButton
@onready var settings_button: Button = $Center/Layout/SettingsButton
@onready var how_to_play_button: Button = $Center/Layout/HowToPlayButton
@onready var quit_button: Button = $Center/Layout/QuitButton
@onready var notice_label: Label = $Notice

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	characters_button.pressed.connect(_on_placeholder_pressed.bind("Characters coming in Phase 6+"))
	weapons_button.pressed.connect(_on_placeholder_pressed.bind("Weapons collection coming soon"))
	achievements_button.pressed.connect(_on_placeholder_pressed.bind("Achievements coming in Phase 9"))
	settings_button.pressed.connect(_on_placeholder_pressed.bind("Settings coming in Phase 10"))
	how_to_play_button.pressed.connect(_on_placeholder_pressed.bind("WASD to move - survive the horde - weapons fire automatically"))
	quit_button.pressed.connect(_on_quit_pressed)
	notice_label.text = ""

func _on_play_pressed() -> void:
	play_button.disabled = true
	GameManager.start_game()

func _on_placeholder_pressed(message: String) -> void:
	notice_label.text = message

func _on_quit_pressed() -> void:
	if OS.get_name() == "Web":
		return
	get_tree().quit()

extends Control
## Settings: volume sliders + quality + shake toggle. Persisted via SaveManager.

@onready var master_slider: HSlider = $Center/Panel/Layout/MasterRow/MasterSlider
@onready var music_slider: HSlider = $Center/Panel/Layout/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $Center/Panel/Layout/SfxRow/SfxSlider
@onready var shake_check: CheckButton = $Center/Panel/Layout/ShakeCheck
@onready var quality_option: OptionButton = $Center/Panel/Layout/QualityRow/QualityOption
@onready var close_button: Button = $Center/Panel/Layout/CloseButton

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	quality_option.clear()
	quality_option.add_item("Low")
	quality_option.add_item("Medium")
	quality_option.add_item("High")

	master_slider.value = SaveManager.get_setting("master_volume", 0.8)
	music_slider.value = SaveManager.get_setting("music_volume", 0.7)
	sfx_slider.value = SaveManager.get_setting("sfx_volume", 0.8)
	shake_check.button_pressed = SaveManager.get_setting("screen_shake", true)
	quality_option.selected = SaveManager.get_setting("quality", 1)

	master_slider.value_changed.connect(_on_volume.bind("master_volume"))
	music_slider.value_changed.connect(_on_volume.bind("music_volume"))
	sfx_slider.value_changed.connect(_on_volume.bind("sfx_volume"))
	shake_check.toggled.connect(_on_shake)
	quality_option.item_selected.connect(_on_quality)
	close_button.pressed.connect(_on_close)
	EventBus.game_state_changed.connect(_on_state_changed)

func _on_state_changed(_new_state: int, _old: int) -> void:
	pass

func open() -> void:
	visible = true

func _on_volume(value: float, key: String) -> void:
	SaveManager.set_setting(key, value)
	AudioManager.apply_saved_volumes()

func _on_shake(pressed: bool) -> void:
	SaveManager.set_setting("screen_shake", pressed)

func _on_quality(index: int) -> void:
	PerformanceManager.set_quality(index)

func _on_close() -> void:
	visible = false

extends Control
## Settings: volume sliders + quality + shake toggle. Persisted via SaveManager.

@onready var master_slider: HSlider = $Center/Panel/Layout/MasterRow/MasterSlider
@onready var music_slider: HSlider = $Center/Panel/Layout/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $Center/Panel/Layout/SfxRow/SfxSlider
@onready var sensitivity_slider: HSlider = $Center/Panel/Layout/SensRow/SensSlider
@onready var touch_sens_slider: HSlider = $Center/Panel/Layout/TouchSensRow/TouchSensSlider
@onready var haptics_check: CheckButton = $Center/Panel/Layout/HapticsCheck
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
	quality_option.add_item("Auto")

	master_slider.value = SaveManager.get_setting("master_volume", 0.8)
	music_slider.value = SaveManager.get_setting("music_volume", 0.7)
	sfx_slider.value = SaveManager.get_setting("sfx_volume", 0.8)
	sensitivity_slider.value = SaveManager.get_setting("look_sensitivity", 1.0)
	touch_sens_slider.value = SaveManager.get_setting("touch_sensitivity", 1.0)
	haptics_check.button_pressed = SaveManager.get_setting("haptics", false)
	shake_check.button_pressed = SaveManager.get_setting("screen_shake", true)
	quality_option.selected = SaveManager.get_setting("quality", 1)

	master_slider.value_changed.connect(_on_volume.bind("master_volume"))
	music_slider.value_changed.connect(_on_volume.bind("music_volume"))
	sfx_slider.value_changed.connect(_on_volume.bind("sfx_volume"))
	sensitivity_slider.value_changed.connect(_on_sensitivity)
	touch_sens_slider.value_changed.connect(_on_touch_sensitivity)
	haptics_check.toggled.connect(_on_haptics)
	shake_check.toggled.connect(_on_shake)
	quality_option.item_selected.connect(_on_quality)
	close_button.pressed.connect(_on_close)
	EventBus.game_state_changed.connect(_on_state_changed)

func _on_sensitivity(value: float) -> void:
	SaveManager.set_setting("look_sensitivity", value)

func _on_touch_sensitivity(value: float) -> void:
	SaveManager.set_setting("touch_sensitivity", value)

func _on_haptics(pressed: bool) -> void:
	SaveManager.set_setting("haptics", pressed)

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
	PerformanceManager.auto_mode = index == 3
	if index != 3:
		PerformanceManager.set_quality(index)
	if PerformanceManager.auto_mode:
		PerformanceManager.set_quality(PerformanceManager.Quality.HIGH)

func _on_close() -> void:
	visible = false

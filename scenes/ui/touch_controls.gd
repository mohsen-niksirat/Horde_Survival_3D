extends Control
## Mobile touch controls: left virtual joystick (movement) + right look region.
## Feeds InputManager; only visible on touch devices.

@onready var joystick_base: Control = $JoystickBase
@onready var joystick_knob: Control = $JoystickBase/Knob
@onready var look_region: Control = $LookRegion

const JOYSTICK_RADIUS := 110.0
const DEAD_ZONE := 0.12

var _joy_touch_index: int = -1
var _joy_center: Vector2 = Vector2.ZERO
var _look_touch_index: int = -1
var _look_last: Vector2 = Vector2.ZERO

func _ready() -> void:
	visible = false
	# Show only where touch is the primary input (web mobile / Android).
	if DisplayServer.is_touchscreen_available():
		visible = true
		joystick_base.modulate.a = 0.45

func _gui_input(event: InputEvent) -> void:
	pass

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _joy_touch_index == -1 and event.position.x < get_viewport_rect().size.x * 0.45:
			_joy_touch_index = event.index
			_joy_center = event.position
			joystick_base.position = _joy_center - joystick_base.size * 0.5
			joystick_base.modulate.a = 0.7
		elif _look_touch_index == -1 and look_region.get_global_rect().has_point(event.position):
			_look_touch_index = event.index
			_look_last = event.position
	else:
		if event.index == _joy_touch_index:
			_joy_touch_index = -1
			_reset_joystick()
		elif event.index == _look_touch_index:
			_look_touch_index = -1

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == _joy_touch_index:
		var offset := event.position - _joy_center
		var length := offset.length()
		if length > JOYSTICK_RADIUS:
			offset = offset.normalized() * JOYSTICK_RADIUS
		joystick_knob.position = joystick_base.size * 0.5 + offset - joystick_knob.size * 0.5
		var vec := offset / JOYSTICK_RADIUS
		if vec.length() < DEAD_ZONE:
			vec = Vector2.ZERO
		else:
			vec = (vec - vec.normalized() * DEAD_ZONE) / (1.0 - DEAD_ZONE)
		InputManager.set_touch_move_vector(Vector2(vec.x, vec.y))
	elif event.index == _look_touch_index:
		var delta := event.position - _look_last
		_look_last = event.position
		InputManager.set_touch_look_delta(delta)

func _reset_joystick() -> void:
	joystick_knob.position = joystick_base.size * 0.5 - joystick_knob.size * 0.5
	InputManager.set_touch_move_vector(Vector2.ZERO)

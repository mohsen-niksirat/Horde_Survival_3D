extends Control
## Mobile touch controls (CoD-style, button zoom):
## - Left half: floating joystick wherever touched (movement only)
## - Right half: camera look — completely independent of movement
## - Zoom IN/OUT buttons (bottom-right, above ability buttons)
## No two-finger pinch: it conflicts with the look finger on small screens.

const JOYSTICK_RADIUS := 110.0
const DEAD_ZONE := 0.12
const BUTTON_ZOOM_STEP := 0.18

@onready var joystick_base: Control = $JoystickBase
@onready var joystick_knob: Control = $JoystickBase/Knob
@onready var zoom_in: Button = $ZoomIn
@onready var zoom_out: Button = $ZoomOut

func _ready() -> void:
	visible = false
	if DisplayServer.is_touchscreen_available():
		visible = true
		joystick_base.modulate.a = 0.45
	zoom_in.pressed.connect(func(): InputManager.add_zoom_delta(-BUTTON_ZOOM_STEP))
	zoom_out.pressed.connect(func(): InputManager.add_zoom_delta(BUTTON_ZOOM_STEP))

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		var half := get_viewport_rect().size.x * 0.5
		if _joy_index == -1 and event.position.x < half:
			_joy_index = event.index
			_joy_center = event.position
			joystick_base.position = _joy_center - joystick_base.size * 0.5
			joystick_base.modulate.a = 0.7
		elif _look_index == -1 and event.position.x >= half:
			_look_index = event.index
			_look_last = event.position
	else:
		if event.index == _joy_index:
			_joy_index = -1
			_reset_joystick()
		elif event.index == _look_index:
			_look_index = -1

var _joy_index: int = -1
var _joy_center: Vector2 = Vector2.ZERO
var _look_index: int = -1
var _look_last: Vector2 = Vector2.ZERO

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == _joy_index:
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
	elif event.index == _look_index:
		InputManager.set_touch_look_delta(event.position - _look_last)
		_look_last = event.position

func _reset_joystick() -> void:
	joystick_knob.position = joystick_base.size * 0.5 - joystick_knob.size * 0.5
	InputManager.set_touch_move_vector(Vector2.ZERO)

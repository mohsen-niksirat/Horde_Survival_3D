extends Control
## Mobile touch controls (CoD-style):
## - Left half: floating joystick wherever touched (movement only)
## - Right half: first finger = camera look
## - Right half: second finger starts PINCH ZOOM with the first look finger
## The movement finger never participates in pinch, so moving + looking
## at the same time is clean. Feeds InputManager; touch devices only.

const JOYSTICK_RADIUS := 110.0
const DEAD_ZONE := 0.12
const PINCH_ZOOM_SCALE := 0.004

@onready var joystick_base: Control = $JoystickBase
@onready var joystick_knob: Control = $JoystickBase/Knob

var _joy_index: int = -1
var _joy_center: Vector2 = Vector2.ZERO
var _look_index: int = -1
var _look_last: Vector2 = Vector2.ZERO
var _look_current: Vector2 = Vector2.ZERO
var _pinch_index: int = -1
var _pinch_current: Vector2 = Vector2.ZERO
var _pinch_last_dist: float = 0.0

func _ready() -> void:
	visible = false
	if DisplayServer.is_touchscreen_available():
		visible = true
		joystick_base.modulate.a = 0.45

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
			_look_current = event.position
		elif _look_index != -1 and _pinch_index == -1 and event.position.x >= half:
			# Second right-half finger: pinch zoom with the look finger
			_pinch_index = event.index
			_pinch_current = event.position
			_pinch_last_dist = _look_current.distance_to(_pinch_current)
	else:
		if event.index == _joy_index:
			_joy_index = -1
			_reset_joystick()
		elif event.index == _pinch_index:
			# Pinch finger lifts: look finger continues normally
			_pinch_index = -1
		elif event.index == _look_index:
			if _pinch_index != -1:
				# Promote the pinch finger to the look finger; re-anchor so
				# the camera does not jump.
				_look_index = _pinch_index
				_pinch_index = -1
				_look_last = _pinch_current
				_look_current = _pinch_current
			else:
				_look_index = -1

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
		_look_current = event.position
		if _pinch_index == -1:
			InputManager.set_touch_look_delta(event.position - _look_last)
		# Keep _look_last fresh so ending a pinch never jumps the camera
		_look_last = event.position
	elif event.index == _pinch_index:
		_pinch_current = event.position
		var dist := _look_current.distance_to(_pinch_current)
		InputManager.add_zoom_delta((_pinch_last_dist - dist) * PINCH_ZOOM_SCALE)
		_pinch_last_dist = dist

func _reset_joystick() -> void:
	joystick_knob.position = joystick_base.size * 0.5 - joystick_knob.size * 0.5
	InputManager.set_touch_move_vector(Vector2.ZERO)

extends Control
## Mobile touch controls: left virtual joystick (movement) + right look
## region + two-finger pinch zoom. Feeds InputManager; only visible on
## touch devices.

@onready var joystick_base: Control = $JoystickBase
@onready var joystick_knob: Control = $JoystickBase/Knob
@onready var look_region: Control = $LookRegion

const JOYSTICK_RADIUS := 110.0
const DEAD_ZONE := 0.12
const PINCH_ZOOM_SCALE := 0.004

var _joy_touch_index: int = -1
var _joy_center: Vector2 = Vector2.ZERO
var _joy_current: Vector2 = Vector2.ZERO
var _look_touch_index: int = -1
var _look_last: Vector2 = Vector2.ZERO
var _look_current: Vector2 = Vector2.ZERO
var _pinch_active: bool = false
var _pinch_last_dist: float = 0.0

func _ready() -> void:
	visible = false
	# Show only where touch is the primary input (web mobile / Android).
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
		if _joy_touch_index == -1 and event.position.x < half:
			# CoD-style: joystick spawns wherever the left half is touched
			_joy_touch_index = event.index
			_joy_center = event.position
			_joy_current = event.position
			joystick_base.position = _joy_center - joystick_base.size * 0.5
			joystick_base.modulate.a = 0.7
		elif _look_touch_index == -1 and event.position.x >= half:
			# Right half = camera look only
			_look_touch_index = event.index
			_look_last = event.position
			_look_current = event.position
	else:
		if event.index == _joy_touch_index:
			_joy_touch_index = -1
			_reset_joystick()
		elif event.index == _look_touch_index:
			_look_touch_index = -1
		_end_pinch_if_needed()

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == _joy_touch_index:
		_joy_current = event.position
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
		_look_current = event.position
		# Two active touches = pinch zoom (movement still works)
		if _joy_touch_index != -1 and not _pinch_active:
			_pinch_active = true
			_pinch_last_dist = _joy_current.distance_to(_look_current)
		if _pinch_active:
			var dist := _joy_current.distance_to(_look_current)
			InputManager.add_zoom_delta((_pinch_last_dist - dist) * PINCH_ZOOM_SCALE)
			_pinch_last_dist = dist
		else:
			var delta := event.position - _look_last
			InputManager.set_touch_look_delta(delta)
		_look_last = event.position

func _end_pinch_if_needed() -> void:
	if _pinch_active and (_joy_touch_index == -1 or _look_touch_index == -1):
		_pinch_active = false

func _reset_joystick() -> void:
	joystick_knob.position = joystick_base.size * 0.5 - joystick_knob.size * 0.5
	InputManager.set_touch_move_vector(Vector2.ZERO)

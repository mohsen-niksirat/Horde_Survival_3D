extends Node
## Input abstraction. Gameplay code calls ONLY this manager — never Input directly
## for gameplay actions. Supports keyboard+mouse, gamepad, and touch (virtual joystick).

var _move_vector: Vector2 = Vector2.ZERO
var _look_delta: Vector2 = Vector2.ZERO
var _touch_move_vector: Vector2 = Vector2.ZERO
var _touch_look_delta: Vector2 = Vector2.ZERO
var _zoom_delta: float = 0.0

var _using_touch: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

## Register a touch UI provider (virtual joystick + look region).
func register_touch_provider(_provider: Node) -> void:
	pass

func set_touch_move_vector(vec: Vector2) -> void:
	_touch_move_vector = vec
	_using_touch = true

func set_touch_look_delta(delta: Vector2) -> void:
	_touch_look_delta = delta
	_using_touch = true

func clear_touch() -> void:
	_touch_move_vector = Vector2.ZERO
	_touch_look_delta = Vector2.ZERO
	_using_touch = false

func get_move_vector() -> Vector2:
	var vec := Vector2.ZERO
	vec.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	vec.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	vec += _touch_move_vector
	if vec.length() > 1.0:
		vec = vec.normalized()
	return vec

func get_look_delta() -> Vector2:
	# Touch look only — desktop uses captured mouse directly in CameraRig.
	return _touch_look_delta

func consume_look_delta() -> Vector2:
	var d := get_look_delta()
	_touch_look_delta = Vector2.ZERO
	return d

## Pinch zoom from the touch controls (negative = zoom in).
func add_zoom_delta(delta: float) -> void:
	_zoom_delta += delta

func consume_zoom_delta() -> float:
	var d := _zoom_delta
	_zoom_delta = 0.0
	return d

func is_action_pressed(action: String) -> bool:
	match action:
		"ability_1", "ability_2", "dash":
			return Input.is_action_pressed(action) or _touch_action_pressed(action)
		_:
			return Input.is_action_pressed(action)

func is_action_just_pressed(action: String) -> bool:
	match action:
		"ability_1", "ability_2", "dash":
			return Input.is_action_just_pressed(action) or _touch_action_just_pressed(action)
		_:
			return Input.is_action_just_pressed(action)

func _touch_action_pressed(_action: String) -> bool:
	return false

func _touch_action_just_pressed(_action: String) -> bool:
	return false

## Called by the game scene to route pause input (Esc / touch button).
func is_pause_just_pressed() -> bool:
	return Input.is_action_just_pressed("pause")

func is_using_touch() -> bool:
	return _using_touch

extends Control
## TouchIndicator: draws floating control rings wherever the user touches.
## Left ring = movement (knob stretches toward drag), right ring = camera
## look. Both are thin translucent circles like modern mobile shooters.

const RING_RADIUS := 110.0
const KNOB_RADIUS := 42.0
const RING_COLOR := Color(1, 1, 1, 0.28)
const KNOB_COLOR := Color(1, 1, 1, 0.45)
const LOOK_KNOB_COLOR := Color(0.6, 0.85, 1.0, 0.4)

var _joy_center: Vector2 = Vector2(-1000, -1000)
var _joy_knob: Vector2 = Vector2.ZERO
var _joy_active: bool = false
var _look_center: Vector2 = Vector2(-1000, -1000)
var _look_knob: Vector2 = Vector2.ZERO
var _look_active: bool = false

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(false)

## Wired from TouchControls state each frame (or on events).
func update_rings(joy_active: bool, joy_center: Vector2, joy_knob: Vector2,
		look_active: bool, look_center: Vector2, look_knob: Vector2) -> void:
	_joy_active = joy_active
	_joy_center = joy_center
	_joy_knob = joy_knob
	_look_active = look_active
	_look_center = look_center
	_look_knob = look_knob
	visible = _joy_active or _look_active
	if visible:
		queue_redraw()

func _draw() -> void:
	if _joy_active:
		_draw_ring(_joy_center, _joy_knob, RING_COLOR, KNOB_COLOR)
	if _look_active:
		_draw_ring(_look_center, _look_knob, RING_COLOR, LOOK_KNOB_COLOR)

func _draw_ring(center: Vector2, knob: Vector2, ring_col: Color, knob_col: Color) -> void:
	var offset := knob - center
	var clamped := offset.limit_length(RING_RADIUS - KNOB_RADIUS)
	var knob_pos := center + clamped
	# Outer ring
	draw_arc(center, RING_RADIUS, 0, TAU, 48, ring_col, 3.0, true)
	# Fill hint
	draw_circle(center, RING_RADIUS, Color(1, 1, 1, 0.05))
	# Inner knob: stretches toward the drag direction (clamped inside ring)
	draw_circle(knob_pos, KNOB_RADIUS, knob_col)
	draw_circle(knob_pos, KNOB_RADIUS - 4.0, Color(knob_col.r, knob_col.g, knob_col.b, knob_col.a * 0.5))

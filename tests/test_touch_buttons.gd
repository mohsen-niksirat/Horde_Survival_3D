extends SceneTree
## Mobile touch validation (button-zoom design):
## - move+look simultaneously: independent, no interference
## - zoom via + / - buttons
## - no pinch path exists anymore

var failures := 0

func _initialize() -> void:
	var tc_ps: PackedScene = load("res://scenes/ui/TouchControls.tscn")
	var tc: Control = tc_ps.instantiate()
	root.add_child(tc)
	await process_frame
	tc.visible = true
	var im: Node = root.get_node("InputManager")

	# --- 1. Joy finger + look finger: independent controls ---
	tc._handle_touch(_touch(0, true, Vector2(150, 400)))
	tc._handle_drag(_drag(0, Vector2(190, 380)))
	var mv: Vector2 = im.get_move_vector()
	_check(mv.length() > 0.05, "joystick moves (len=%.2f)" % mv.length())
	tc._handle_touch(_touch(1, true, Vector2(900, 300)))
	tc._handle_drag(_drag(1, Vector2(945, 300)))
	var look: Vector2 = im.get_look_delta()
	_check(look.length() > 10.0, "look flows while moving (len=%.1f)" % look.length())
	im.consume_look_delta()
	_check(im.consume_zoom_delta() == 0.0, "no accidental zoom from move+look")

	# --- 2. Zoom buttons ---
	tc.zoom_out.pressed.emit()
	var z1: float = im.consume_zoom_delta()
	_check(z1 > 0.0, "zoom OUT button adds positive delta (%.3f)" % z1)
	tc.zoom_in.pressed.emit()
	var z2: float = im.consume_zoom_delta()
	_check(z2 < 0.0, "zoom IN button adds negative delta (%.3f)" % z2)

	# --- 3. Independent: look continues while joystick held ---
	tc._handle_drag(_drag(0, Vector2(210, 390)))
	_check(im.get_move_vector().length() > 0.05, "joystick still active")
	tc._handle_drag(_drag(1, Vector2(920, 320)))
	_check(im.get_look_delta().length() > 0.0, "look still active while moving")

	# --- 4. Releases clean state ---
	tc._handle_touch(_touch(0, false, Vector2(210, 390)))
	tc._handle_touch(_touch(1, false, Vector2(920, 320)))
	_check(im.get_move_vector().length() == 0.0, "movement stops on release")

	# --- 5. No pinch API remnants ---
	_check(not tc.has_method("_handle_pinch"), "no pinch handler")

	if failures == 0:
		print("TOUCH_BUTTONS_PASS")
	else:
		print("TOUCH_BUTTONS_FAIL failures=", failures)
	quit(0 if failures == 0 else 1)

func _touch(index: int, pressed: bool, pos: Vector2) -> InputEventScreenTouch:
	var ev := InputEventScreenTouch.new()
	ev.index = index
	ev.pressed = pressed
	ev.position = pos
	return ev

func _drag(index: int, pos: Vector2) -> InputEventScreenDrag:
	var ev := InputEventScreenDrag.new()
	ev.index = index
	ev.position = pos
	return ev

func _check(cond: bool, label: String) -> void:
	if cond:
		print("OK: ", label)
	else:
		push_error("FAIL: " + label)
		failures += 1

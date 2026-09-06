extends SceneTree
## Two-finger touch validation: move+look simultaneously must NOT trigger
## pinch (zoom jitter / look suppression); pinch only starts with a second
## right-half finger; promotion after look release re-anchors without jumps.

var failures := 0

func _initialize() -> void:
	var tc_ps: PackedScene = load("res://scenes/ui/TouchControls.tscn")
	var tc: Control = tc_ps.instantiate()
	root.add_child(tc)
	await process_frame
	tc.visible = true  # force on for the test (desktop default hides it)
	var im: Node = root.get_node("InputManager")

	# --- 1. Joy finger down + drag: movement works ---
	tc._handle_touch(_touch(0, true, Vector2(150, 400)))
	tc._handle_drag(_drag(0, Vector2(190, 380)))
	var mv: Vector2 = im.get_move_vector()
	_check(mv.length() > 0.05, "joystick moves (len=%.2f)" % mv.length())

	# --- 2. Look finger down + drag: camera look works, NO zoom jitter ---
	tc._handle_touch(_touch(1, true, Vector2(900, 300)))
	tc._handle_drag(_drag(1, Vector2(945, 300)))
	var look: Vector2 = im.get_look_delta()
	_check(look.length() > 10.0, "look delta flows while moving (len=%.1f)" % look.length())
	im.consume_look_delta()
	_check(im.consume_zoom_delta() == 0.0, "no pinch zoom from move+look combo")

	# --- 3. Second right-half finger: pinch starts, look suppressed ---
	tc._handle_touch(_touch(2, true, Vector2(840, 350)))
	tc._handle_drag(_drag(2, Vector2(800, 350)))  # fingers spread apart
	var zoom: float = im.consume_zoom_delta()
	_check(absf(zoom) > 0.0, "pinch zoom active with 2nd right finger (%.4f)" % zoom)
	tc._handle_drag(_drag(1, Vector2(960, 300)))
	_check(im.get_look_delta().length() == 0.0, "look suppressed during pinch")
	im.consume_look_delta()

	# --- 4. Look finger lifts: pinch finger promotes, no camera jump ---
	tc._handle_touch(_touch(1, false, Vector2(960, 300)))
	tc._handle_drag(_drag(2, Vector2(803, 352)))
	var promoted_look: Vector2 = im.get_look_delta()
	_check(promoted_look.length() < 20.0, "promotion re-anchors (no jump, len=%.1f)" % promoted_look.length())

	# --- 5. Joy finger lifts: movement stops ---
	tc._handle_touch(_touch(0, false, Vector2(180, 370)))
	_check(im.get_move_vector().length() == 0.0, "movement stops on release")

	if failures == 0:
		print("TOUCH_TWOFINGER_PASS")
	else:
		print("TOUCH_TWOFINGER_FAIL failures=", failures)
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

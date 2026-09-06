extends Node2D
## V7 animated menu background: slowly drifting glowing orbs over a subtle
## starfield. Cheap: 14 circles redrawn per frame.

const ORB_COUNT := 14
const STAR_COUNT := 40

var _orbs: Array = []
var _stars: Array = []
var _time: float = 0.0
var _size: Vector2 = Vector2(1280, 720)

func _ready() -> void:
	set_process(true)
	for i in range(ORB_COUNT):
		_orbs.append({
			"base": Vector2(randf() * _size.x, randf() * _size.y),
			"radius": randf_range(60.0, 160.0),
			"drift": randf_range(10.0, 30.0),
			"phase": randf() * TAU,
			"color": [Color(0.42, 0.71, 1.0), Color(1.0, 0.84, 0.0), Color(0.4, 0.9, 0.7)][i % 3],
		})
	for i in range(STAR_COUNT):
		_stars.append({
			"pos": Vector2(randf() * _size.x, randf() * _size.y),
			"r": randf_range(0.8, 2.2),
			"twinkle": randf() * TAU,
		})

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	for s in _stars:
		var a := 0.35 + 0.3 * sin(_time * 2.0 + s["twinkle"])
		draw_circle(s["pos"], s["r"], Color(1, 1, 1, a))
	for o in _orbs:
		var pos: Vector2 = o["base"] + Vector2(
			cos(_time * 0.4 + o["phase"]) * o["drift"] * 2.0,
			sin(_time * 0.3 + o["phase"]) * o["drift"]
		)
		draw_circle(pos, o["radius"], Color(o["color"].r, o["color"].g, o["color"].b, 0.05))
		draw_circle(pos, o["radius"] * 0.5, Color(o["color"].r, o["color"].g, o["color"].b, 0.06))

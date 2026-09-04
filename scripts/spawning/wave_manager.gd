extends Node
## Placeholder wave manager (Phase 5 implements the real threat-budget system).
## Exists so Main.gd wiring is validated early.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	print("WaveManager placeholder ready — full system arrives in Phase 5")

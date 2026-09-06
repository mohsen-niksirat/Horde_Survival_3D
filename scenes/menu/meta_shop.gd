extends Control
## V9 meta shop: 6 permanent stat upgrades bought with meta gold.
## Levels persist via SaveManager; applied at every run start.

const STATS := [
	{"id": "meta_hp", "name": "Vitality", "stat": "max_hp", "pct": 0.05},
	{"id": "meta_might", "name": "Might", "stat": "might", "pct": 0.04},
	{"id": "meta_cooldown", "name": "Frenzy", "stat": "cooldown_mult", "pct": -0.03},
	{"id": "meta_speed", "name": "Swiftness", "stat": "move_speed", "pct": 0.03},
	{"id": "meta_luck", "name": "Luck", "stat": "luck", "pct": 0.04},
	{"id": "meta_gold", "name": "Greed", "stat": "gold_gain", "pct": 0.05},
]
const MAX_LEVEL := 20

@onready var gold_label: Label = $Center/Panel/Layout/Gold
@onready var rows: VBoxContainer = $Center/Panel/Layout/Rows
@onready var close_button: Button = $Center/Panel/Layout/Close

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_button.pressed.connect(func(): visible = false)
	_build_rows()
	EventBus.game_state_changed.connect(func(_n, _o): _refresh())

func open() -> void:
	visible = true
	_refresh()

func _level(id: String) -> int:
	return int(SaveManager.get_meta_data("meta_upgrades", {}).get(id, 0))

func _cost(level: int) -> int:
	return 50 + level * 75

func _build_rows() -> void:
	for s in STATS:
		var row := HBoxContainer.new()
		row.name = s["id"]
		var name_l := Label.new()
		name_l.text = s["name"]
		name_l.custom_minimum_size = Vector2(110, 0)
		row.add_child(name_l)
		var lvl := Label.new()
		lvl.name = "Level"
		lvl.custom_minimum_size = Vector2(60, 0)
		row.add_child(lvl)
		var buy := Button.new()
		buy.name = "Buy"
		buy.custom_minimum_size = Vector2(130, 34)
		buy.pressed.connect(_on_buy.bind(s))
		row.add_child(buy)
		rows.add_child(row)

func _refresh() -> void:
	gold_label.text = "Gold: %d" % SaveManager.get_meta_data("gold", 0)
	for s in STATS:
		var row: HBoxContainer = rows.get_node(s["id"])
		var lvl: int = _level(s["id"])
		row.get_node("Level").text = "Lv %d/20" % lvl
		var buy: Button = row.get_node("Buy")
		if lvl >= MAX_LEVEL:
			buy.text = "MAX"
			buy.disabled = true
		else:
			buy.text = "+1 (%dg)" % _cost(lvl)
			buy.disabled = SaveManager.get_meta_data("gold", 0) < _cost(lvl)

func _on_buy(s: Dictionary) -> void:
	var lvl := _level(s["id"])
	var cost := _cost(lvl)
	var gold: int = SaveManager.get_meta_data("gold", 0)
	if lvl >= MAX_LEVEL or gold < cost:
		return
	SaveManager.set_meta_data("gold", gold - cost)
	var ups: Dictionary = SaveManager.get_meta_data("meta_upgrades", {}).duplicate()
	ups[s["id"]] = lvl + 1
	SaveManager.set_meta_data("meta_upgrades", ups)
	AudioManager.play_game_sfx("relic_pickup")
	_refresh()

## Apply all purchased levels as modifiers (called at run start).
func apply_to(stats: StatBlock) -> void:
	for s in STATS:
		var lvl := _level(s["id"])
		if lvl > 0:
			stats.add_modifier(s["stat"], 0.0, s["pct"] * lvl)

## Static helper usable without instantiating the UI.
static func apply_meta_upgrades(stats: StatBlock) -> void:
	for s in STATS:
		var lvl := int(SaveManager.get_meta_data("meta_upgrades", {}).get(s["id"], 0))
		if lvl > 0:
			stats.add_modifier(s["stat"], 0.0, s["pct"] * lvl)

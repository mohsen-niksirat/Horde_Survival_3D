extends Control
## HUD: HP bar, XP bar, level, timer, kills, combo counter, ability buttons.

@onready var hp_bar: ProgressBar = $TopLeft/HPBar
@onready var hp_label: Label = $TopLeft/HPLabel
@onready var xp_bar: ProgressBar = $Top/XPBar
@onready var level_label: Label = $TopLeft/LevelLabel
@onready var timer_label: Label = $Top/TimerLabel
@onready var kills_label: Label = $TopRight/KillsLabel
@onready var combo_label: Label = $Combo
@onready var ability1_button: Button = $Abilities/Ability1
@onready var ability2_button: Button = $Abilities/Ability2

var _player: Node
var _ability_controller: Node

const TIER_COLORS := {
	"BRONZE": Color(0.8, 0.65, 0.4),
	"SILVER": Color(0.85, 0.87, 0.9),
	"GOLD": Color(1, 0.85, 0.2),
	"PLATINUM": Color(0.3, 0.9, 1),
	"DIAMOND": Color(0.85, 0.5, 1),
	"GODLIKE": Color(1, 0.25, 0.3),
}

func bind_player(player: Node) -> void:
	_player = player
	EventBus.player_leveled_up.connect(_on_level_up)
	RunManager.kills_changed.connect(_on_kills)
	EventBus.combo_changed.connect(_on_combo)
	ability1_button.pressed.connect(func(): pass)

func bind_abilities(controller: Node) -> void:
	_ability_controller = controller
	ability1_button.text = "Q Meteor"
	ability2_button.text = "E Freeze"

func _process(_delta: float) -> void:
	timer_label.text = RunManager.get_time_string()
	if _player == null:
		return
	hp_bar.max_value = _player.health.max_hp
	hp_bar.value = _player.health.current_hp
	hp_label.text = "%d / %d" % [int(_player.health.current_hp), int(_player.health.max_hp)]
	xp_bar.value = _player.experience.current_xp
	xp_bar.max_value = _player.experience.xp_to_next
	level_label.text = "Lv %d" % _player.experience.level

	# Ability cooldown indicators
	if _ability_controller != null:
		for ab in _ability_controller.abilities:
			var data = ab["data"]
			var ratio: float = _ability_controller.get_cooldown_ratio(data.id)
			var btn := ability1_button if data.id == "meteor_strike" else ability2_button
			btn.modulate = Color(1, 1, 1, 0.4 if ratio > 0.0 else 1.0)

func _on_level_up(_level: int) -> void:
	pass

func _on_kills(kills: int) -> void:
	kills_label.text = "Kills: %d" % kills

func _on_combo(count: int, multiplier: float) -> void:
	if count <= 0:
		combo_label.visible = false
		return
	combo_label.visible = true
	var tier: String = _combo_tier(count)
	combo_label.text = "x%d COMBO %s\n(%.1f XP)" % [count, tier, multiplier]
	combo_label.add_theme_color_override("font_color", TIER_COLORS.get(tier, Color.WHITE))
	var size := 20 + mini(count / 10, 6) * 3
	combo_label.add_theme_font_size_override("font_size", size)

func _combo_tier(count: int) -> String:
	if count >= 200: return "GODLIKE"
	if count >= 100: return "DIAMOND"
	if count >= 50: return "PLATINUM"
	if count >= 25: return "GOLD"
	if count >= 10: return "SILVER"
	return "BRONZE"

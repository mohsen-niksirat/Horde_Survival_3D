extends Control
## HUD: HP bar, XP bar, level, timer, kills.

@onready var hp_bar: ProgressBar = $TopLeft/HPBar
@onready var hp_label: Label = $TopLeft/HPLabel
@onready var xp_bar: ProgressBar = $Top/XPBar
@onready var level_label: Label = $TopLeft/LevelLabel
@onready var timer_label: Label = $Top/TimerLabel
@onready var kills_label: Label = $TopRight/KillsLabel

var _player: Node

func bind_player(player: Node) -> void:
	_player = player
	EventBus.player_leveled_up.connect(_on_level_up)
	EventBus.xp_collected.connect(_on_xp)
	RunManager.kills_changed.connect(_on_kills)

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

func _on_level_up(_level: int) -> void:
	pass

func _on_xp(_amount: float) -> void:
	pass

func _on_kills(kills: int) -> void:
	kills_label.text = "Kills: %d" % kills

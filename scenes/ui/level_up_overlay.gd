extends Control
## Level-up overlay: shows 3 upgrade cards, applies the chosen one, resumes.

@onready var cards_container: HBoxContainer = $Center/Layout/Cards

var _choices: Array = []

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.game_state_changed.connect(_on_state_changed)

func bind_progression(progression: Node) -> void:
	progression.choices_generated.connect(_on_choices_generated)

func _on_state_changed(new_state: int, _old: int) -> void:
	visible = new_state == GameManager.State.LEVEL_UP

func _on_choices_generated(choices: Array) -> void:
	_choices = choices
	_rebuild_cards()

func _rebuild_cards() -> void:
	for child in cards_container.get_children():
		child.queue_free()
	for i in range(_choices.size()):
		var option: UpgradeOption = _choices[i]
		var card := Button.new()
		card.custom_minimum_size = Vector2(220, 260)
		card.text = "%s\nLv %d → %d\n\n%s" % [
			option.title,
			option.current_level,
			option.next_level,
			option.description,
		]
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var color := option.rarity_color()
		card.add_theme_color_override("font_color", color)
		card.pressed.connect(_on_card_pressed.bind(i))
		cards_container.add_child(card)

func _on_card_pressed(index: int) -> void:
	if index < 0 or index >= _choices.size():
		return
	var main: Node = get_tree().root.get_node_or_null("Main")
	var progression: Node = main.progression if main != null else null
	if progression != null:
		progression.apply_and_continue(_choices[index])
	else:
		GameManager.close_level_up()

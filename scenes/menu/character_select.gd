extends Control
## Character select: 3 cards, pick applies id + starts the run.

const CHARS := ["mage", "paladin", "rogue"]

@onready var cards: HBoxContainer = $Center/Layout/Cards
@onready var close_button: Button = $Center/Layout/Close

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_button.pressed.connect(func(): visible = false)
	for id in CHARS:
		var path := "res://data/characters/%s.tres" % id
		if not ResourceLoader.exists(path):
			continue
		var data: CharacterData = load(path)
		var card := Button.new()
		card.custom_minimum_size = Vector2(220, 220)
		card.text = "%s\n\n%s" % [data.display_name, data.description]
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_theme_color_override("font_color", data.color)
		card.add_theme_font_size_override("font_size", 15)
		card.pressed.connect(_on_pick.bind(data))
		cards.add_child(card)

func open() -> void:
	visible = true

func _on_pick(data: CharacterData) -> void:
	GameManager.selected_character_id = data.id
	GameManager.start_game()

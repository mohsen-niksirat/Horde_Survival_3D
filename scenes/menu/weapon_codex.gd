extends Control
## P4: weapon codex — catalog of weapons + evolutions (read-only info).

const WEAPONS := ["fireball", "magic_missile", "orbiting_shield", "divine_spear", "lightning"]
const EVOLUTIONS := [
	{"base": "Fireball", "passive": "Spinach (max)", "result": "Hellfire", "req": "T5"},
	{"base": "Magic Missile", "passive": "Empty Tome (max)", "result": "Holy Bible", "req": "T5"},
	{"base": "Orbiting Shield", "passive": "Heart (max)", "result": "Aurora", "req": "T5"},
	{"base": "Divine Spear", "passive": "Crown (max)", "result": "Judgment", "req": "T5"},
	{"base": "Lightning", "passive": "Wings (max)", "result": "Thunderstorm", "req": "T5"},
]

@onready var rows: VBoxContainer = $Center/Panel/Layout/Scroll/Rows
@onready var close_button: Button = $Center/Panel/Layout/Close

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_button.pressed.connect(func(): visible = false)
	_build()

func open() -> void:
	visible = true

func _build() -> void:
	var wc_colors: Dictionary = {}
	var wc_script: GDScript = load("res://scripts/weapons/weapon_controller.gd")
	for w in WEAPONS:
		var data: WeaponData = load("res://data/weapons/%s.tres" % w)
		var label := Label.new()
		label.text = "%s  —  dmg %d / cd %.1fs" % [data.display_name, data.base_damage, data.base_cooldown]
		label.add_theme_font_size_override("font_size", 17)
		label.add_theme_color_override("font_color", wc_script.WEAPON_FLASH_COLORS.get(w, Color.WHITE))
		rows.add_child(label)
	var evo_title := Label.new()
	evo_title.text = "EVOLUTIONS  (weapon T5 + maxed passive)"
	evo_title.add_theme_font_size_override("font_size", 19)
	evo_title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	rows.add_child(evo_title)
	for e in EVOLUTIONS:
		var l := Label.new()
		l.text = "%s + %s  ->  %s" % [e["base"], e["passive"], e["result"]]
		l.add_theme_font_size_override("font_size", 16)
		l.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
		rows.add_child(l)

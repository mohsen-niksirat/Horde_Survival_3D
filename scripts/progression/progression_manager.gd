extends Node
## ProgressionManager: generates level-up choices and applies them to the
## player's StatBlock/weapons. Per-run node owned by Main.

const PASSIVE_IDS := [
	"spinach", "empty_tome", "crown", "wings",
	"magnet", "heart", "growth", "vampire",
]
const MAX_WEAPON_SLOTS := 4
const CHOICES := 3

signal choices_generated(choices: Array)

var player: CharacterBody3D
var passive_levels: Dictionary = {}   # passive_id -> level
var passive_data: Dictionary = {}     # passive_id -> PassiveData
var pending_levels: int = 0

func setup(p_player: CharacterBody3D) -> void:
	player = p_player
	for id in PASSIVE_IDS:
		var path := "res://data/passives/%s.tres" % id
		if ResourceLoader.exists(path):
			passive_data[id] = load(path)

## Called when the player levels up. Queues the level and shows choices;
## stacked multi-level ups wait until the current pick is made.
func offer_choices() -> void:
	pending_levels += 1
	match GameManager.state:
		GameManager.State.PLAYING, GameManager.State.BOSS:
			_open_and_offer()
		GameManager.State.LEVEL_UP:
			pass  # player is mid-pick; apply_and_continue chains the rest
		_:
			pending_levels = maxi(pending_levels - 1, 0)

func _open_and_offer() -> void:
	GameManager.open_level_up()
	pending_levels -= 1
	choices_generated.emit(generate_choices())

## Called by the UI after the player picks one card.
func apply_and_continue(option: UpgradeOption) -> void:
	apply_choice(option)
	if pending_levels > 0:
		_open_and_offer()
	else:
		GameManager.close_level_up()

func generate_choices() -> Array:
	var pool: Array = []
	_fill_pool(pool)
	# Deduplicate by title, keep 3 (fallback heal always last resort)
	var picked: Array = []
	var used_titles := {}
	pool.shuffle()
	for option in pool:
		if picked.size() >= CHOICES:
			break
		if used_titles.has(option.title):
			continue
		used_titles[option.title] = true
		picked.append(option)
	if picked.is_empty():
		picked.append(_make_heal_option())
	return picked

func _fill_pool(pool: Array) -> void:
	var weapon_controller: Node = player.weapon_controller
	var weapons: Array = weapon_controller.weapons

	# Weapon tier-ups
	for w in weapons:
		if w.level < 5:
			var opt := UpgradeOption.new()
			opt.kind = UpgradeOption.Kind.WEAPON_TIER
			opt.rarity = "rare" if w.level >= 3 else "common"
			opt.title = w.data.display_name
			opt.description = "Upgrade to level %d" % (w.level + 1)
			opt.target = w.data
			opt.current_level = w.level
			opt.next_level = w.level + 1
			pool.append(opt)

	# New weapons (MVP: fireball only exists; offer passives more often)
	# Passives
	for id in passive_data:
		var data: PassiveData = passive_data[id]
		var lvl: int = passive_levels.get(id, 0)
		if lvl >= data.max_level:
			continue
		var opt := UpgradeOption.new()
		opt.kind = UpgradeOption.Kind.PASSIVE
		opt.rarity = "common"
		if lvl + 1 >= data.max_level:
			opt.rarity = "rare"
		opt.title = data.display_name
		opt.description = "%s (Lv %d → %d)" % [data.description, lvl, lvl + 1]
		opt.target = data
		opt.current_level = lvl
		opt.next_level = lvl + 1
		pool.append(opt)

	# Heal fallback
	if pool.size() < CHOICES or player.health.get_ratio() < 0.5:
		pool.append(_make_heal_option())

func _make_heal_option() -> UpgradeOption:
	var opt := UpgradeOption.new()
	opt.kind = UpgradeOption.Kind.HEAL
	opt.rarity = "common"
	opt.title = "Heal"
	opt.description = "Restore 30% of max HP"
	return opt

## Apply the chosen option.
func apply_choice(option: UpgradeOption) -> void:
	match option.kind:
		UpgradeOption.Kind.WEAPON_TIER:
			for w in player.weapon_controller.weapons:
				if w.data == option.target:
					w.level_up()
					break
		UpgradeOption.Kind.PASSIVE:
			var id: String = option.target.id
			passive_levels[id] = passive_levels.get(id, 0) + 1
			option.target.apply_per_level(player.stat_block, 1)
			player.on_stats_changed()
		UpgradeOption.Kind.HEAL:
			player.health.heal(player.health.max_hp * 0.3)
	EventBus.upgrade_applied.emit(option.title)

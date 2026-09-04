extends RefCounted
class_name DifficultyManager
## Difficulty scaling: reuses the reference game's proven formula shape with
## 3D-retuned constants. Per-stat caps prevent late-game absurdity.

static func difficulty_multiplier(player_level: int, minutes: float) -> float:
	return 1.0 + 0.18 * sqrt(float(maxi(player_level, 1))) + minutes * 0.06

static func hp_scale(difficulty: float) -> float:
	return minf(difficulty, 10.0)

static func damage_scale(difficulty: float) -> float:
	return minf(difficulty, 5.0)

static func speed_scale(difficulty: float) -> float:
	return minf(1.0 + (difficulty - 1.0) * 0.25, 1.8)

## Threat budget grows with time: more points = more/stronger enemies.
static func threat_budget(minutes: float) -> float:
	return 2.0 + minutes * 2.2 + minutes * minutes * 0.08

## Spawn interval shrinks over time.
static func spawn_interval(minutes: float) -> float:
	return maxf(2.0 / (1.0 + minutes * 0.06), 0.35)

## Which archetypes are allowed at this time (minutes).
static func allowed_archetypes(minutes: float) -> Array:
	var out := ["basic_drone"]
	if minutes >= 1.5:
		out.append("swarm_bat")
	if minutes >= 2.5:
		out.append("fast_wisp")
	if minutes >= 4.0:
		out.append("shooter_turret")
	if minutes >= 5.0:
		out.append("tank_golem")
	return out

## Elite cadence: every 10 player levels (matches reference game).
static func should_spawn_elite(player_level: int, last_elite_level: int) -> bool:
	return player_level / 10 > last_elite_level / 10

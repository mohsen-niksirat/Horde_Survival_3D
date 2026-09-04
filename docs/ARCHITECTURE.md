# ARCHITECTURE — HordeSurvival 3D

> Godot 4.x · GDScript · Compatibility renderer · Web-first (GitHub Pages static deployment)
> Principles: data-driven, pooled, component-based, no monoliths, zero per-frame allocations in hot paths.

---

## 1. Project Layout

```
Horde_Survival_3D/
├── project.godot
├── scenes/
│   ├── bootstrap/        # boot, loading screen, preloads
│   ├── main/             # Main (root orchestrator)
│   ├── menu/             # main menu, character select, settings, results
│   ├── world/            # arena, environment
│   ├── player/           # player scene
│   ├── enemies/          # enemy scene(s), boss scene
│   ├── weapons/          # weapon scenes + projectile scenes
│   ├── pickups/          # xp orb, gold, health, relic pickup
│   ├── vfx/              # reusable one-shot VFX scenes
│   └── ui/               # HUD, level-up, pause, damage numbers, joystick
├── scripts/
│   ├── core/             # GameManager, state machine, events, constants
│   ├── player/           # player components
│   ├── combat/           # DamageSystem, StatusEffects, TargetingSystem
│   ├── enemies/          # enemy components + AI
│   ├── spawning/         # WaveManager, SpawnManager, DifficultyManager
│   ├── weapons/          # weapon framework + per-weapon logic
│   ├── abilities/        # ability framework
│   ├── items/            # relics, pets framework
│   ├── progression/      # XP, upgrades, combo, achievements
│   ├── modes/            # game mode definitions
│   ├── save/             # SaveManager
│   ├── input/            # InputManager abstraction
│   ├── audio/            # AudioManager
│   ├── performance/      # PerformanceManager, budgets, debug overlay
│   └── utilities/        # pooling, math, helpers
├── data/                 # .tres resources
│   ├── weapons/  enemies/  upgrades/  relics/  pets/  abilities/  characters/
├── assets/               # glb models, textures, audio, fonts
│   ├── characters/  enemies/  environment/  vfx/  ui/  audio/
├── web/                  # export shell: loading page, PWA manifest, fallback
├── docs/
└── .github/workflows/deploy-web.yml
```

## 2. Runtime Architecture

### 2.1 Scene tree (run time)

```
Main (Node)                      # orchestrates state machine, owns managers
├── World (Node3D)
│   ├── Arena (environment, lights, boundaries, props)
│   ├── Entities (Node3D)       # pooled containers
│   │   ├── Enemies (Node3D)
│   │   ├── Projectiles (Node3D)
│   │   ├── Pickups (Node3D)
│   │   └── VFX (Node3D)
│   └── Player (CharacterBody3D)
│       ├── CollisionShape3D
│       ├── MovementComponent
│       ├── StatsComponent (+ Health, Experience)
│       ├── WeaponController
│       ├── AbilityController
│       ├── TargetingComponent
│       └── CameraRig (Node3D → SpringArm3D → Camera3D)
├── HUD (CanvasLayer)
└── Overlays (CanvasLayer)      # level-up, pause, game over, debug
```

### 2.2 Managers (autoload singletons — one responsibility each)

| Autoload | Responsibility |
|---|---|
| `GameManager` | Global game-state machine (BOOT, MAIN_MENU, CHARACTER_SELECT, GAME_START, PLAYING, LEVEL_UP, BOSS, PAUSED, GAME_OVER, RESULTS), scene transitions, signals |
| `EventBus` | Typed signal hub decoupling systems (enemy_died, damage_dealt, xp_collected, level_up, boss_spawned…) |
| `PoolManager` | Pools: enemies, projectiles, xp orbs, pickups, VFX, damage numbers. `acquire()/release()`, prewarm, per-pool caps |
| `SaveManager` | versioned save/load/delete/has; meta state; platform-agnostic (user:// works on web via IndexedDB) |
| `AudioManager` | music/SFX buses, volume settings, one-shot SFX pool |
| `InputManager` | abstract actions (move_vector, look_vector, ability_1, ability_2, dash, pause) from keyboard+mouse / touch / gamepad; device detection |
| `PerformanceManager` | entity budgets, quality tiers (shadows, VFX, render scale), dynamic degradation, debug overlay |
| `RunManager` | per-run session state: timer, kills, gold earned, run stats, game speed |
| `ProgressionManager` | XP curve, level-ups, upgrade generation & application (uses ModifierSystem) |
| `LootManager` | drop tables: xp orbs, gold, health, relic spawns |
| `CombatManager` | damage pipeline + status effect registry |

**Not autoloads** (per-run instanced, owned by Main/World): `WaveManager`, `SpawnManager`, `DifficultyManager`, `ComboManager`, `TargetingSystem`, `ModifierSystem`.

### 2.3 Component pattern (Godot-idiomatic)

Components are plain `Node`s (or just scripts on the owner node) — no ECS framework; Godot's scene tree is the composition root.

- `StatsComponent` — holds `StatBlock` (base dict) + list of active `Modifier`s; exposes `get_stat(name)`; recalculates on change; **timed modifiers stored as (value, duration), reapplied from base each frame**.
- `HealthComponent` — current/max, armor, invincibility window, `take_damage(DamageEvent)` / `heal()`, signals `died`, `damaged`.
- `ExperienceComponent` — xp, level, curve, signals `leveled_up`.
- `MovementComponent` — steering toward a direction vector, acceleration/deceleration, speed multiplier support, arena-bounds clamp.
- `TargetingComponent` — queries `TargetingSystem` (nearest / lowest_hp / random / boss_priority / area) with cached shortlists; refreshed on a timer (0.2s), not every frame.
- `WeaponController` — owns equipped `WeaponInstance`s; ticks cooldowns; fires via weapon behavior scripts.
- `StatusComponent` — list of active status effects (burn/slow/freeze/knockback), tick + expiry, data-driven `StatusEffectData`.
- `LootComponent` (enemies) — delegates death drops to `LootManager`.

### 2.4 Data-driven resources (`data/`)

| Resource | Key fields |
|---|---|
| `WeaponData` | id, name, type(PROJECTILE/ORBIT/AOE/PIERCING), base_damage, base_cooldown, projectile_count, speed, area, pierce, crit_chance, status, targeting, tier_effects[5], evolution (WeaponEvolutionData), vfx/sfx, icon |
| `EnemyData` | id, archetype, hp, speed, damage, xp, gold, radius, attack_range, attack_cooldown, movement_type, spawn_weight, threat_cost, elite_abilities, scene |
| `UpgradeData` | id, kind(WEAPON_NEW/WEAPON_TIER/PASSIVE/RELIKE/HEAL), target_id, effect(ModifierSpec), rarity, max_stacks, description |
| `RelicData` | id, name, rarity, modifiers[], special |
| `AbilityData` | id, cooldown, duration, damage, area, status, vfx |
| `PetData` | id, follow_offset, attack data, scaling |
| `CharacterData` | id, name, stats, starting_weapon, perk modifiers, unlock_cost |
| `WaveProfile` / `DifficultyCurve` | timeline of allowed archetypes, threat budget growth, elite/boss cadence |

Content = new `.tres` files, not code changes.

### 2.5 Combat pipeline (single path)

`DamageSystem.deal_damage(source_id, target, DamageRequest)` → crit roll → armor → apply → spawn damage number (pooled) → status application → death check → `EventBus.enemy_died` → LootManager + ComboManager + Achievements.
Weapons never compute damage locally; they emit `DamageRequest`s.

### 2.6 Spawning & culling

- `WaveManager` ticks timeline → budget; `SpawnManager` picks spawn points on a ring (35–45 m, camera-aware: prefer behind player / outside frustum), instantiates via PoolManager.
- Cull: enemies > 75 m from player recycled; pickups > 60 m recycled; per-pool hard caps with oldest-first recycling (type whitelists only — never weapons/player).
- `PerformanceManager` scales caps by quality tier (Low 100 enemies / Med 160 / High 240).

### 2.7 Performance rules (enforced by review)

1. No `get_tree().get_nodes_in_group()` / O(n) global search per entity per frame. Targeting uses a **spatial hash grid** (uniform cell 8 m, rebuilt incrementally or queried by cell).
2. Zero allocations in `_process`/`_physics_process` hot paths (reuse arrays, no string building; damage numbers use cached format).
3. Squared-distance checks; timers via accumulators, not `get_node` lookups.
4. Physics: enemies move with `CharacterBody3D`? — **No.** Enemies use lightweight `Node3D` + manual movement + sphere-overlap queries from the spatial grid; only the Player and Boss are physics bodies. Projectile hits = grid queries, not physics.
5. Rendering: Compatibility renderer; shared materials; `MultiMesh` candidates (XP orbs) noted for Phase 11; shadows off for hordes; VFX budget from PerformanceManager.
6. Web: no threads (`OS.low_processor_usage_mode` acceptable), asset preloads minimized in bootstrap, `web/` shell handles loading progress + Click-to-Play (audio unlock) + WebGL fallback.

### 2.8 Input abstraction

`InputManager.get_move_vector() -> Vector2`, `get_look_delta() -> Vector2`, `is_action_pressed(action)` — implementations: `KeyboardMouseInput`, `TouchInput` (virtual joystick scene + right-half look region + buttons), `GamepadInput`. Gameplay code only ever calls the abstraction.

### 2.9 Save model

- `MetaSave` (versioned JSON): settings, gold, meta upgrade levels, characters unlocked, achievements, bests, statistics. `SAVE_VERSION = 1` + migration switch.
- Run state is **not** persisted as source of truth (resume-after-death is not an MVP feature).
- Web: `user://` maps to IndexedDB — works unattended.

### 2.10 State machine

`GameManager` states: BOOT → MAIN_MENU → CHARACTER_SELECT → GAME_START → PLAYING ⇄ LEVEL_UP / PAUSED → BOSS (sub-state during PLAYING) → GAME_OVER → RESULTS → MAIN_MENU.
LEVEL_UP/PAUSED implemented via `get_tree().paused` + `process_mode` whitelists (UI + GameManager), so horde logic halts cleanly.

### 2.11 Web deployment

- Godot 4 export preset `Web` (Compatibility, `export-web` pipeline).
- `.github/workflows/deploy-web.yml`: checkout → godot-build-tools/godot export web → upload artifact → deploy `web/` + build to GitHub Pages (`gh-pages` or actions-deploy-pages).
- `web/`: `index.html` loading shell with progress bar, "Click to Play" (user gesture → fullscreen + audio unlock), WebGL-unsupported fallback, PWA manifest + service worker (cache shell only; gameplay assets cached by browser).

### 2.12 Testing strategy

- Headless test scenes (`tests/`): movement integration, spawn wave fill/drain, pool acquire/release balance, damage pipeline math, xp/level thresholds, save round-trip. Run via `godot --headless --script`.
- Manual test checklist per phase in ROADMAP.

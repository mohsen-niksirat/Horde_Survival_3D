# EXISTING GAME ANALYSIS — HordeSurvival (Android Reference)

> Reference: https://github.com/mohsen-niksirat/HordeSurvival
> Analyzed version: v1.2.9 (versionCode 11), Aug 2026
> Tech: Kotlin + Jetpack Compose Canvas rendering, custom ECS, Room DB + DataStore, ToneGenerator/SoundPool audio.
> ~46 Kotlin files, ~5,500+ LOC.

---

## 1. What the Existing Game Is

A Vampire-Survivors-style survival roguelite for Android:

- Player moves with a virtual joystick on an **infinite 2D plane** (no world bounds).
- Weapons **fire automatically** on cooldown; the player never aims.
- Enemies chase in a growing horde; killing them drops **XP gems** (magnetized in pickup range), gold, and rare health drops.
- XP → level up → pause → **3 upgrade choices** (new weapon / weapon tier-up / passive item / heal fallback).
- Weapons have **5 tiers** and can **evolve** at tier 5 + a maxed specific passive (8 evolution recipes).
- **Elites** every 10 levels (golden, ×3 HP, 8 modular elite abilities), **mini-boss** every 5 minutes, **boss** every 50 player levels (4 phases, minion spawns per phase).
- Meta-progression: gold, 6 permanent stat upgrades, 10 blessings, 5 prestige tiers, 10 unlockable characters, skins, pets, achievements (24), daily login streak, offline progress.
- Modes: Survival, Daily Challenge (10 rotating seeded variants), Tower Defense (actually a 1942-style vertical shooter), Quest Mode, Boss Rush Extreme.
- Extras: in-run shop, combo system (6 visual tiers), map/stage hazards, weapon synergies, 6 languages, dynamic music intensity states.

## 2. Full System Inventory (source-verified)

### Weapons (8, tiers 1–5 + evolution)
| Weapon | DMG | CD | Behavior |
|---|---|---|---|
| Magic Missile | 8 | 0.8s | Homing projectiles, range 500, speed 400 |
| Lightning Ring | 12 | 1.5s | Instant AOE strike in radius, 0.3s per-enemy hit CD |
| Fireball | 20 | 2.0s | Projectile + AOE burst, burn DoT |
| Ice Shard | 10 | 1.0s | Piercing shot, slow 0.5×/2s |
| Poison Cloud | 5 | 3.0s | Stationary damage cloud, 0.5s ticks |
| Boomerang Dagger | 15 | 1.2s | Fly out 200, return to player, pierce |
| Orbiting Shield | 8 | — | Persistent orbiting shields, contact damage |
| Divine Spear | 35 | 2.5s | Fast long shot, crit ×2.5, pierce-all at T4 |

Tier effects are per-weapon (extra projectiles, radius, burn, freeze, chain, meteor shower, etc.).

### Evolutions (8)
Holy Bible (Missile+Tome), Hellfire (Fireball+Spinach), Blizzard (Ice+Crown), Thunderstorm (Lightning+Clover), Plague (Poison+Vampire), Megaboom (Boomerang+Wings), Aurora (Shield+Shield), Judgment (Spear+Heart). All: dmg ×2–3, CD ×0.7, +2 projectiles, one special effect.

### Enemies (11 types)
| Type | HP | DMG | Speed | XP | Special |
|---|---|---|---|---|---|
| Basic Drone | 15 | 8 | 60 | 1 | straight chase |
| Flying Wisp | 8 | 5 | 120 | 2 | fast chase |
| Tank Golem | 80 | 20 | 30 | 5 | slow tank |
| Shooter Turret | 25 | 12 | 0 | 3 | stationary ranged, 2s volley |
| Swarm Bat | 5 | 3 | 150 | 0.5 | erratic sine wobble |
| Elite Knight | 50 | 15 | 70 | 4 | armor 5 |
| Ghost | 20 | 10 | 80 | 3 | sine-wave path |
| Splitter | 30 | 8 | 50 | 2 | splits into 2 bats on death |
| Healer | 20 | 5 | 55 | 3 | heals allies in 100px every 3s |
| Mage | 18 | 15 | 40 | 4 | kites (flee <150, approach >300), shoots every 2.5s |
| Boss | 500 | 25 | 40 | 50 | 4 phases, minion spawns |

### Elite abilities (8, applied to random elite every 10 levels)
Teleport (3s CD, 80–140px), Shielded (30% maxHp at 50%), Explode on Death (r=100, 30 dmg), Healer Aura (5 HP/2s r=120), Speed Boost (×2 speed <30% HP), Split on Death (3 minis), Vampiric (heal on hit), Thorns (reflect 30%).

### Passives (12, max levels 3–5)
Spinach (+10% might), Empty Tome (−8% CD), Crown (+8% area), Wings (+10% speed), Duplicator (+1 projectile), Shield (+10% armor), Heart (+20 max HP), Clover (+5% luck), Magnet (+20% pickup), Growth (+10% XP), Speedster (+5% attack speed), Vampire (+0.5 HP/s regen).

### Characters (10, 500g each; 3 free)
Mage, Paladin, Rogue (free); Alchemist, Archmage, Pyromancer, Frost Mage, Storm Caller, Assassin, Necromancer. Each has a starting weapon, HP/speed/might statline and a perk.

### Active abilities (8, one per character, HUD button, 15–35s CD)
Time Freeze, Meteor Strike, Shadow Clone, Healing Aura, Lightning Storm, Berserker Rage, Frost Nova, Soul Harvest.

### Relics (12, rarity-weighted map pickups every 45s, last 2 min)
Crown/Wings/Armor/Clover/Ring/Amulet (Common/Uncommon), Chalice/Gauntlet/Oracle (Rare), Phoenix Feather (revive), Time Glass (−50% CD), Void Heart (invincibility on kill) (Legendary).

### Pets (5)
Dragon (fireballs), Fairy (heals), Wolf (charge), Owl (+XP), Phoenix (revive). Owl/Dragon unlocked via achievements. Follow at orbit 60px.

### Combo
2s window; multiplier = 1 + (kills/5)×0.1 applied to XP. Tiers: Bronze 0 → Silver 10 → Gold 25 → Platinum 50 → Diamond 100 → Godlike 200, escalating visuals + screen shake.

### Waves/Difficulty
- Difficulty = `1 + 0.15·sqrt(level) + minutes·0.05`.
- Spawn interval = `2.0 / (1 + minutes·0.06)`, floor 0.3s; wave size = `(2 + level/5) × difficulty`, cap 25; every 5th wave extra bats.
- Spawn ring 500–650px around player. HP ×(min(diff,10)), DMG ×(min(diff,5)), speed ×(min(1+(diff−1)·0.25, 2.5)).
- Population: hard cap 500 entities / 300 enemies; cull enemies >900px; despawn farthest if over cap.

### Hazards (8 stage hazards, every 25s, max 6)
Fire Geyser, Ice Patch, Spike Trap, Poison Swamp, Lightning Rod, Healing Spring, Teleport Pad, Fire Wall.

### Save/Meta
Room DB `PlayerSave` (gold, bests, 6 meta levels, prestige, blessingLevels, unlockedPets, settings, accessibility toggles) + `RunRecord` per run; DataStore mid-run save. Meta upgrades 6 stats ×20 levels, cost `50 + lvl·75`, +5% each. Prestige 5 tiers (10k→5M gold, +2%→+15% might etc.). Blessings 10 types ×10 levels, cost `100×1.5^lvl`.

### Performance history (lessons)
- Entity cap 500, enemy cap 300, particle cap 150 (kills oldest).
- Object pooling for entities (initial 128); cached active-entity list (no per-frame alloc); reused `findInRange` result list; squared distances; single-pass collision categorization; insertion sort on nearly-sorted layers; cached damage-number strings; per-enemy hit cooldown maps; sound throttle 30ms/15 sounds per sec.
- Late bugs: weapons stopped firing at 30s (stale entity recycle ate weapons), DamageBoost additive might exploit, boss kill counted per-frame, runSaved flag not reset on continue, SLOW_ZONE permanently shrinking speed (multiplicative decay never restored), weapon tier multipliers compounding without base reset.
- Unwired systems found by bug report: synergy, blessings, pets, prestige, achievement rewards, haptics — i.e., **feature creep outran integration testing**.

## 3. What Should Be Preserved (identity of the game)

1. **Core loop**: auto-attack weapons, XP gems → level-up pause → 3 choices, build crafting, evolutions.
2. **Weapon roster & feel** (8 weapons with distinct behaviors; homing, orbit, boomerang return, AOE, DoT zones).
3. **Elite/boss cadence** (elite every N levels, mini-boss timed, boss milestone) and elite ability set (8 modular abilities).
4. **Threat/population caps + pooling discipline** (proven necessary at 300+ enemies).
5. **Combo with decay + multiplier on XP**, 6 tiers.
6. **Data-driven stat scaling** formulas (difficulty multiplier form is sane and battle-tested).
7. **Relic rarity-weighted pickups**, pets, one active ability per character.
8. **Save/meta separation** (run state ≠ meta state), versioned saves.
9. Accessibility toggles (damage numbers, particles, shake) and graphics quality tiers.

## 4. What Should Be Redesigned for 3D Third-Person

1. **World**: infinite 2D plane → **compact bounded 3D arena** (~120×120 m) with landmarks, boundaries, spawn zones. No streaming needed for MVP.
2. **Distances**: all px values become meters with re-tuned ratios (e.g. spawn ring 35–45 m, pickup 2.5 m, ranges 15–40 m).
3. **Camera**: static top-down translate/zoom → **third-person follow rig** (yaw orbit via mouse/right stick/touch, pitch clamp, spring arm collision, optional dynamic zoom). Vertical dimension introduces occlusion — readability rules (enemy outlines, ground rings) must compensate.
4. **Collision**: brute-force circle tests → **Godot physics spheres/capsules + spatial partitioning** (physics layers + Area3D or manual uniform grid). Never O(n²) per frame.
5. **Aiming-free combat stays, but in 3D**: weapons auto-target; orbit weapons move on the **horizontal plane**; AOE becomes ground circles; melee arcs use cone checks.
6. **Enemy identity**: color+shape primitives → **stylized low-poly meshes** with strong silhouettes + team-color/emissive accents; readability > detail.
7. **Damage numbers**: world-space text → billboarding `Label3D` (capped pool) or HUD-projected labels.
8. **Tower Defense mode**: fundamentally screen-space 2D; **exclude from MVP** (candidate for a later top-down-lane 3D redesign).
9. **Haptics/ads/billing**: drop ads/billing (web-first, static); haptics optional via mobile web APIs later.
10. **Performance model**: entity caps re-derived from 3D draw-cost reality (150–250 enemies MVP), plus a PerformanceManager that scales shadows/VFX before entity counts.

## 5. What Should NOT Be Copied Literally

- **Two/three overlapping implementations of the same system** (legacy RelicSystem vs new, EliteAbilitySystem vs EliteAbilities, MapHazard vs StageHazard, CharacterClass enum vs DB roster) — in the 3D project, exactly **one** implementation per system, wired from day one.
- **The "systems defined but never wired" pattern** (BUG_REPORT_v1.2.6: synergy, blessings, pets, prestige, rewards, haptics all unwired). Rule for the remake: a system ships only when it is integrated, tested, and its UI reflects it.
- **Unbounded multiplicative decay bugs** (SLOW_ZONE-style per-frame multipliers without restore). Rule: all timed modifiers stored as (value, remaining_time) and re-applied from base each frame — never multiply in place.
- **Per-frame allocations / global searches** in hot loops. Rule: cached lists, pools, spatial queries only.
- **Tower Defense 1942 shooter**, AdMob/Billing, offline progress, daily login — out of MVP scope.
- **Procedural ToneGenerator audio** — replace with real (free) SFX/music assets or minimal synthesized audio in Godot.

## 6. Mechanics Fit for 3D As-Is

- Auto-attack + cooldown weapons (all 8 archetypes translate directly).
- XP orbs with magnet pickup; level-up pause + 3 choices.
- Elite modifier system (8 abilities) — all work in 3D.
- Combo decay + XP multiplier.
- Relic rarity pickups; one pet (Dragon archetype) following + auto-attacking.
- Threat-capped spawning + cull distance.
- Difficulty multiplier formula `1 + a·sqrt(level) + b·minutes` (re-tune constants).
- Achievements, save/meta split, graphics quality tiers.

## 7. Mechanics Needing Modification for Third-Person Gameplay

1. **Global-hit abilities** (Meteor Strike hits all enemies) become **arena-wide VFX + damage**, acceptable, but AOE abilities (Frost Nova) get explicit ground circles.
2. **Time Freeze** full-screen tint works, but needs enemy outline/status visual per-enemy to read correctly in 3D depth.
3. **Pickup range** (50px 2D) → magnet radius ~2.5–3 m with visible magnet VFX; else XP orbs are hard to see in 3D.
4. **Spawn ring** 500px → 35–45 m AND spawn points must be **outside the camera frustum or behind props** to avoid pop-in.
5. **Lightning Ring** radius strike: needs a visible ground ring telegraph in 3D.
6. **Boomerang** pathing: straight out-and-back works; add slight arc for readability.
7. **Camera-relative movement**: player movement must be camera-relative (WASD relative to yaw), unlike the screen-fixed 2D joystick.
8. **Occlusion management**: low camera pitch default, elevated ground-markers for pickups, enemy health bars billboarded; "readability shader" (outline) optional post-MVP.

## 8. Concrete Takeaways for the New Project

- Keep the weapon-first design: weapons define the fun. Port all 8 weapon behaviors + 8 evolutions over phases.
- Reuse the difficulty/cadence formulas with re-tuned constants (spawn 35–45 m, cull 70 m, arena 120×120 m).
- One manager per responsibility; data as Godot `Resource`s; pooling mandatory for enemies/projectiles/orbs/VFX/damage numbers.
- Caps: enemies 150–250, projectiles 150, particles 120, damage numbers 40 — all configurable.
- A single `DamageSystem` pipeline (crit, armor, status, death → loot) so weapons never duplicate formulas.
- Bug-proof patterns from the reference's mistakes: modifier store re-applied from base; single recycle path guarded by type whitelists; state-reset on run start; per-enemy hit cooldown maps; kill-once guards for boss rewards.
- Web-first: Compatibility renderer, low draw calls, merged meshes where possible, no per-frame allocations, budgets in PerformanceManager.

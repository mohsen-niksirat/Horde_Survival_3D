# GAME DESIGN — HordeSurvival 3D

> Version: 0.1 (Phase 0) · Platform-first: Desktop + Mobile Web (GitHub Pages), future Android export
> Engine: Godot 4.x, GDScript, Compatibility renderer. No backend. Static web app.

---

## 1. High Concept

**HordeSurvival 3D** is a third-person 3D survival roguelite. The player enters a stylized fantasy arena, survives increasingly dangerous hordes, and never aims — weapons fire automatically. Killing enemies drops XP; leveling up pauses the game and offers upgrade choices that snowball into overpowered builds with weapon evolutions, relics, and pets.

**Design sentence:** *Vampire Survivors gameplay philosophy + third-person 3D action game.*
**Not:** a manual-aim shooter. The camera exists for orientation and spectacle, not aiming.

## 2. Pillars

1. **The horde is the spectacle.** Hundreds of enemies on screen, readable silhouettes, satisfying mass-kill feedback.
2. **The build is the fantasy.** Weapon synergies, evolutions, and modifiers create "broken build" moments.
3. **Zero-friction play.** Launch in browser, no install, auto-attack means mobile and desktop play identically.
4. **Readable chaos.** In 3D, clarity is earned: silhouettes, ground telegraphs, capped VFX, tuned camera.

## 3. Core Loop

```
Enter arena → move (WASD / joystick) → horde approaches
→ weapons auto-fire → kills → XP orbs (magnet pickup) → level up
→ pause → choose 1 of 3 upgrades → resume, stronger
→ every N levels: elite → timed mini-boss → milestone boss
→ survive to target duration (MVP: 15 min) → results screen → meta gold
```

## 4. Player Fantasy & Controls

**Third person, camera-relative movement, auto-attack.**

| Action | Desktop | Mobile | Gamepad |
|---|---|---|---|
| Move | WASD | Left virtual joystick | Left stick |
| Camera yaw/pitch | Mouse (captured) or arrow keys | Right touch region drag | Right stick |
| Ability 1/2 | Q / E (or R/F) | Ability buttons | Triggers |
| Dash (post-MVP) | Space | Dash button | A/Cross |
| Pause | Esc | Pause button | Start |

- Movement **accelerates** (0.15s to full speed) and decelerates quickly — weighty but responsive.
- Camera: smooth follow, yaw orbit, pitch clamp (−60°..−15° default −35°), distance 6–9 m with dynamic zoom (closer when idle, farther when moving), collision spring arm, subtle shake on hits/boss.
- Default camera keeps player slightly below screen center to see the horde ahead.

## 5. Stats & Modifier Model

Player stats (all data-driven): `max_hp, armor, regen, move_speed, pickup_radius, might (dmg mult), area_mult, cooldown_mult, attack_speed, projectile_bonus, crit_chance, crit_mult, luck, xp_gain, gold_gain, projectile_size`.

**One universal ModifierSystem.** Every source (character, upgrade, relic, pet, blessing, prestige, buff/debuff) produces modifiers; StatsComponent recomputes final stats = base × Σ modifiers. **Timed modifiers are stored as (value, duration) and re-applied from base every frame** — never multiplied in place (reference-game bug).

## 6. Weapons (MVP: 5, port all 8 archetypes post-MVP)

| Weapon | Type | MVP behavior (3D-tuned) |
|---|---|---|
| Fireball | Projectile+AOE | Auto-targets nearest, explodes on impact, ground burn zone at higher tiers |
| Magic Missile | Homing | Multiple homing bolts, 3D homing on locked targets |
| Orbiting Shield | Orbit | Shields orbit player on horizontal plane, contact damage |
| Divine Spear | Piercing line | Long fast piercing bolt, crit-focused |
| Lightning | AOE strike | Random enemies in radius struck, ground ring telegraph |

- Each weapon: `WeaponData` resource (damage, cooldown, projectile_count, speed, area, pierce, crit, status, targeting, evolution_id, VFX/SFX refs) + level 1–5 tier effects + evolution.
- **Evolutions (MVP: 2)** — weapon at tier 5 + required maxed passive → evolution offered (Legendary):
  - Fireball + Spinach → **Hellfire** (×3 dmg, burning ground trails)
  - Magic Missile + Empty Tome → **Holy Bible** (×3 dmg, orbiting homing tomes)

## 7. Enemies (MVP: 5 archetypes)

| Archetype | Behavior | Notes |
|---|---|---|
| Basic Drone | straight chase | bread-and-butter horde filler |
| Fast Wisp | fast chase | flanking pressure |
| Tank Golem | slow, high HP | blocks lanes, soak |
| Shooter Turret | stationary ranged | forces movement, 2s volley |
| Swarm Bat | fast erratic | sine wobble, spawns in packs |

Later: Ghost (sine path), Splitter, Healer, Mage (kite/strafe ranged), Charger, Shielder, Teleporter.
All enemy defs are `EnemyData` resources: hp, speed, damage, xp, gold, size(radius), attack_range, attack_cooldown, movement_type, spawn_weight, rarity, elite_flags.

**Elite system (modifiers, not new enemies):** Teleport, Shield, Explode on Death, Healer Aura, Speed Boost, Split on Death, Vampiric, Thorns. Elites = existing enemy + EliteComponent (1–2 abilities, gold tint, ×3 HP ×2 dmg ×1.3 size, ×10 XP ×5 gold).

**Boss (MVP: ONE complete boss):**
- Cadence: milestone boss (e.g., first at 5 min / level 25), announced with warning banner + intro VFX.
- Phases: **P1** chase + contact + occasional ground-slam AOE (telegraphed ring); **P2** (<50% HP) adds ranged volley fan + summons swarm minions; **Enrage** (<25%) speed/damage up, faster patterns, arena edge glow.
- Rewards: big XP orb burst, gold, guaranteed relic/heal drop, results bonus.

## 8. Combat Pipeline (single, mandatory)

```
Weapon → TargetingSystem → Hit detection → DamageEvent
→ crit roll → armor/resistance → final damage
→ status effects (burn/freeze/slow/knockback…) → death check
→ XP/gold/loot drop → combo increment → achievements
```

Status effects MVP: Burn, Slow, Freeze, Knockback (Bleed/Shock/Poison post-MVP). Effects are data-driven; each entity holds a status list; re-applied from base per tick.

## 9. Progression & Pacing

- XP curve: `xp_to_next = 12 × 1.18^(level−1)` (retuned for 3D kill rates; target: level ~25 by 10 min).
- Level-up: pause gameplay (single-player pause, not scene tree pause), 3–4 choices (new weapon / tier-up / passive / relic-flavored / heal fallback), no duplicate useless options, rarity-colored cards.
- **Threat-budget spawning**: Basic=1, Fast=2, Tank=4, Ranged=3, Swarm=0.5, Elite=10, Boss=100. Budget grows over time; density and composition shift before raw HP does.
- Difficulty = `1 + 0.18·sqrt(level) + minutes·0.06`; caps on per-stat scaling (HP ×10, DMG ×5, speed ×1.8) as in reference.
- Timeline: 0–2 min basics only → 2–5 min +fast/swarm/ranged → 5–10 min +tanks, elites begin → 10–15 min high density + mini-bosses → boss → survive to 15 min.
- Population caps: 200 enemies / 150 projectiles / 120 particles / 40 damage numbers (configurable, quality-scaled).

## 10. Relics, Pets, Abilities (post-core MVP slices)

- **Relics**: map pickups every 45s (max 3, 120s lifetime), rarity-weighted (C50/U30/R15/L5): Crown (+25% XP), Wings (+20% speed), Armor (+8 armor), Clover (+15% luck), Ring (+15% might), Amulet (+1 regen), Chalice, Gauntlet (+2 projectiles), Phoenix Feather (revive)…
- **Pet (MVP: 1)** — **Dragon Welp**: follows player (lerp offset orbit), auto-fires small fireball at nearest enemy every 2s (scales with player might & pet level). Architecture supports Fairy/Wolf/Owl/Phoenix later.
- **Active abilities (MVP: 2)** — **Meteor Strike** (targeted ground AOE, 25s CD) and **Time Freeze** (arena freeze 3s, 30s CD); buttons on HUD + keys, cooldown UI.

## 11. Combo & Feedback

- Kills within 2s chain; combo multiplier `1 + (kills/5)×0.1` applied to XP; decay resets.
- Tiers: Bronze → Silver(10) → Gold(25) → Platinum(50) → Diamond(100) → Godlike(200); HUD counter escalates size/color/shake.
- Feedback checklist: hit flash, damage numbers (crits gold), death burst, XP sparkle, level-up ring, screen shake (scaled by quality), low-HP vignette, boss warning banner, weapon trails.

## 12. Meta (between runs)

- Gold from kills/bosses → permanent stat upgrades (HP/Might/Cooldown/Speed/Luck/Gold, 20 levels, cost `50+lvl·75`).
- Character roster: 3 free starters (Mage/Paladin/Rogue archetypes), unlockable with gold; each = statline + starting weapon + perk.
- Achievements MVP: 8–10 (kills 1/100/1000, survive 5/10 min, level 10/25, first boss, combo 25) with gold rewards.
- Save: versioned `SAVE_VERSION=1` JSON via `user://` (web: IndexedDB), run-state ≠ meta-state.

## 13. Game Modes

- MVP: **Survival (endless)** with 15-min target + **Daily-flavored challenge** deferred. Tower Defense, Boss Rush, Quests: post-MVP, redesigned for 3D (TD becomes a lane-defense arena variant or is cut).

## 14. World & Visual Direction

- **One compact arena** (~120×120 m): stylized low-poly fantasy meadow with stone ring boundary, 4 landmark pillars, scattered rocks/trees (cheap colliders off for horde flow), central beacon, warm directional light + subtle fog, sky gradient.
- Style: flat-shaded low-poly, saturated but readable palette; enemies strongly color-coded by archetype; emissive accents for elites/boss/projectiles; ground decal rings for every AOE.
- Animations MVP (procedural/simple): idle bob, run lean/bob, attack cue, hit flash, death fall+shrink. No skeletal cinematic work.

## 15. Audio

Music: one ambient loop + intensity layers (calm/tense/boss). SFX: weapon fire per type, hit, death, XP pickup, level up, UI, boss warn/death. Volume: Master/Music/SFX. Web-safe (no autoplay before user gesture — audio starts after "Click to Play").

## 16. UX Screens

Boot/Loading (progress + Click to Play + WebGL fallback) → Main Menu (Play, Characters, Achievements, Settings, How to Play) → Character Select → Game (HUD: HP bar, XP bar, level, timer, kills, combo, weapon icons, ability buttons, pause) → Level-Up overlay → Pause → Game Over/Results (stats, gold, Play Again/Menu). Responsive: mobile gets bigger touch targets, joystick, safe-area margins, landscape recommendation.

## 17. MVP Definition (acceptance)

All of: menu → start → third-person movement + camera (desktop + mobile input architecture) → arena → 5 enemy archetypes spawning with threat budget → XP/levels/upgrade choices → 5 weapons auto-attacking → damage pipeline + statuses → pooling → elites → 1 phased boss → 2 abilities → 2 evolutions → relics → 1 pet → combo → 8 achievements → save/load → responsive HUD → pause → game over → performance manager → web export → GitHub Pages deployment.

## 18. Explicit Non-Goals (MVP)

Manual aiming; open world; photorealistic assets; multiplayer; backend/accounts; ads/billing; Tower Defense mode; 10 bosses; 20 evolutions; Persian-only UI (EN first, i18n-ready).

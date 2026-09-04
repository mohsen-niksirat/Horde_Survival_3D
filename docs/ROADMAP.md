# ROADMAP — HordeSurvival 3D

> Rule: no phase is "done" while known blocking errors exist. Each phase ends with: inspect → run → fix → test → document → push to GitHub → next.

| Phase | Scope | Deliverable / Exit criteria | Status |
|---|---|---|---|
| **0 — Research** | Analyze reference repo; write EXISTING_GAME_ANALYSIS, GAME_DESIGN, ARCHITECTURE, ROADMAP | Docs committed & pushed | ✅ done |
| **1 — Godot Foundation** | Godot 4 project (Compatibility), folder structure, GameManager + states, InputManager, EventBus, PoolManager skeleton, basic UI, Main Menu, empty Game scene, basic arena, project runs | Game launches to menu → arena (desktop build + web preview) | ⬜ |
| **2 — Third-Person Controller** | Player scene, movement (camera-relative), camera rig (follow, orbit, pitch clamp, spring arm, dynamic zoom), InputManager keyboard+mouse+touch abstraction, idle/run animation placeholder | Player moves smoothly in arena with camera; mobile joystick functional | ⬜ |
| **3 — First Enemy** | Enemy scene, EnemyData resource, HealthComponent, chase AI (grid steering), contact damage, death, XP orb drop + magnet pickup, pooling for enemy+orb | An enemy follows, damages, dies, drops XP the player collects | ⬜ |
| **4 — First Weapon** | Weapon framework (WeaponData, WeaponInstance, WeaponController), Fireball (auto-target nearest, projectile, AOE, cooldown), DamageSystem pipeline v1 (crit/armor), hit VFX + SFX | Player auto-attacks; enemies die to fireballs through the unified damage pipeline | ⬜ |
| **5 — Horde System** | WaveManager, SpawnManager (threat budget, spawn ring, camera-aware spawn points), DifficultyManager, cull distance, entity caps, pool hardening | Real survival loop: escalating hordes with caps, stable at 150+ enemies | ⬜ |
| **6 — XP / Level Up** | XP curve, level-up pause, upgrade generation (new weapon/tier/passive/heal), upgrade application via ModifierSystem, rarity cards UI | Player builds power during a run; no duplicate dead choices | ⬜ |
| **7 — Multiple Weapons** | Magic Missile (homing), Orbiting Shield (orbit), Divine Spear (pierce/crit), Lightning (AOE strike); status effects v1 (burn, slow); targeting modes (nearest/lowest/random/area) | 5 working, distinct weapons | ⬜ |
| **8 — Elites + Boss** | EliteComponent (8 modular abilities), elite cadence, ONE complete boss (phases 1/2/enrage, telegraphs, minion summons, rewards), boss intro/outro | Elites appear with abilities; boss fight is complete and beatable | ⬜ |
| **9 — Horde Survival Systems** | 2 weapon evolutions, relics (rarity pickups), 1 pet (Dragon Welp), 2 active abilities (Meteor Strike, Time Freeze), combo system, achievements (8–10), save system v1 | Meta + run systems integrated AND wired into HUD/menus (no "unwired systems") | ⬜ |
| **10 — Polish** | VFX pass (hit flash, death, level-up, boss), camera shake, low-HP vignette, sound pass + volume settings, loading screen, settings menu, responsive/mobile UI pass | Game feels finished, not prototype | ⬜ |
| **11 — Optimization** | Profile desktop+mobile web; MultiMesh for orbs if needed; draw call / pool / particle tuning; quality tiers (Low/Med/High) auto-detect | 60 FPS desktop, 30+ FPS mid-range mobile in 200-enemy stress scene | ⬜ |
| **12 — Web Deployment** | Export preset, GitHub Actions workflow, GitHub Pages deploy, loading shell, Click-to-Play, PWA manifest, WebGL fallback | Public playable URL on Pages | ⬜ |
| **Post-MVP backlog** | Remaining evolutions (8 total), more enemies (ghost/splitter/healer/mage), more pets/abilities/characters, meta upgrades shop, daily challenge, redesigned TD, Android export | — | ⬜ |

## Phase testing checklists (minimum)

- **P1:** project opens in Godot without errors; menu → arena transition; pause/resume.
- **P2:** 60 FPS movement in editor + browser; camera occlusion works; joystick on touch device/emulation.
- **P3:** enemy recycle under pool stress (spawn/despawn 500 cycles, no leaks); XP collect increments XP.
- **P4:** damage numbers match expected crit/armor math; weapon stops/starts cleanly on pause.
- **P5:** 5-min soak: entity count stable ≤ caps, no memory growth, spawn interval timeline correct.
- **P6:** level-up pauses world; choices apply; resume clean; no stacked duplicate offers.
- **P7:** each weapon fires/levels distinctly; status effects expire correctly (no per-frame multiplier bugs).
- **P8:** elite abilities all trigger and expire; boss transitions once (no double-count kills).
- **P9:** save round-trip (write→load→write); achievements fire once; evolution only at tier 5 + passive max.
- **P11:** stress scene 250 enemies on Low quality stays ≥30 FPS on mid mobile-class hardware.
- **P12:** deployed URL loads in Chrome/Firefox desktop + Android Chrome; save persists across reload.

## Definition of Done (per feature)

1. Data in `.tres` resources, not magic numbers.
2. Integrated (UI/HUD reflects it), not just implemented.
3. No new per-frame allocations or O(n) scans in hot paths.
4. Pooled if high-frequency.
5. Tested (headless where possible).
6. Documented (CHANGELOG + phase report) and pushed.

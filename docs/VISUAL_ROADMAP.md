# VISUAL & CONTENT ROADMAP — long-term improvement phases

> Companion to `ROADMAP.md` (engineering). This file sequences the GAME-FACING
> improvements: graphics, characters, weapons, effects, content.
> Rule from the main roadmap still applies: FEEL → CLARITY → STABILITY → POLISH → FEATURES.
> Each phase: implement → headless suite green → commit → push. One phase at a time.

## V1 — Hero visual identity  ✅
Replace the placeholder capsule with a stylized low-poly hooded mage built
from primitives (robe, torso, hood, staff with glowing orb, shoulders).
Procedural idle bob, run lean, staff sway; subtle orb pulse.
Deliverable: player is instantly readable as "the hero".
Test: scene loads with all parts; run bob animates; suite green.

## V2 — Enemy visual identity  ✅
Per-archetype distinct primitive-built models instead of uniform spheres:
- Drone: hovering round bot with antennae
- Wisp: floating flame-ish kite shape, trail glow
- Golem: bulky stacked-stone body, slow lumber bob
- Turret: tripod base + rotating barrel head
- Bat: small body + flapping wing planes
Team-color coding kept; per-type death effect. Boss already distinct.
Deliverable: enemies are identifiable by silhouette alone.
Test: each archetype spawns with its meshes; suite green.

## V3 — Weapon models & firing visuals  ✅
- Visible weapon prop on the hero (staff orb is the muzzle for most)
- Per-weapon projectile redesign: Fireball (rolling flame + ember trail),
  Magic Missile (bright bolt + streak), Divine Spear (long shaft + light
  trail), Lightning (jagged bolt segment + strike flash)
- Muzzle flash + per-weapon fire SFX distinction
Deliverable: every weapon looks and sounds like itself.
Test: each fires its scene; pooled; suite green.

## V4 — Arena beauty pass  ✅
Ground shader (soft two-tone grass noise), scattered grass tufts/rocks/
trees (cheap, no collision), redesigned boundary (stone ring instead of
plain walls), beacon redesign (crystal monument), warm key light + fog
tune, sky gradient. Spawn-zone markers subtle.
Deliverable: arena reads as a place, not a test grid.

## V5 — Combat juice  ✅
3D damage-number billboards (pooled, crits bigger/gold), kill burst VFX,
XP orb trails + MultiMesh batching, level-up ground ring, elite aura
ring, boss death explosion, low-HP heartbeat vignette refinement.
Deliverable: kills feel juicy and readable at 200+ entities.

## V6 — Content wave 1 (enemies + evolutions)  ✅
4 new archetypes per GAME_DESIGN §7: Ghost (sine + phase), Splitter
(splits at 50% HP), Healer (support aura), Mage (kite + telegraphed
volley). Then the 6 remaining weapon evolutions following the Hellfire
pattern. Wave timeline integration + threat costs.

## V7 — HUD/UI polish  ✅
Weapon/ability icons, animated HP/XP bars, combo tier banner animations,
main menu with animated background, character select layout.
Deliverable: UI stops looking default.

## V8 — Audio pass  ✅
Procedural ambient music loop + intensity layers (calm/tense/boss),
fuller SFX set, master/music/sfx mix polish, hit-kill feedback sounds.

## V9 — Meta & modes  ✅
Endless mode toggle (post-15min scaling), permanent gold upgrade shop
(6 stats), 3 starting characters (Mage/Paladin/Rogue) with perks, save
migration.

## V10 — Optimization + Android  ✅ (device profiling remains)
Evidence-based optimization from stress-scene numbers (MultiMesh orbs,
shared materials, spawn-burst scheduling), auto quality detection,
Android export per BUILD_ANDROID.md.

---

### Working order & guards
- Never break Web export; never regress the headless suite.
- Graphics changes must keep entity budgets (V4/V5 respect particle caps).
- Content (V6) only after V1–V5 land, so new content ships pretty.
- Each phase ends with: suite green → commit → push → playtest feedback
  from Mohsen → next phase.

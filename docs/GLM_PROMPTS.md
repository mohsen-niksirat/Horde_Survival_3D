# GLM PROMPTS — راهنمای پرامپت برای GLM 5.3 (OpenCode)

> این فایل مجموعهای از پرامپتهای آمادهی کپی برای GLM 5.3 است که روی این پروژه
> (HordeSurvival 3D — Godot 4.7, GDScript, Compatibility renderer) در OpenCode کار میکند.
> پرامپتها عمداً **انگلیسی** نوشته شدهاند چون برای کدنویسی خروجی GLM به انگلیسی
> قابلاطمینانتر است. فارسی هم جواب میدهد، ولی برای تسکهای پیچیده انگلیسی مطمئنتر است.

**روش استفاده:**
1. یک تسک را از لیست پایین انتخاب کن (یا از ROADMAP).
2. پرامپت را کپی کن، جای «[…]» را با جزئیات خودت پر کن.
3. بعد از هر تسک، یک خط نتیجه در این فایل (بخش «لاگ پرامپت») اضافه کن.

---

## ۱. قوانین پرامپتنویسی (۷ قانون طلایی)

1. **هر پرامپت را با «اول این داکها را بخوان» شروع کن**: `docs/ROADMAP.md`،
   `docs/ARCHITECTURE.md`، `docs/GAME_DESIGN.md`. پروژه بهخوبی مستند شده — بگذار GLM از آن استفاده کند.
2. **هر پرامپت = یک قابلیت + معیار پذیرش.** سطرهای ROADMAP خودشان الگوی پرامپت هستند (Scope + Exit criteria).
3. **محدودیتها را هر بار کپی کن** (به آن اعتماد نکن که یادش بماند).
4. **همیشه بخواه کل تستهای headless را اجرا کند** و جدول pass/fail بدهد.
5. **بازخورد پلیتست را به شکل «علائم دقیق» بده**، نه «این را بهتر کن».
6. **جلوی بزرگشدن بیکنترل کار را بگیر**: اگر کار بیشتر از ~۳۰ دقیقه شد، اول پلن بدهد و تأیید بگیرد.
7. **لاگ پرامپت نگه دار** — بخش انتهایی همین فایل را پر کن.

### بلوک محدودیتها (به هر پرامپت بچسبان)

```
Constraints: content lives in data/*.tres resources (no magic numbers in code);
entities are pooled; zero per-frame allocations in hot paths; enemies are NOT physics
bodies (lightweight Node3D + manual movement + spatial-hash queries); keep the
Compatibility renderer; the Web export must keep working; keep the diff minimal —
never refactor working systems; pause/level-up use tree.paused with process_mode
whitelists — don't break them; if SAVE_VERSION changes, add a migration.
When done: run the full headless suite, fix failures, update ROADMAP.md statuses and
docs, and end with a short change list.
```

### دستور اجرای تستها

```text
godot --headless --path . --script res://tests/smoke_phase1.gd
godot --headless --path . --script res://tests/test_phase2.gd   (… phase3..10، task_a1، a4، a5)
```

---

## ۲. پرامپتهای آماده (به ترتیب اولویت)

### پرامپت ۱ — تمیزکاری وضعیت فعلی (اولین پرامپت)

```text
Project: HordeSurvival 3D (Godot 4.7, GDScript, Compatibility renderer, repo root).

I just fixed tests/test_phase3.gd so XP orbs drop in magnet range. Now run the FULL
headless suite and make every test green:
  godot --headless --path . --script res://tests/smoke_phase1.gd
  godot --headless --path . --script res://tests/test_phase2.gd   (repeat for phase3..10, task_a1, a4, a5)

If a test fails, fix the smallest thing — prefer fixing the test to match intended
behavior, but ask me first if it looks like a real gameplay bug. Touch nothing else.
End with a pass/fail table and a clean git status.
```

### پرامپت ۲ — بچ پلیتست (با ارزشترین کار؛ جاهای «[…]» را با علائم دقیق پر کن)

```text
Project: HordeSurvival 3D. I played the live build and here is my feedback.
Fix each item with the smallest diff; if two fixes conflict, pick the one that
makes the game feel better and tell me what you changed and why.

- [مثال: on mobile the right-side camera drag feels too fast near the edges]
- [مثال: boss warning banner hides the XP bar on narrow screens]
- [...]

Constraints: balance numbers unchanged unless I asked, no new settings screens
unless needed, run the full headless suite, end with a change list + what to re-test.
```

### پرامپت ۳ — فاز ۱۱: بهینهسازی «اول اندازهگیری، بعد بهینهسازی»

```text
Project: HordeSurvival 3D. Read docs/ARCHITECTURE.md §2.7 and docs/ROADMAP.md Phase 11 first.

Goal: 60 FPS desktop + 30 FPS mid-range mobile web at 200+ enemies, without changing
game feel or balance.

Step 1 — Instrument: extend the F3 debug overlay with FPS, per-system frame time
(spawning/targeting/combat/VFX), entity counts, draw calls. Add a dev-only stress scene
forcing 250 enemies + full VFX.
Step 2 — Measure: tell me exactly what to record on desktop and on a phone browser.
Step 3 — Optimize by evidence only, in this order: XP-orb MultiMesh → spatial-hash
targeting → VFX/particle budget per quality tier → draw calls/shared materials →
spawn-burst scheduling (no frame spikes when a wave spawns).

Constraints: no physics bodies for enemies, zero per-frame allocations, Compatibility
renderer, web export intact, balance untouched. Headless tests green after each step.
End with before/after numbers and what you ruled out.
```

### پرامپت ۴ — محتوا: ۶ اِوولوشن باقیمانده

```text
Project: HordeSurvival 3D. Read docs/GAME_DESIGN.md §6 and study the two existing
evolutions end-to-end (Hellfire, Holy Bible): data .tres, behavior, VFX/SFX,
level-up card, HUD indicator.

Add the 6 missing evolutions, one per remaining weapon, following that EXACT pattern.
Each requires weapon tier 5 + a maxed passive from the existing pool (add a new passive
only if none fits) and must feel 2.5–3x stronger with distinct visuals and sound.
Everything in WeaponEvolutionData — no magic numbers. Wire into the existing
evolution-offer flow. Update the evolution test if it enumerates evolutions, add a
docs table of all 8, run the full suite.
```

### پرامپت ۵ — محتوا: ۴ آرکتایپ دشمن جدید

```text
Project: HordeSurvival 3D. Read docs/GAME_DESIGN.md §7 and docs/ARCHITECTURE.md §2.4.
Study the existing archetypes (Basic Drone, Fast Wisp, Tank Golem, Shooter Turret, Swarm Bat).

Add 4 data-driven archetypes as EnemyData + scene + behavior script, same pattern:
- Ghost: sine-wave path, brief phasing (untargetable), low HP, high XP reward
- Splitter: splits into 2 small copies once at 50% HP (pooled, not instantiated fresh)
- Healer: support unit, heals nearby enemies in a radius; cap 3 alive; high targeting priority
- Mage: keeps distance, casts telegraphed ranged volleys

Add each to the WaveProfile timeline at sensible minutes with correct threat cost;
tune XP/gold to threat. No physics bodies. Headless suite green; update docs.
```

### پرامپت ۶ — حالت Endless (ادامهی بینهایت بعد از دقیقهی ۱۵)

```text
Project: HordeSurvival 3D. Read docs/GAME_DESIGN.md §13 and the WaveManager /
DifficultyManager code.

Add an Endless toggle on the Main Menu: Survival keeps the EXACT current 15-min
balance; Endless continues past minute 15 with slower difficulty growth, higher
quality-tier caps, and the boss returning every 5 minutes at +30% stats. Track best
endless time + level in SaveManager (bump SAVE_VERSION with a migration) and show it
on the menu. Headless tests green incl. save round-trip; update docs.
```

---

## ۳. ایدههای بعدی (بدون پرامپت کامل — وقتی لیست بالا تمام شد)

- **متاشاپ ارتقای دائمی با طلا** (سکشن ۱۲ GAME_DESIGN): HP/Might/Cooldown/Speed/Luck/Gold،
  ۲۰ سطح، هزینه `50 + level*75`، صفحهی جدا از منوی اصلی + میگریشن سیو.
- **۳ کاراکتر شروعکننده** (Mage/Paladin/Rogue) — ساختار `CharacterData` از قبل در
  معماری هست؛ فقط دیتا + صفحهی انتخاب + اتصال به ModifierSystem.
- **اکسپورت اندروید** — طبق `docs/BUILD_ANDROID.md` (بعد از فاز ۱۱).
- **باسراش / دیلی چلنج / پت و رلیکهای بیشتر** — بکلاگ پست-MVP در ROADMAP.

---

## ۴. لاگ پرامپت

| تاریخ | پرامپت (خلاصه) | نتیجه / تغییرات | وضعیت |
|---|---|---|---|
|  |  |  |  |
|  |  |  |  |
|  |  |  |  |
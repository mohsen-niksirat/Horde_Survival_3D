# BUILD ANDROID (post-MVP guide)

The project is architected to be Android-export-compatible:
- Compatibility (GL) renderer works on GLES3 devices
- Touch input is abstracted via InputManager (virtual joystick + look region already implemented)
- No native-only plugins or GDExtensions

## Steps (when ready)

1. **Install build tools**: Android Studio (SDK + NDK), JDK 17. In Godot: Editor → Editor Settings → Export → Android → set SDK path and debug keystore.
2. **Install Android build template**: Project → Install Android Build Template.
3. **Add preset**: Project → Export → Add → Android.
   - Package name: `com.hordesurvival3d`
   - Orientation: Landscape
   - Min SDK: 24+, Target: latest installed
   - Textures: ETC2/ASTC (already the project default for imports)
4. **Renderer**: keep `gl_compatibility` (project.godot sets both desktop and mobile fallback to compatibility).
5. **Input**: verify `DisplayServer.is_touchscreen_available()` path — TouchControls become visible automatically.
6. **Performance**: start from Quality LOW defaults for Android (PerformanceManager.set_quality(0)) — consider device-tier detection on startup.
7. Export APK/AAB; test on a mid-range device targeting 30+ FPS with the 100-enemy cap.

## Mobile-specific TODOs before release

- Safe-area margins for notched devices (HUD offsets)
- Performance tier auto-detection (`OS.get_processor_count()`, device model heuristics)
- Haptics via `Input.vibrate_handheld()` on hit/level-up (optional toggle)
- App icon set (Godot 4 uses 432x432 adaptive icon PNG)

## Web-first caveat

The MVP targets Web; Android export is validated but untested on real hardware at this stage. Budget-tune after a device test session (Phase 11-style pass).

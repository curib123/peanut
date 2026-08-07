# Current game screenshot tour

These phone-sized captures are the verified Phase 12 full-state visual audit set:

1. `01-home.png` - illustrated adventure home and branding
2. `02-settings.png` - persistent audio, haptic, motion, and reset controls
3. `03-level-map.png` - the connected vertical 60-level world journey
4. `04-pre-level.png` - recipe goals, move limit, and tutorial preview
5. `05-gameplay.png` - live HUD, AI-generated ingredient pieces, premium board, and world backdrop
6. `06-paused.png` - pause overlay over the redesigned game presentation
7. `07-victory.png` - star result, score, and unused-move reward
8. `08-failure.png` - out-of-moves recovery actions
9. `09-blockers.png` - blocker-heavy Sunrise Bakery gameplay
10. `10-sugar-harbor.png` - later-world background and gameplay presentation
11. `11-special-pieces.png` - all five special recipe sprites on one board

Regenerate the set on Windows with:

```powershell
flutter test tool/capture_screenshots_test.dart --update-goldens
```

The capture uses the Flutter SDK's local Roboto and Material Icons files so text and icons render faithfully in the test environment.

# Current game screenshot tour

These phone-sized captures show the game immediately after Phase 10 and before the Phase 11 visual redesign:

1. `01-home.png` - home and branding
2. `02-settings.png` - persistent audio, haptic, motion, and reset controls
3. `03-level-map.png` - the 60-level journey and locked progression
4. `04-pre-level.png` - recipe goals, move limit, and tutorial preview
5. `05-gameplay.png` - live HUD, deterministic board, pieces, and tutorial prompt
6. `06-paused.png` - pause overlay and map exit

Regenerate the set on Windows with:

```powershell
flutter test tool/capture_screenshots_test.dart --update-goldens
```

The capture uses the Flutter SDK's local Roboto and Material Icons files so text and icons render faithfully in the test environment.

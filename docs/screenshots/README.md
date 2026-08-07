# Current game screenshot tour

These phone-sized captures show the completed Phase 11 visual redesign:

1. `01-home.png` - illustrated adventure home and branding
2. `02-settings.png` - persistent audio, haptic, motion, and reset controls
3. `03-level-map.png` - the connected vertical 60-level world journey
4. `04-pre-level.png` - recipe goals, move limit, and tutorial preview
5. `05-gameplay.png` - live HUD, AI-generated ingredient pieces, premium board, and world backdrop
6. `06-paused.png` - pause overlay over the redesigned game presentation

Regenerate the set on Windows with:

```powershell
flutter test tool/capture_screenshots_test.dart --update-goldens
```

The capture uses the Flutter SDK's local Roboto and Material Icons files so text and icons render faithfully in the test environment.

# Current game screenshot tour

These captures were regenerated for the 19 October 2026 quality review. Portrait captures use 390×844 logical pixels; the landscape capture uses 844×390.

1. `01-home.png` - illustrated adventure home and branding
2. `02-settings.png` - persistent audio, haptic, motion, and reset controls
3. `03-level-map.png` - the connected vertical 120-level world journey
4. `04-pre-level.png` - recipe goals, move limit, and tutorial preview
5. `05-gameplay.png` - live HUD, AI-generated ingredient pieces, premium board, and world backdrop
6. `06-paused.png` - pause overlay over the redesigned game presentation
7. `07-victory.png` - star result, score, and unused-move reward
8. `08-failure.png` - out-of-moves recovery actions
9. `09-blockers.png` - blocker-heavy Sunrise Bakery gameplay
10. `10-sugar-harbor.png` - later-world background and gameplay presentation
11. `11-special-pieces.png` - all five special recipe sprites on one board
12. `12-secret-world-cloud.png` - upward journey gate hiding the next world until completion
13. `13-power-activation.png` - live combined power activation with beam, arcs, burst sheets, and bounded crumbs
14. `14-basket-goals.png` - basket positions and live recipe progress
15. `15-time-trial.png` - final-world timed gameplay and multi-goal HUD
16. `16-landscape-gameplay.png` - responsive landscape board and recipe sidebar

Regenerate the set on Windows with:

```powershell
flutter test tool/capture_screenshots_test.dart --update-goldens
```

The capture uses the Flutter SDK's local Roboto and Material Icons files so text and icons render faithfully in the test environment.

Victory and failure captures use result fixtures; lifecycle tests verify actual result/save ordering. The power capture resolves a real special combination. See [the full quality review](../QUALITY_REVIEW_2026-10-19.md) for findings, validation, and limits.

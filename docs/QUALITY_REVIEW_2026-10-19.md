# Game quality review — 19 October 2026

This pass reviewed the running Flutter game, its domain rules, navigation, assets, presentation lifecycle, and sound pipeline. The tropical bakery artwork and 120-level campaign remain the game's visual and content foundation.

## Resolved findings

| Finding | Correction | Evidence |
| --- | --- | --- |
| Landscape home and recipe actions overflowed. | Responsive home composition and scrollable recipe panels; Settings stays above the scroll surface. | Responsive screen tests; screenshot 01/04. |
| Timed HUD overflowed at narrow widths and enlarged text. | Flexible score/move counters, separate clock, and landscape sidebar. | Responsive tests; screenshots 15/16. |
| Panel art stretched into thin bars. | Cocoa-and-gold panels with consistent corners, highlights, contrast, and shadows. | Screenshots 01–10. |
| Players could not see live recipe progress or board objectives. | Immutable goal snapshots, progress bars, basket/oven markers, cream tiles, and blocker layer badges. | Lifecycle goal tests; screenshots 05/09/14/15. |
| Removing a crate left an empty cell after the turn. | Resolve clear impacts before gravity and refill in that cascade. | Session mechanics regression tests. |
| Basket levels could win from an unrelated first move. | Baskets descend through support actually cleared in their column, respecting tray barriers. | Level 41 and basket support regressions. |
| Move availability and shuffles ignored swap-locked pieces. | Include locked cells in move checks and keep them fixed during recovery. | Locked-special and locked-opening regressions. |
| Winning HUD appeared before animation/save notification; timeouts and navigation could race. | Report terminal results exactly once, settle current animation, preserve earned results on removal, and cancel delayed messages. | Game lifecycle tests. |
| Rotation could dispose and reuse the active game. | Preserve the GameWidget state across responsive layouts and defer board resizing during turns. | Live orientation and mid-cascade resize tests. |
| Combining powers silently removed other struck specials. | Expand secondary activations once while retaining the combination footprint; consumed Sparks do not clear an unrelated color. | Six special-combination regressions. |
| Button sounds bypassed mute and keyboard activation was missing. | Settings-aware audio and a focusable native interaction surface. | Button sound and keyboard tests. |
| Stalled audio could hold a turn. | Nonblocking feedback, bounded startup requests, duplicate suppression, failure handling, and recovery timeouts. | Audio and game lifecycle tests. |
| Deep links could enter locked/invalid recipes; stars ignored level thresholds. | Route access gates with recovery actions; shared recipe-specific star calculation. | Access and star-award tests. |
| The map reopened at level 1 and world labels overflowed. | Restore/recenter current progress, measure world sections, wrap ribbons, and stop decorative motion when disabled. | Six map navigation tests. |

## Presentation and sound

- More readable ingredient contrast on a layered tray, static selection for reduced motion, and less frequent sprite shine passes.
- Distinct beam sweeps, oven shock rings, recipe-power arcs, sparkle bursts, and fading crumbs. A cascade creates at most four power layers, twelve burst sheets, and one crumb layer with at most 120 particles.
- Original deterministic stereo synthesis for all 19 SFX: layered mallets, bells, pops, filtered air, sweeps, and reflections. Existing filenames and sound settings remain compatible.
- Export checks verify stereo PCM, bounded peaks/duration, silent edges, reproducibility, and equality with packaged files. The 19 cues total approximately 1.39 MiB.

## Current verification

- `flutter test --no-pub --reporter expanded`: **128 tests passed**. Whole-session campaign checks cover every level through a win or loss, including stable boards and legal move accounting.
- `dart run tool/validate_levels.dart --simulations=10000`: **120 openings and 10,000 bounded simulations passed**.
- `flutter analyze --no-pub`: **no issues**.
- `dart format --output=none --set-exit-if-changed lib test tool`: **73 files, no changes**.
- `python tool/test_sfx.py`: **2 tests passed**, including deterministic regeneration and packaged artifact comparison.
- `flutter test tool/capture_screenshots_test.dart --update-goldens --no-pub`: **16-state capture tour passed**.
- `flutter build web --release --no-pub --no-wasm-dry-run`: **passed**.
- `flutter build apk --release --no-pub`: **passed**, `build/app/outputs/flutter-apk/app-release.apk`.
- Live browser automation: **not completed**. The pre-change home was captured, but final Chromium/Edge automation stalled and the isolated Edge launch timed out. Automated Flutter gameplay/navigation tests and the capture tour passed; they do not substitute for a completed real-browser playthrough or audio listening check.

## Captured flow

1. Home: readable branding, reachable Play and Settings controls.
2. Settings: visible persistent sound, music, haptics, motion, and reset controls.
3. Journey: current-level recovery, original world/road art, and clear locked states.
4. Recipe: readable goals, move/time limits, tutorial, and Start action.
5. Gameplay: live goals, move/score/clock feedback, tray, ingredients, and markers.
6. Pause: explicit resume and journey actions.
7. Victory: recipe-based stars, score, and unused-move bonus. Screenshot uses a result fixture; real completion/save ordering is tested separately.
8. Failure: visible retry and journey recovery. Screenshot uses a result fixture; move/time expiry is tested separately.
9. Blockers and later worlds: distinct art, blocker states, and readable objectives.
10. Special showcase and activation: actual combined-power resolution and bounded effects.
11. Basket and final time trial: visible objective markers and live counters.
12. Landscape: goals and counters stay beside the board without overflow.

See [the screenshot index](screenshots/README.md). Screenshots demonstrate visual state; they do not establish full accessibility compliance or hardware frame rates. The campaign checks exercise deterministic sessions and terminal states, rather than proving that every level can be won by every strategy. No physical Android device was connected for this review.

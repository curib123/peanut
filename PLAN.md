# Puff & Crunch Development Plan

## Product and technical constraints

Build an original, offline tropical-bakery match-3 game in Flutter using Flame, Riverpod, GoRouter, Shared Preferences, Flame Audio, Flutter SVG, and JSON content packs. Game rules remain pure Dart and independent of rendering. The default board is 8x8, deterministic seeds are supported, repetitive assets and levels are produced by scripts, and no commercial game names, artwork, sounds, characters, interfaces, maps, or level designs may be copied.

Worlds, levels, piece pools, goals, blockers, tutorials, themes, and scheduled events must be data-driven and identified by stable string IDs. Routine content updates using existing mechanics must not require board-engine or screen changes. Content files are versioned and validated; genuinely new mechanics use registered handlers while their balancing remains data-driven.

Regular pieces are Peanut, Egg, Sugar Crystal, Caramel Ribbon, Coconut Cream, and Cocoa Crumb. Special pieces are Sugar Beam, Golden Recipe Spark, Oven Burst, and Peanut Spinner.

## Phase 0 - Project foundation

Flutter app, dependencies, routing, theme constants, feature/domain/rendering structure, basic themed home screen, and test setup.

Acceptance: app launches; navigation and theme work; tests compile; `flutter analyze` and `flutter test` pass.

## Phase 1 - Pure Dart match-3 engine

Board/cell/position/piece models; orthogonal swaps; match grouping including intersections; move validation; deterministic playable board generation; gravity, refill, cascades, dead-board detection, and shuffle.

Acceptance: no Flame dependency in the domain; focused tests cover horizontal, vertical, multiple and intersecting matches, valid/invalid swaps, gravity, refill, cascades, starting boards, and shuffle; 1,000 generated boards are playable; cascades terminate.

## Phase 2 - Basic Flame gameplay

Game and board components, piece rendering, tap/swipe input, valid and invalid swap animation, removal, falling, refill, and resolution input lock.

Acceptance: a full turn is playable; visual/domain state remains synchronized; locked input cannot interrupt resolution; an 8x8 board is smooth; analyzer and tests pass.

## Phase 3 - Special pieces

Create and activate Sugar Beams from four-piece lines, Golden Recipe Sparks from five-piece lines, Oven Bursts from T/L matches, and Peanut Spinners from 2x2 squares. Implement Beam+Beam, Beam+Burst, Burst+Burst, Spark+regular, Spark+Beam, Spark+Burst, Spark+Spark, and Spinner+special combinations.

Acceptance: every special and combination has tests, activates only once, and terminates safely through cascades.

## Phase 4 - Objectives and blockers

Goals: score, collect pieces, clear frosting, break crates, drop recipe baskets, spread cream, and light ovens. Blockers: Sugar Frosting, Peanut Crates, Sticky Caramel, Chocolate Crumbs, Oven Stones, and Baker's Twine.

Acceptance: progress, victory, and move-limit failure are correct; every goal and blocker is tested with normal and special clears.

## Phase 5 - Screens and progress

Splash, home, map, pre-level, gameplay, pause, victory, failure, and settings. Versioned local saving covers unlocked level, stars, best scores, boosters, audio, haptics, reduced motion, migrations, and confirmed reset.

Acceptance: progress/settings survive restart; unlocks and best scores work; reset requires confirmation.

## Phase 6 - Original asset pipeline

Create `tool/generate_svg_assets.dart` and `tool/generate_sfx.py` for all pieces, specials, blockers, boosters, buttons, stars, goals, backgrounds, basic characters, and sound effects. Style: soft rounded 3D vectors, tropical bakery palette, cream backgrounds, brown text, gold buttons, clear silhouettes.

Acceptance: all assets are original, declared, valid, load safely, and audio can be disabled.

## Phase 7 - Ten-level vertical slice

JSON Levels 1-10 form Sunrise Bakery, progressively introducing swaps, cascades, collections, frosting, Sugar Beam, irregular cells, objective play, layered frosting, mixed goals, and a finale.

Acceptance: all load, tutorials work, difficulty rises gradually, levels are completable, and every opening board has no match and at least one move.

## Phase 8 - Level expansion

Expand to 60 launch levels across Sunrise Bakery, Peanut Grove, Egg Cloud Kitchen, Sugar Harbor, Festival Oven, and Starlight Bake-Off. The catalog remains open-ended for later worlds and events. Add `tool/validate_levels.dart` for schema, dimensions, cells, goals, moves, blockers, spawn weights, stars, tutorial moves, and opening boards.

Acceptance: 60 valid JSON levels exist; all openings are playable; Levels 11-60 pass simulations; milestones are manually tuned.

## Phase 9 - Animation and audio polish

Selection pulse, swap/shake, squash/pop, landing bounce, cascade messages, particles, blocker effects, move bonus, star fill, unlock celebration, original audio, haptics, and reduced-motion alternatives.

Acceptance: presentation never changes domain results; motion/audio settings are respected; particles are bounded; gameplay stays responsive.

## Phase 10 - Testing and release

Run formatting, analyzer, unit/widget/integration tests, debug Android and release web builds, level/asset validation, unresolved TODO search, and at least 10,000 board simulations. Verify Levels 1, 5, 10, a blocker-heavy level, a combination-heavy level, and Level 60.

Acceptance: all checks and builds pass; 60 levels load; saving, reduced motion, and special combinations work; README has setup/build commands; no copyrighted commercial assets are included.

## Final completion checklist

- All phase acceptance criteria pass.
- Complete turns, objectives, blockers, specials, boosters, progression, settings, audio, and accessibility work offline.
- Android and web artifacts build successfully.
- All 60 levels and declared assets validate.
- Documentation, notices, and exact verification results are current.

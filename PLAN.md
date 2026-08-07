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

## Phase 11 - Peanut Kisses-inspired visual enhancement

Rebuild the complete presentation as a modern premium match-3 game. Art style and color are the first priority, followed by board readability, satisfying motion, and interface polish. Use the warm character of the Peanut Kisses palette - peanut gold, bakery cream, cocoa brown, energetic red, toasted orange, and sugar-white highlights - inside an original Puff & Crunch identity. Aim for the dimensional richness, gloss, clarity, depth, and playful polish players expect from leading games such as Candy Crush, without copying any protected artwork, candy shapes, characters, maps, layouts, effects, typography, branding, or trade dress.

### 11.1 - Art-direction approval gate

Before rebuilding screens, use image generation to create original style explorations and contact sheets for the home screen, gameplay board, pieces, specials, blockers, UI controls, and one world background. Establish semantic color tokens, lighting direction, material rules, outline weight, corner language, shadows, highlights, texture, perspective, and typography. Compare the concepts at phone size and approve one cohesive direction before producing the full asset set.

Target style: cheerful polished 2.5D/3D illustration, rounded toy-like volume, appetizing bakery materials, clean silhouettes, controlled glossy highlights, soft ambient shadows, rich depth, modern composition, and strong color separation. Avoid flat programmer art, plain circles, generic clip art, excessive outlines, muddy brown screens, empty cream space, and inconsistent rendering styles.

### 11.2 - Real illustrated game pieces

Remove every letter from normal pieces. Generate and integrate transparent-background production artwork that reads by shape alone:

- Peanut: a recognizable warm roasted peanut shell with friendly curves and textured dimples.
- Egg: a glossy cream-and-gold egg ingredient with a distinct silhouette.
- Sugar Crystal: a faceted translucent crystal with icy blue-white sparkle.
- Caramel Ribbon: a curled amber caramel strip with soft shine and depth.
- Coconut Cream: a white coconut-cream swirl with a coconut-shell accent.
- Cocoa Crumb: a rich cocoa cookie/crumb cluster with an irregular crunchy silhouette.

Every piece needs a consistent camera angle, lighting direction, footprint, padding, shadow, highlight, saturation, and transparent edge treatment. Provide selected, matched, falling, disabled, and reduced-motion presentation states without adding text labels. Pieces must remain distinguishable in grayscale and for common color-vision deficiencies.

### 11.3 - Specials, blockers, goals, and boosters

Generate visually unmistakable original artwork for Sugar Beams in both orientations, Golden Recipe Spark, Oven Burst, Peanut Spinner, Sugar Frosting layers, Peanut Crates, Sticky Caramel, Chocolate Crumbs, Oven Stones, Baker's Twine, recipe baskets, cream, ovens, every goal icon, and all boosters. Specials should feel more luminous and energetic than normal pieces; blockers must clearly show their remaining layers or state through visible damage and material changes rather than letters or counters alone.

Add purpose-built effect assets for glints, trails, crumbs, sugar dust, caramel splashes, impact rings, beam sweeps, special combinations, collection flights, blocker damage, star fills, unlocks, and victory celebrations. Effects must stay bounded and have reduced-motion alternatives.

### 11.4 - Board and gameplay interface

Replace the plain board with a dimensional bakery tray that has readable cells, subtle depth, soft inset shadows, valid-cell masks, blocker layering, selection glow, swap feedback, hint treatment, and clear inactive holes. Keep the art behind pieces quiet enough for instant move recognition.

Redesign the gameplay HUD into compact polished goal, score, move, booster, pause, and progress components. Remove large empty areas, fix narrow-phone app-bar crowding, keep the board prominent, and make tutorial prompts helpful without covering play. Redesign pause, victory, failure, move-bonus, star-fill, and unlock overlays with premium illustrated panels and responsive animations.

### 11.5 - Complete modern UI system

Redesign the splash, home, settings, world map, level nodes, world headers, pre-level goals, booster selection, gameplay, dialogs, loading, empty, locked, victory, and failure states. Replace generic Material defaults with an original cohesive component kit: dimensional buttons, cards, tabs, toggles, badges, counters, progress bars, stars, icons, modal frames, and navigation controls.

Use bold rounded readable typography, clear hierarchy, consistent spacing, minimum 48-pixel touch targets, WCAG AA contrast where applicable, safe-area handling, and responsive layouts for small phones through tablets. Interaction states must include normal, pressed, selected, disabled, focused, locked, loading, and success feedback.

### 11.6 - AI-generated world artwork

Generate original layered backgrounds, map scenery, decorative props, landmarks, and loading art for Sunrise Bakery, Peanut Grove, Egg Cloud Kitchen, Sugar Harbor, Festival Oven, and Starlight Bake-Off. Each world needs a distinct palette, atmosphere, landmark, path treatment, and level-node decoration while sharing the master art direction. Backgrounds must support responsive cropping, foreground/midground/background parallax where appropriate, and readable UI placement.

Generate original character and mascot poses for welcome, tutorial, celebration, concern, victory, and failure. Do not use the Peanut Kisses logo, packaging, mascot, proprietary product illustrations, or any Candy Crush assets or recognizable copies.

### 11.7 - Asset production and integration

Create an inventory and naming specification before generation. Produce high-resolution master images, then export optimized runtime WebP/PNG assets at required densities with transparency, safe padding, deterministic filenames, and source prompts recorded for reproducibility. Remove obsolete placeholder assets only after every reference has migrated. Provide safe fallbacks and precache critical gameplay assets so pieces never appear late or blank.

Integrate the artwork into real components; no sample-only mockups. Preserve all gameplay logic, hit boxes, deterministic results, save compatibility, audio settings, and accessibility behavior. Measure memory, decode time, frame pacing, package-size impact, and particle counts on representative low-end settings.

### 11.8 - Review and release acceptance

Capture matching before/after screenshots at common phone and tablet sizes for every primary state. Review the complete app for art consistency, cropping, text overflow, safe areas, contrast, color-blind readability, touch size, animation pacing, reduced motion, loading behavior, and asset fallbacks. Manually inspect Levels 1, 10, 30, and 60 with normal pieces, blockers, goals, and special combinations visible.

Acceptance: no letters or placeholder geometry remain on pieces; all normal pieces, specials, blockers, goals, boosters, characters, effects, backgrounds, and major UI surfaces use the approved original art direction; all six worlds are distinct and cohesive; the board is instantly readable; narrow-phone crowding and empty-space problems are resolved; touch targets and contrast meet requirements; reduced motion remains complete; assets load without flashes or missing images; gameplay results and saves are unchanged; analyzer and all tests pass; Android release and web builds succeed; and the final screenshot set is approved against the Phase 10 baseline.

## Final completion checklist

- All phase acceptance criteria pass.
- Complete turns, objectives, blockers, specials, boosters, progression, settings, audio, and accessibility work offline.
- Android and web artifacts build successfully.
- All 60 levels and declared assets validate.
- Documentation, notices, and exact verification results are current.
- Phase 11 visual-direction, accessibility, screenshot, and release-build acceptance criteria pass.

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

### 11.9 - Phase 12 capture-readiness

Build Phase 11 so every important visual and interaction state can be reproduced on demand instead of waiting for random gameplay. Add development-only capture fixtures or deterministic routes for fresh progress, advanced progress, locked/unlocked/completed nodes, every piece and special, blocker layers, goals, booster states, tutorials, low moves, shuffle, pause, victory, failure, star awards, unlocks, loading, offline, and asset-fallback behavior. Keep fixtures outside production behavior and ensure they cannot alter real saves.

Create stable screenshot viewport presets and a short-tour capture workflow for common phone and tablet sizes. Record Phase 11 baseline measurements for startup, asset precache, image decoding, board frame pacing, peak texture memory, package size, and reduced-motion behavior. Maintain an asset inventory containing runtime path, purpose, owning component, master source, generation prompt/reference, dimensions, format, file size, transparency, fallback, and preload priority. These outputs become direct evidence for Phase 12 rather than requiring the audit to reconstruct missing context.

### 11.10 - Phase 13 adventure-readiness

Do not bake world artwork into single inflexible screenshots. Author every world with reusable, separable foreground, midground, background, landmark, transition, path, node, atmosphere, and optional loop layers. Define safe crop zones, overlap margins, anchor points, horizon/perspective guides, scroll extents, parallax depth values, static reduced-motion frames, and color-transition rules. Produce adjacent-world transition studies so Phase 13 can connect the six regions into one continuous vertical journey without regenerating the complete art set.

Refactor visual components around reusable semantic primitives instead of screen-specific coordinates: `WorldSection`, `LevelNode`, `RouteSegment`, `WorldGate`, `Landmark`, `AmbientLayer`, `GoalBadge`, `RewardMarker`, and responsive illustrated panels. Keep level order, lock state, stars, current position, and navigation driven by saved domain data. The Phase 11 level map may remain functionally simple, but its assets and components must already support virtualization, offscreen culling, restored scroll position, appendable future worlds, parallax offsets, and animation pause/resume hooks.

Reserve performance budgets for the later journey: critical gameplay pieces and UI load first; world scenery loads by region; loops are optional enhancements; no full-resolution master is shipped when a smaller runtime export is sufficient. Establish one shared motion policy covering normal, reduced-motion, battery-conscious, offscreen, paused, and unsupported-codec states. Phase 13 must be able to add a cinemagraph or seamless loop without changing progression logic or losing a static fallback.

### 11.11 - Required handoff package

Phase 11 is not complete until it hands Phase 12 and Phase 13:

- Approved art-direction board, color tokens, typography, lighting/material rules, and UI component sheet.
- Final normal-piece, special, blocker, goal, booster, character, effect, and UI asset inventories.
- Six world style boards plus connected transition concepts and separated layer specifications.
- Deterministic capture fixtures, viewport matrix, baseline screenshots, and short-tour recording workflow.
- Performance, memory, package-size, accessibility, and reduced-motion baselines.
- Asset provenance, generation prompts/references, licenses/ownership notes, masters, runtime exports, and fallback mapping.
- A component/API map showing how progression data drives nodes, routes, world gates, landmarks, and ambient layers.
- Known limitations and deliberately deferred work, explicitly routed into the Phase 12 audit or Phase 13 implementation backlog.

Acceptance: no letters or placeholder geometry remain on pieces; all normal pieces, specials, blockers, goals, boosters, characters, effects, backgrounds, and major UI surfaces use the approved original art direction; all six worlds are distinct and cohesive; the board is instantly readable; narrow-phone crowding and empty-space problems are resolved; touch targets and contrast meet requirements; reduced motion remains complete; assets load without flashes or missing images; gameplay results and saves are unchanged; analyzer and all tests pass; Android release and web builds succeed; the final screenshot set is approved against the Phase 10 baseline; deterministic capture fixtures and measurement baselines are ready for Phase 12; and the layered assets, reusable components, transition studies, fallbacks, provenance, and handoff documents are sufficient for Phase 13 to build the connected vertical adventure without redoing Phase 11.

## Phase 12 - Capture, analysis, and enhancement audit

Capture the complete working game after Phase 11 and analyze what still needs to be added, enhanced, simplified, or fixed before the final adventure presentation. This is an evidence-gathering and prioritization phase: do not hide defects with mockups, and do not mark an item complete without checking the real running Android/web experience.

### 12.1 - Complete state capture

Create reproducible phone and tablet captures for splash, home, settings, every world section, locked/unlocked/completed level nodes, pre-level goals, booster selection, first-time tutorials, standard gameplay, every normal piece, every special, special combinations, each blocker and damage layer, pause, shuffle, low moves, victory, failure, star awards, unlock celebration, reset confirmation, loading, offline, empty, and error/fallback states.

Record both still screenshots and short interaction clips. Include representative Levels 1, 5, 10, 20, 30, 40, 50, and 60; small and large screens; fresh and advanced saves; sound/haptics on and off; reduced motion; and at least one sustained session that moves from the adventure map into gameplay and back with a newly unlocked level.

### 12.2 - Visual and interaction analysis

Review every capture for hierarchy, composition, art consistency, palette, contrast, legibility, world identity, cropping, safe areas, typography, text overflow, button states, touch targets, board readability, goal clarity, blocker state clarity, animation timing, effect density, audio/visual synchronization, loading flashes, empty space, visual repetition, frame pacing, memory use, and package-size impact.

Compare the experience with the quality expectations of leading polished match-3 games while evaluating Puff & Crunch on its own original art, mechanics, characters, terminology, and layouts. Do not copy screenshots or reproduce a competitor's exact interface.

### 12.3 - Gameplay and progression analysis

Audit onboarding, difficulty curve, objective explanations, move pressure, booster discovery, special-combination teaching, retry flow, reward feedback, star thresholds, level unlock visibility, world transitions, return-to-map position, save recovery, and the sense of forward adventure. Identify missing content and unclear mechanics as well as bugs.

### 12.4 - Evidence-backed backlog

Create a Phase 12 review report with annotated captures and one prioritized backlog. Each item must include evidence, affected screen/level, severity, player impact, proposed correction, dependency, validation method, and status. Sort into:

1. Critical functional defects and data-loss risks.
2. Gameplay readability and accessibility blockers.
3. Performance, loading, memory, and package-size problems.
4. Progression, onboarding, and navigation friction.
5. Art inconsistency and missing assets/states.
6. Animation, audio, haptic, and delight improvements.
7. Optional future content and retention ideas.

Acceptance: the capture set covers every required state and representative level; Android and web are both reviewed; defects are reproducible; every recommendation links to visible evidence; accessibility and performance measurements are recorded; the backlog has an explicit priority/order; quick fixes made during the audit have regression tests; analyzer/tests/builds pass; and Phase 13 receives a clear approved input specification rather than assumptions.

## Phase 13 - AI-generated vertical world adventure

Transform the home/progression experience into a premium vertically scrolling adventure journey. The level journey becomes the main home experience: players open directly into a living connected world map, see their current location and next goal immediately, scroll through completed and upcoming levels, and watch the route continue naturally into newly unlocked worlds.

Use the sense of discovery, layered depth, clarity, and reward pacing associated with polished map-based match-3 adventures such as Candy Crush as a quality reference only. Create original Puff & Crunch geography, level-node shapes, landmarks, paths, characters, props, compositions, colors, animations, and interface components; do not copy competitor maps, layouts, icons, characters, world themes, or artwork.

### 13.1 - Vertical journey structure

Replace the plain level grid and separate static home with one responsive vertical journey containing all 60 launch levels. Arrange levels along a readable winding path with visible connections, completed stars, current-level emphasis, locked states, milestone nodes, reward moments, world gates, and clear forward direction. Preserve direct settings access and provide a compact persistent status area without obscuring the journey.

Opening the journey restores the player's previous scroll position unless a level or world was just unlocked. After victory, return to the completed node, animate earned stars and rewards, extend the route, unlock the next node, and automatically reveal the new destination without disorienting the player. World transitions must feel continuous rather than like unrelated grids.

### 13.2 - Connected world design

Join Sunrise Bakery, Peanut Grove, Egg Cloud Kitchen, Sugar Harbor, Festival Oven, and Starlight Bake-Off into one coherent island adventure. Each ten-level region needs an original entrance, exit, landmark, path material, terrain, vegetation/props, atmospheric palette, and transition zone that visually blends into the next region. Use landmark levels and gates to signal major progression moments.

Design the content architecture so later permanent and event worlds can append above the existing journey without renumbering saves or rebuilding the entire map. Locked future regions may be teased honestly but must not imply playable content that does not exist.

### 13.3 - AI-generated environmental artwork

Use image generation to create original high-resolution master art for each world's background, transition scenes, landmarks, foreground decorations, clouds, particles, ambient creatures, bakery props, and celebratory moments. Produce a shared art-direction sheet and connected map storyboard before final generation so perspective, scale, lighting, horizon, path alignment, and color transitions remain consistent across world boundaries.

Split approved masters into optimized foreground, midground, and background layers with safe overlap and responsive crop zones. Record prompts, seeds/reference inputs when available, asset ownership notes, source dimensions, export settings, and runtime filenames. Export efficient WebP/PNG layers and sprite sheets; retain working masters outside the runtime bundle when they are not needed by the app.

### 13.4 - Parallax, cinemagraph, and looping life

Give each region a subtle living environment using bounded layered parallax and seamless AI-assisted looping elements. Candidate motion includes drifting clouds, moving oven glow, sparkling sugar, swaying palms, floating flour dust, harbor water shimmer, festival lights, distant steam, and starlight twinkle. Prefer small isolated loops, sprite atlases, shader effects, or lightweight encoded clips over animating an entire full-resolution screen.

Loops must be seamless, quiet behind UI, free of visible AI morphing, and tested at their loop boundary. Pause offscreen worlds and application-background motion, cap simultaneous animated layers, precache the next region, and provide static poster-frame alternatives for reduced motion, battery saver, unsupported web codecs, slow devices, and asset failures. Ambient audio must respect the existing music/sound settings.

### 13.5 - Adventure interaction and UI

Create polished original nodes, star plaques, world ribbons, gates, route segments, treasure/reward markers, avatar position, current-level beacon, locked overlays, progress counters, and scroll controls. Add a reliable "return to current level" control and semantic labels for accessible navigation. Node hit areas must remain at least 48 logical pixels even when artwork is visually smaller.

Use restrained depth reactions while scrolling: foreground drift, landmark reveal, subtle character response, node pulse, route illumination, and world-gate celebration. Do not let motion fight scrolling or obscure level state. Reduced motion replaces travel/reveal animation with immediate positioning and short opacity changes.

### 13.6 - Performance, validation, and release

Virtualize/cull offscreen map sections, avoid decoding all world masters at startup, bound texture memory, reuse loop controllers, and test fast scrolling between the bottom and top of the journey. Measure first meaningful paint, time to current-level positioning, scroll frame pacing, peak memory, image decode spikes, bundle growth, and battery-sensitive animation behavior on Android and web.

Acceptance: the journey is the primary home/progression surface; all 60 nodes form one clear connected vertical route; each world is original, recognizable, and blends into the next; winning reveals the next level/world correctly; return position and save compatibility work; AI-generated backgrounds and loops have recorded provenance and optimized fallbacks; parallax/loops are seamless and pause when offscreen; reduced motion uses static alternatives; map scrolling remains responsive on target phone and web sizes; no copied commercial artwork or layout is included; annotated screenshots and a short journey video are approved; analyzer/tests pass; and Android release and web builds succeed.

## Final completion checklist

- All phase acceptance criteria pass.
- Complete turns, objectives, blockers, specials, boosters, progression, settings, audio, and accessibility work offline.
- Android and web artifacts build successfully.
- All 60 levels and declared assets validate.
- Documentation, notices, and exact verification results are current.
- Phase 11 visual-direction, accessibility, screenshot, and release-build acceptance criteria pass.
- Phase 12 capture coverage, analysis report, prioritized backlog, and regression evidence are complete.
- Phase 13 connected vertical journey, AI-generated environments, looping fallbacks, performance targets, and release checks pass.

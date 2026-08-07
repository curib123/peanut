# Architecture

## Structure

```text
lib/
  app/                 application shell and routes
  core/theme/          shared visual constants
  features/            screen-oriented presentation and state
  game/domain/         pure Dart match-3 rules
  game/presentation/   Flame components, input, and animation
  services/            persistence and audio boundaries
assets/levels/         JSON level definitions
assets/content/        versioned world and event manifests
tool/                  deterministic generators and validators
test/                  unit and widget tests
integration_test/      end-to-end flows
```

Directories are added when their phase introduces real implementation; empty placeholder files are avoided.

## Boundaries and state ownership

The domain layer owns board truth, moves, matches, cascades, scoring, goals, blockers, content validation, and deterministic randomness. It imports neither Flutter nor Flame. Flame renders immutable domain snapshots and forwards intent; it does not decide outcomes. Riverpod owns app-level progress, selected level, active content snapshot, settings, booster inventory, and service wiring. GoRouter owns screen navigation.

## Rendering and resolution flow

Input is converted to an adjacent swap request. `TurnEngine` validates and resolves the move into immutable frames: swap, matched positions, removal snapshot, gravity snapshot, refill snapshot, and repeats until stable. The Flame layer uses `TurnInputGate` to reject concurrent input, animates those frames in order, synchronizes to the final snapshot, then unlocks input even if animation fails. A stable dead board is shuffled by the domain.

`SpecialResolver` is the single authority for special creation, activation expansion, and pair combinations. It returns a set of cleared cells, created pieces, and uniquely activated origins; it never animates. `TurnEngine` folds that plan into the normal bounded cascade frames. This prevents duplicate activation and lets later objectives provide a higher-priority target selector for Peanut Spinner without coupling special rules to Flame.

`LevelSession` owns the move limit, accumulated score, goal tracker, blocker grid, and board objectives. It consumes `TurnEngine` frames to count collected pieces and apply normal/special damage without recomputing matches. Hard blockers are passed into gravity, refill, shuffle, and swap validation as blocked positions. Goal and blocker factories map stable content IDs to tested handlers, keeping target counts, layers, layouts, and combinations in level data.

## Save data

`SharedPreferencesSaveRepository` stores one versioned JSON document. `ProgressController` is the Riverpod source of truth for the highest unlocked level, stars and best score by level, open-ended booster inventory, and sound/music/haptic/reduced-motion settings. Parsing clamps corrupt values and uses safe defaults; version-1 flat settings migrate into the version-2 nested settings object. Unknown future save versions reset safely rather than being interpreted incorrectly.

Completing the current highest unlocked level opens exactly the next level. Replays may improve stars and best score but never reduce either. Settings and booster mutations save immediately. Progress reset removes the stored document only after UI confirmation.

## Application flow

Splash waits for local state before routing to Home. Home opens the world/level map, locked levels have disabled controls, and an unlocked level opens a pre-level goal panel before gameplay. Gameplay owns Flutter pause/victory/failure overlays around Flame, persists winning results, and uses reduced-motion settings to shorten animation timing. Settings exposes all persistent accessibility/audio controls and confirmed reset.

Gameplay presentation consumes immutable `TurnResolution` frames: pieces swap, invalid moves return with a shake, cleared pieces pop into a bounded five-particle burst, refills land with squash, and multi-step turns announce their cascade count. These effects never calculate board state. The session adds a deterministic 100-point bonus for each unused move after goals complete. Original synthesized WAV cues and platform haptics are failure-safe and obey saved settings; reduced motion keeps short positional continuity while removing looping pulse, particles, shake, and bounce.

## Levels

## Extensible content system

`GameContentCatalog` parses a versioned content pack into worlds, levels, and scheduled events. Stable string IDs replace closed enums for content-facing types. A level controls board dimensions, deterministic seed, weighted piece pool, move limit, goals, blockers, star thresholds, and metadata. `MechanicDefinition` carries a handler ID plus arbitrary validated parameters, allowing existing goals, blockers, and event modifiers to be recombined without engine changes.

At a given UTC time, the catalog creates an immutable snapshot containing base content plus active event worlds and levels. IDs and references are validated before use. Updates can append content packs; they cannot mutate an active board. New balance/content uses JSON only. A genuinely new rule requires one registered domain handler and tests, then becomes reusable from any later pack.

JSON files may be split by world/event for authoring and combined into the catalog by the repository layer. They define dimensions, playable cells, goals, move limit, blockers, spawn weights, star thresholds, and optional tutorial moves. Loading validates schema before domain board generation. Seeds make tests and simulations repeatable.

`BundledLevelRepository` loads each Sunrise Bakery JSON recipe independently, so later patches can replace or append levels without changing screens or the engine. `IslandMatchGame` builds its session from the loaded definition. Cells excluded by `playableCells` are immutable holes shared by swap validation, gravity, refill, and shuffle; tutorial content is presented by both the pre-level panel and gameplay overlay.

The repository resolves all 60 launch levels through world-based asset paths while retaining an open numeric range in saved progress. `tool/generate_launch_levels.dart` reproducibly authors Levels 11-60, and `tool/validate_levels.dart` independently checks file order, schema, mechanics, tutorials, masks, openings, and bounded turn resolution. Goal cell parameters initialize baskets, cream, and ovens without adding screen-specific rules.

## Phase 11 presentation assets

AI-generated runtime art is isolated from domain logic. `PieceComponent` resolves a stable piece/special ID to a preloaded transparent sprite and falls back to text-free geometry on asset failure. `BoardComponent` renders the bakery tray and blocker sprite layer from the session's live `BlockerGrid`; turn resolution remains authoritative. Flutter screen layers choose the world background from the numeric level without changing content or save data. The connected map reads only unlock/star state from `ProgressController`, so later parallax and virtualization work can replace its composition without migrating progression.

Static piece and blocker PNGs are animated by reusable Flame presentation components: breathing/bob and movement tweens, alpha-clipped gradient shine, bounded particles, and an eight-frame AI-generated match-burst sprite sheet. Reduced-motion mode freezes decorative loops and uses a brief static burst frame without changing gameplay timing or state.

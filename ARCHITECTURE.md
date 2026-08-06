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

## Save data

Shared Preferences stores a versioned JSON document containing the highest unlocked level, stars and best score by level, booster inventory, sound/music/haptic/reduced-motion settings, and save version. Parsing uses safe defaults; explicit migrations upgrade older versions.

## Levels

## Extensible content system

`GameContentCatalog` parses a versioned content pack into worlds, levels, and scheduled events. Stable string IDs replace closed enums for content-facing types. A level controls board dimensions, deterministic seed, weighted piece pool, move limit, goals, blockers, star thresholds, and metadata. `MechanicDefinition` carries a handler ID plus arbitrary validated parameters, allowing existing goals, blockers, and event modifiers to be recombined without engine changes.

At a given UTC time, the catalog creates an immutable snapshot containing base content plus active event worlds and levels. IDs and references are validated before use. Updates can append content packs; they cannot mutate an active board. New balance/content uses JSON only. A genuinely new rule requires one registered domain handler and tests, then becomes reusable from any later pack.

JSON files may be split by world/event for authoring and combined into the catalog by the repository layer. They define dimensions, playable cells, goals, move limit, blockers, spawn weights, star thresholds, and optional tutorial moves. Loading validates schema before domain board generation. Seeds make tests and simulations repeatable.

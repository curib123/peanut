# Phase 13 World Adventure

Phase 13 turns the 120-level map into one continuous six-world journey without changing match-3 rules or save compatibility.

## Delivered

- The map automatically switches to each world's AI-generated scene as the player reaches its 20-level section.
- Backgrounds move at a slower rate than the level path to create depth while scrolling.
- Every scene has a subtle 14-second seamless ambient drift and a looping field of warm floating lights.
- World changes cross-fade instead of cutting abruptly.
- Each world ribbon has a distinct landmark icon while the connected path continues through all 120 levels.
- Reduced Motion disables the ambient animation through Flutter's ticker system.
- World images, level ranges, names, music, and ordering remain catalog-driven, so adding a world does not require a new map screen.

## Art direction

The implementation deliberately reuses the six existing AI-generated world paintings. This preserves the established Peanut Kisses-inspired palette and makes the level map, pre-level screen, gameplay background, and world music feel like the same place.

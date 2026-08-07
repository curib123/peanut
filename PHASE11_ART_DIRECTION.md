# Phase 11 Art Direction and Asset Provenance

## Approved direction

Puff & Crunch uses an original premium 2.5D bakery-adventure style: rounded toy-like volume, recognizable ingredient silhouettes, upper-left studio lighting, controlled gloss, warm ambient shadows, rich but readable materials, and strong separation at small gameplay sizes. The core palette is peanut gold, bakery cream, cocoa brown, caramel orange, energetic coral-red, sugar blue, and restrained white highlights.

Candy Crush and other leading match-3 games are quality references for clarity, depth, polish, and feedback only. No commercial artwork, map, candy silhouette, character, interface layout, logo, typography, or effect was copied.

## Built-in image generation

All Phase 11 raster artwork was created with OpenAI's built-in image-generation tool. The runtime files are project-bound under `assets/images/`; chroma-key sources were processed with the installed imagegen skill helper and Pillow. Transparent sheets were split and normalized by `tool/process_phase11_assets.py`; the world sheet was split by `tool/split_world_sheet.py`.

### Ingredient prompt

Six isolated production sprites in a 3x2 grid: roasted peanut, glossy egg, faceted sugar crystal, caramel ribbon, coconut-cream swirl, and cocoa crumb cluster. Premium original 2.5D mobile-game rendering, consistent camera/light, no letters/faces/logos, flat green chroma background, readable at 64 pixels.

Runtime outputs: `assets/images/pieces/*.png` (384x384 RGBA).

### Special prompt

Original magical bakery specials: horizontal and vertical Sugar Beams, Golden Recipe Spark, Oven Burst, and Peanut Spinner. Luminous polished 2.5D rendering, no words/logos, flat green chroma background.

Runtime outputs: `assets/images/specials/*.png` (384x384 RGBA).

### Blocker prompt

Six tactile obstacles: layered Sugar Frosting, Peanut Crate, Sticky Caramel, Chocolate Crumbs, Oven Stone, and Baker's Twine. Cohesive damage-ready material rendering, shape-readable without text, flat green chroma background.

Runtime outputs: `assets/images/blockers/*.png` (384x384 RGBA).

### Environment prompts

One high-resolution portrait bakery-island adventure master plus a consistent six-world 3x2 environment sheet: Sunrise Bakery, Peanut Grove, Egg Cloud Kitchen, Sugar Harbor, Festival Oven, and Starlight Bake-Off. Each uses an original winding path, distinct atmosphere, shared camera language, and text-free safe areas for game UI.

Runtime outputs: `assets/images/worlds/sunrise_adventure.png` and six optimized WebP world scenes.

## Runtime rules

- Critical piece and special sprites preload before the Flame board mounts.
- Missing piece art falls back to text-free colored geometry; gameplay never depends on image loading.
- World art uses cover cropping and a readability gradient.
- Blockers are separate prioritized components and refresh after domain resolution.
- Reduced motion continues to remove pulse, particles, shake, and bounce; background art remains static.
- Generated masters are not required at runtime. Optimized exports and prompts are sufficient to reproduce the pipeline.

## Phase 12/13 handoff

The deterministic capture workflow remains `tool/capture_screenshots_test.dart`. Phase 10 screenshots are the before baseline; regenerated files in `docs/screenshots/` are the Phase 11 after state. The six separated world scenes, vertical path component structure, semantic saved progression, and static backgrounds are ready for the Phase 12 audit and Phase 13 parallax/loop expansion.

Known deferred items for Phase 12 evidence: scripted victory/failure capture fixtures, automated color-vision image comparison, device-side GPU memory telemetry, and encoded cinemagraph loops. These do not affect Phase 11 gameplay or asset integration.

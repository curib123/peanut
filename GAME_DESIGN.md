# Game Design

## Identity

Puff & Crunch: Island Match is an original offline match-3 game set in a cheerful tropical bakery. It uses familiar genre mechanics without copying commercial names, assets, characters, interfaces, maps, sounds, or levels.

## Pieces and matching

The six regular pieces are Peanut, Egg, Sugar Crystal, Caramel Ribbon, Coconut Cream, and Cocoa Crumb. Players swap orthogonally adjacent pieces using taps or swipes. Lines of three or more clear, then gravity, refill, and cascades resolve before input returns. Opening boards contain no matches and at least one valid move; dead boards shuffle.

## Special pieces

- Sugar Beam: four in a line; clears its horizontal or vertical line.
- Golden Recipe Spark: five in a line; swapped with a regular piece to clear that type.
- Oven Burst: T or L match; clears a large nearby area.
- Peanut Spinner: 2x2 match; targets an important objective and clears near arrival.

Special-to-special combinations amplify and combine these effects as specified in `PLAN.md`. Beam+Beam clears crossed lines; Beam+Burst clears three-row and three-column bands; Burst+Burst clears a larger area; Spark combinations apply the partner effect across the selected ingredient type; Spark+Spark clears the board; Spinner+special targets and activates its partner. Each special origin activates at most once per resolution chain.

## Objectives and blockers

Objectives include target score, collecting pieces, clearing frosting, breaking crates, dropping recipe baskets, spreading cream, and lighting ovens. Blockers are Sugar Frosting, Peanut Crates, Sticky Caramel, Chocolate Crumbs, Oven Stones, and Baker's Twine.

## Boosters

Launch boosters will provide limited, explicitly selected help before or during a level. Exact inventory balance and effects will be finalized with the ten-level vertical slice.

## Scoring and progression

Matches, cascades, specials, and completed objectives award score. Each level has a move limit and three ascending star thresholds. Completing goals before moves reach zero wins; otherwise the level fails. Stars, best scores, unlocked levels, and booster inventory persist locally.

## Worlds

The launch set has six worlds of ten levels each: Sunrise Bakery, Peanut Grove, Egg Cloud Kitchen, Sugar Harbor, Festival Oven, and Starlight Bake-Off. This is not a fixed ceiling. Later updates may add permanent worlds or time-bounded event worlds through versioned content packs. The first ten levels introduce mechanics gradually before the remaining launch worlds are authored.

## Live events

Events have stable IDs, UTC start/end times, optional event worlds and levels, and parameterized modifiers. Expired content is removed from the active catalog snapshot without deleting earned progress. Existing mechanics can be mixed and rebalanced entirely in data; new rule types must be registered and tested before a pack references them.

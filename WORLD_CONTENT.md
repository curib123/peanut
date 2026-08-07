# Adding Worlds, Backgrounds, and Music

World presentation is configured in `assets/content/worlds.json`. Flutter screens do not contain a switch statement for world artwork or music.

To add a world:

1. Add one entry to `worlds.json` with a unique `id`, display `name`, ordering number, non-overlapping `firstLevel` and `lastLevel`, background asset, and music filename.
2. Place the background under `assets/images/worlds/` and the seamless WAV loop under `assets/audio/music/`.
3. Add the world's level JSON files under `assets/levels/<world_id>/` and declare that new level directory in `pubspec.yaml`.

The level repository locates the correct folder from the configured level range. The map expands to the catalog's highest level, inserts the world ribbon at `firstLevel`, and gameplay selects the configured background and looping music from the level's world ID.

The `main` object independently controls the home/map background and main theme. Music obeys the persisted Music setting, switches only when the requested track changes, loops through Flame Audio's BGM player, and fails silently when audio hardware is unavailable.

Run `python tool/generate_music.py` to reproduce the seven original 16-second mono loops currently shipped with the game.

# Dusk Horde

A solo, mobile (Android first), pixel-art horror wave-survival shooter. Every level is a different end of the world: a zombie outbreak first, an alien invasion next, more apocalypses later.

Built with [Flutter](https://flutter.dev) + [Flame](https://flame-engine.org), maps made in [Tiled](https://www.mapeditor.org).

## Run it

```bash
flutter pub get
flutter run          # with an Android phone plugged in (USB debugging on) or an emulator
flutter test
```

## Layout

| Path | What lives there |
| --- | --- |
| `lib/main.dart` | App entry: landscape lock, full screen, starts the game |
| `lib/game/dusk_horde_game.dart` | The Flame game: loads a level, runs story or Endless, unlocks |
| `lib/game/levels.dart` | The levels: map file, wave plan, boss. Add an apocalypse here |
| `lib/game/waves/wave_plan.dart` | What each wave holds, per apocalypse (`ZombiePlan`, `AlienPlan`) |
| `lib/game/enemies/` | Enemy data (`enemy_type.dart`) and behaviours (Brute, aliens, the Warden) |
| `lib/game/game_assets.dart` | The single list of every sprite file the game loads |
| `lib/meta/weapon_catalog.dart` | Every gun's base stats, the upgrade tiers and their costs. Tune balance here |
| `lib/meta/perks.dart` | Survivor perks and their costs |
| `lib/meta/progress.dart` | What carries over between runs (scrap, cores, unlocks, tiers, perks), saved as JSON |
| `lib/ui/` | Flutter menus: the workbench and the end-of-run panels |
| `assets/images/sprites/` | Placeholder sprites (32 x 32, Brute 48 x 48, Warden 64 x 64, all facing right) |
| `assets/tiles/` | Tiled maps (`.tmx`) and their tileset PNGs. Open `gas_station.tmx` (Level 1) or `crash_site.tmx` (Level 2) in Tiled to edit them |
| `tools/maps/make_gas_station.py`, `make_crash_site.py` | Scripts that made the first version of each map and tileset (edit the maps in Tiled from now on) |
| `tools/art/make_sprites.py` | Script that draws the placeholder sprites (`python3 make_sprites.py`, then copy the PNGs into `assets/images/sprites/`) |

Art is placeholder. To replace a sprite, overwrite its PNG with the same name; no code changes needed.

## Editing the map in Tiled

Keep these layer names, the game finds everything by name:

| Layer | Type | What it holds |
| --- | --- | --- |
| `ground`, `walls` | Tile layers | The art |
| `collision` | Objects (rectangles) | Anything solid. Class `wall` = drawn by the tiles, class `prop` = the game draws a wreck (`name` = `car`, `dumpster` or `debris`) |
| `spawns` | Objects (points) | Where zombies walk in from |
| `pickups` | Objects (points) | Where medkits appear between waves |
| `hives` | Objects (points), optional | Where Brood Pods grow (Crash Site) |
| `markers` | Objects (points) | `player_start` and `supply_crate` |

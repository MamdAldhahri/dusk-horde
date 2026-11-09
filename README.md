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
| `lib/game/dusk_horde_game.dart` | The Flame game |
| `lib/game/game_assets.dart` | The single list of every sprite file the game loads |
| `assets/images/sprites/` | Placeholder sprites (32 x 32, Brute 48 x 48, all facing right) |
| `assets/tiles/` | Tiled maps (`.tmx`) and tilesets, from M3 |
| `tools/art/make_sprites.py` | Script that draws the placeholder sprites (`python3 make_sprites.py`, then copy the PNGs into `assets/images/sprites/`) |

Art is placeholder. To replace a sprite, overwrite its PNG with the same name; no code changes needed.

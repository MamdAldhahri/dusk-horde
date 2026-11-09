import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';

/// A rectangle from the map's `collision` layer. `kind` is the Tiled object
/// class: `wall` (drawn by the tiles) or `prop` (a wreck or dumpster the game
/// draws itself).
class Blocker {
  const Blocker(this.rect, this.name, this.kind);
  final Rect rect;
  final String name;
  final String kind;
}

/// Everything the game needs from one Tiled map. Object layers are found by
/// name, so a map edited in Tiled works as long as it keeps these names:
/// `collision`, `spawns`, `pickups`, `markers` (with `player_start` and
/// `supply_crate` points).
class LevelMap {
  LevelMap._(this.component);

  final TiledComponent component;
  late final Rect bounds;
  final List<Blocker> blockers = [];
  final List<Vector2> spawns = [];
  final List<Vector2> pickups = [];
  late final Vector2 playerStart;
  Vector2? supplyCrate;

  List<Rect> get obstacles => [for (final b in blockers) b.rect];

  static Future<LevelMap> load(String file) async {
    final tiled = await TiledComponent.load(
      file,
      Vector2.all(16),
      images: Images(prefix: 'assets/tiles/'),
      priority: -10,
    );
    final level = LevelMap._(tiled);
    final map = tiled.tileMap.map;
    level.bounds = Rect.fromLTWH(
      0,
      0,
      (map.width * map.tileWidth).toDouble(),
      (map.height * map.tileHeight).toDouble(),
    );

    ObjectGroup? group(String name) =>
        tiled.tileMap.getLayer<ObjectGroup>(name);

    for (final o in group('collision')?.objects ?? const <TiledObject>[]) {
      level.blockers.add(
        Blocker(Rect.fromLTWH(o.x, o.y, o.width, o.height), o.name, o.type),
      );
    }
    for (final o in group('spawns')?.objects ?? const <TiledObject>[]) {
      level.spawns.add(Vector2(o.x, o.y));
    }
    for (final o in group('pickups')?.objects ?? const <TiledObject>[]) {
      level.pickups.add(Vector2(o.x, o.y));
    }
    Vector2? start;
    for (final o in group('markers')?.objects ?? const <TiledObject>[]) {
      if (o.name == 'player_start') start = Vector2(o.x, o.y);
      if (o.name == 'supply_crate') level.supplyCrate = Vector2(o.x, o.y);
    }
    level.playerStart =
        start ?? Vector2(level.bounds.center.dx, level.bounds.center.dy);
    return level;
  }
}

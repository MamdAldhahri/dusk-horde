import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';

import 'fx/flashlight.dart';
import 'game_assets.dart';
import 'hud.dart';
import 'input/virtual_stick.dart';
import 'player/player.dart';
import 'weapons/bullet.dart';
import 'world/arena_floor.dart';
import 'world/training_dummy.dart';

/// M1 scene: a dark lot with training dummies, to tune how moving, aiming,
/// shooting and dodging feel on a phone.
class DuskHordeGame extends FlameGame {
  DuskHordeGame({Random? random}) : random = random ?? Random();

  /// Height of the visible world in game pixels, whatever the phone.
  static const viewHeight = 360.0;

  final Random random;

  /// Playable area in world coordinates, centred on 0,0.
  final Rect arena = const Rect.fromLTRB(-480, -270, 480, 270);

  late final Player player;
  late final BulletPool bullets;
  late final VirtualStick moveStick;
  late final VirtualStick aimStick;
  final List<TrainingDummy> targets = [];

  double _shake = 0;

  @override
  Color backgroundColor() => const Color(0xFF050407);

  @override
  Future<void> onLoad() async {
    await images.loadAll(GameAssets.all);

    bullets = BulletPool(world);
    player = Player();
    world.add(ArenaFloor(arena));
    world.add(player);

    for (final (path, x, y, hp) in const [
      (GameAssets.zombieShambler, 150.0, -60.0, 30.0),
      (GameAssets.zombieShambler, 190.0, 70.0, 30.0),
      (GameAssets.zombieRunner, -170.0, -90.0, 20.0),
      (GameAssets.zombieBloater, 300.0, 10.0, 80.0),
      (GameAssets.zombieBrute, -260.0, 120.0, 300.0),
    ]) {
      final d = TrainingDummy(
        spritePath: path,
        home: Vector2(x, y),
        maxHp: hp,
        hitRadius: path == GameAssets.zombieBrute
            ? 20
            : path == GameAssets.zombieBloater
            ? 15
            : 11,
      );
      targets.add(d);
      world.add(d);
    }
    world.add(Flashlight());

    moveStick = VirtualStick(leftSide: true);
    aimStick = VirtualStick(leftSide: false);
    camera.viewport.addAll([moveStick, aimStick, Hud()]);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    camera.viewfinder.zoom = size.y / viewHeight;
  }

  /// Adds camera shake; strongest request wins, then it fades.
  void shake(double amount) => _shake = max(_shake, amount);

  /// The first living target a point at [p] touches, if any.
  TrainingDummy? targetHitBy(Vector2 p) {
    for (final t in targets) {
      if (t.isAlive && t.position.distanceTo(p) <= t.hitRadius) return t;
    }
    return null;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final offset = _shake > 0.05
        ? Vector2(random.nextDouble() - 0.5, random.nextDouble() - 0.5) *
              (_shake * 2)
        : Vector2.zero();
    _shake *= pow(0.0005, dt).toDouble();
    camera.viewfinder.position = _cameraTarget() + offset;
  }

  /// Follows the player but stops at the arena edge.
  Vector2 _cameraTarget() {
    final zoom = camera.viewfinder.zoom;
    final halfW = size.x / zoom / 2;
    final halfH = size.y / zoom / 2;
    double clampAxis(double v, double lo, double hi, double half) =>
        hi - lo <= half * 2 ? (lo + hi) / 2 : v.clamp(lo + half, hi - half);
    return Vector2(
      clampAxis(player.position.x, arena.left, arena.right, halfW),
      clampAxis(player.position.y, arena.top, arena.bottom, halfH),
    );
  }
}

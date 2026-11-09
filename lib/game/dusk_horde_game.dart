import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';

import 'enemies/enemy.dart';
import 'fx/flashlight.dart';
import 'game_assets.dart';
import 'hud.dart';
import 'input/virtual_stick.dart';
import 'player/player.dart';
import 'waves/wave_manager.dart';
import 'weapons/bullet.dart';
import 'world/arena_floor.dart';
import 'world/flow_field.dart';
import 'world/obstacle_layer.dart';

/// M2 scene: a dark lot with a few wrecks, and zombies that come in waves.
class DuskHordeGame extends FlameGame {
  DuskHordeGame({Random? random, this.firstBreather = 3})
    : random = random ?? Random();

  /// Height of the visible world in game pixels, whatever the phone.
  static const viewHeight = 360.0;
  static const gameOverOverlay = 'gameOver';

  final Random random;
  final double firstBreather;

  /// Playable area in world coordinates, centred on 0,0.
  final Rect arena = const Rect.fromLTRB(-480, -270, 480, 270);

  /// Placeholder wrecks and a dumpster. Comes from Tiled in M3.
  final List<Rect> obstacles = const [
    Rect.fromLTWH(-260, -150, 64, 30),
    Rect.fromLTWH(170, -190, 30, 64),
    Rect.fromLTWH(120, 110, 70, 32),
    Rect.fromLTWH(-330, 90, 40, 40),
    Rect.fromLTWH(-40, 170, 80, 26),
  ];

  /// Just outside the arena edges, so zombies walk in from the dark.
  late final List<Vector2> spawnPoints = [
    Vector2(arena.left - 20, -120),
    Vector2(arena.left - 20, 140),
    Vector2(arena.right + 20, -60),
    Vector2(arena.right + 20, 180),
    Vector2(-200, arena.top - 20),
    Vector2(260, arena.top - 20),
    Vector2(80, arena.bottom + 20),
  ];

  late final Player player;
  late final BulletPool bullets;
  late final FlowField flowField;
  late final WaveManager waves;
  late final VirtualStick moveStick;
  late final VirtualStick aimStick;

  double _shake = 0;

  @override
  Color backgroundColor() => const Color(0xFF050407);

  @override
  Future<void> onLoad() async {
    await images.loadAll(GameAssets.all);

    flowField = FlowField(bounds: arena, obstacles: obstacles);
    bullets = BulletPool(world);
    player = Player();
    waves = WaveManager(firstBreather: firstBreather);

    world.addAll([
      ArenaFloor(arena),
      ObstacleLayer(obstacles),
      player,
      Flashlight(),
    ]);
    add(waves);

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

  /// The first living enemy a point at [p] touches, if any.
  Enemy? targetHitBy(Vector2 p) {
    for (final e in waves.alive) {
      if (e.position.distanceTo(p) <= e.hitRadius) return e;
    }
    return null;
  }

  bool isGameOver = false;

  void onPlayerDied() {
    isGameOver = true;
    shake(8);
    if (overlays.registeredOverlays.contains(gameOverOverlay)) {
      overlays.add(gameOverOverlay);
    }
    pauseEngine();
  }

  /// Back to wave 1 with full health.
  void restart() {
    isGameOver = false;
    overlays.remove(gameOverOverlay);
    waves.reset();
    player.revive();
    moveStick.vector.setZero();
    aimStick.vector.setZero();
    resumeEngine();
  }

  @override
  void update(double dt) {
    flowField.update(player.position);
    super.update(dt);
    final offset = _shake > 0.05
        ? (Vector2(random.nextDouble() - 0.5, random.nextDouble() - 0.5)
            ..scale(_shake * 2))
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

import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';

import '../meta/progress.dart';
import '../meta/save_store.dart';
import 'enemies/enemy.dart';
import 'fx/explosion.dart';
import 'fx/flashlight.dart';
import 'game_assets.dart';
import 'hud.dart';
import 'input/virtual_stick.dart';
import 'pickups/ammo_box.dart';
import 'pickups/medkit.dart';
import 'pickups/supply_crate.dart';
import 'player/player.dart';
import 'waves/wave_manager.dart';
import 'weapons/bullet.dart';
import 'world/flow_field.dart';
import 'world/level_map.dart';
import 'world/obstacle_layer.dart';

/// Level 1: the Gas Station. Survive 10 waves of zombies until dawn.
class DuskHordeGame extends FlameGame {
  DuskHordeGame({
    Random? random,
    this.firstBreather = 3,
    this.mapFile = 'gas_station.tmx',
    Progress? progress,
    SaveStore? store,
    this.showWorkbenchOnStart = false,
  }) : random = random ?? Random(),
       progress = progress ?? Progress(),
       store = store ?? MemorySaveStore();

  /// Height of the visible world in game pixels, whatever the phone.
  static const viewHeight = 360.0;
  static const gameOverOverlay = 'gameOver';
  static const dawnOverlay = 'dawn';
  static const workbenchOverlay = 'workbench';

  /// Wave reached at the Gas Station that unlocks the SMG.
  static const smgUnlockWave = 5;

  final Random random;
  final double firstBreather;
  final String mapFile;
  final Progress progress;
  final SaveStore store;
  final bool showWorkbenchOnStart;

  /// Scrap and boss cores earned this run; banked when the run ends.
  int runScrap = 0;
  int runCores = 0;

  /// Set when something unlocked this run, for the end-of-run panel.
  String? unlockedThisRun;

  late final LevelMap level;
  Rect get arena => level.bounds;
  late final List<Rect> obstacles;
  List<Vector2> get spawnPoints => level.spawns;

  late final Player player;
  late final BulletPool bullets;
  late final FlowField flowField;
  late final WaveManager waves;
  late final VirtualStick moveStick;
  late final VirtualStick aimStick;
  SupplyCrate? crate;

  bool isGameOver = false;
  bool isDawn = false;
  double _shake = 0;

  @override
  Color backgroundColor() => const Color(0xFF050407);

  @override
  Future<void> onLoad() async {
    await images.loadAll(GameAssets.all);
    level = await LevelMap.load(mapFile);
    obstacles = level.obstacles;

    flowField = FlowField(bounds: arena, obstacles: obstacles);
    bullets = BulletPool(world);
    player = Player()..position = level.playerStart.clone();
    waves = WaveManager(firstBreather: firstBreather);

    world.addAll([
      level.component,
      ObstacleLayer(level.blockers),
      player,
      Flashlight(),
    ]);
    final cratePos = level.supplyCrate;
    if (cratePos != null) world.add(crate = SupplyCrate(cratePos));
    add(waves);

    moveStick = VirtualStick(leftSide: true);
    aimStick = VirtualStick(leftSide: false);
    camera.viewport.addAll([moveStick, aimStick, Hud()]);
    if (showWorkbenchOnStart) openWorkbench();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    camera.viewfinder.zoom = size.y / viewHeight;
  }

  /// Adds camera shake; strongest request wins, then it fades.
  void shake(double amount) => _shake = max(_shake, amount);

  /// The first living enemy a point at [p] touches, if any.
  Enemy? targetHitBy(Vector2 p, {Set<Enemy> except = const {}}) {
    for (final e in waves.alive) {
      if (except.contains(e)) continue;
      if (e.position.distanceTo(p) <= e.hitRadius) return e;
    }
    return null;
  }

  /// A burst that hurts the player and other zombies (Bloater death).
  /// Zombies take double, so popping a Bloater in a crowd pays off.
  void explode(Vector2 at, double radius, double damage) {
    world.add(Explosion(at, radius));
    shake(5);
    if (player.position.distanceTo(at) <= radius + Player.radius) {
      player.takeBite(damage, (player.position - at)..normalize());
    }
    for (final e in [...waves.alive]) {
      final d = e.position - at;
      if (d.length <= radius + e.type.radius) {
        e.takeHit(damage * 2, d.length2 > 0 ? d : Vector2(1, 0));
      }
    }
  }

  void dropMedkit(Vector2 at) => world.add(Medkit(at, lifetime: 20));

  /// Scrap for every kill; the Brute also gives a boss core. Guns that use
  /// ammo make zombies drop ammo boxes now and then.
  void onKill(Enemy e) {
    runScrap += (e.type.scrap * progress.scrapScale).round();
    if (e.type.isBoss) runCores++;
    final usesAmmo = player.guns.any((g) => !g.mag.isInfinite);
    if (usesAmmo && random.nextDouble() < 0.08) {
      world.add(AmmoBox(e.position.clone()));
    }
  }

  void onWaveStarted(int wave) {
    if (wave >= smgUnlockWave && !progress.unlocked.contains('smg')) {
      progress.unlock('smg');
      unlockedThisRun = 'SMG';
      store.save(progress);
    }
  }

  /// Bonus scrap for clearing a wave: 10 x the wave number.
  void onWaveCleared(int wave) {
    runScrap += (10 * wave * progress.scrapScale).round();
  }

  /// Puts the run's takings into saved progress and writes it to disk.
  void _bankRun() {
    progress.bank(scrap: runScrap, cores: runCores, wave: waves.wave);
    store.save(progress);
  }

  /// Between waves: put a medkit on up to two empty pickup spots.
  void onBreather() {
    final taken = world.children.whereType<Medkit>().map((m) => m.position);
    final free =
        level.pickups
            .where((p) => taken.every((t) => t.distanceTo(p) > 8))
            .toList()
          ..shuffle(random);
    for (final p in free.take(2)) {
      world.add(Medkit(p.clone()));
    }
  }

  void onPlayerDied() {
    isGameOver = true;
    _bankRun();
    shake(8);
    _showOverlay(gameOverOverlay);
    pauseEngine();
  }

  /// The final wave is cleared: the level is beaten.
  void onDawn() {
    isDawn = true;
    _bankRun();
    _showOverlay(dawnOverlay);
    pauseEngine();
  }

  void _showOverlay(String name) {
    if (overlays.registeredOverlays.contains(name)) overlays.add(name);
  }

  /// Pauses on the workbench (main menu).
  void openWorkbench() {
    overlays.removeAll([gameOverOverlay, dawnOverlay]);
    _showOverlay(workbenchOverlay);
    pauseEngine();
  }

  /// Back to wave 1 with full health and the current loadout.
  void restart() {
    isGameOver = false;
    isDawn = false;
    runScrap = 0;
    runCores = 0;
    unlockedThisRun = null;
    overlays.removeAll([gameOverOverlay, dawnOverlay, workbenchOverlay]);
    waves.reset();
    world.children.whereType<Medkit>().forEach((m) => m.removeFromParent());
    world.children.whereType<AmmoBox>().forEach((m) => m.removeFromParent());
    crate?.reset();
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

  /// Follows the player but stops at the map edge.
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

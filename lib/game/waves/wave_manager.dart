import 'package:flame/components.dart';

import '../dusk_horde_game.dart';
import '../enemies/enemy.dart';
import '../enemies/enemy_type.dart';
import '../enemies/spawn.dart';
import 'wave_plan.dart';

enum WavePhase { breather, spawning, fighting, dawn }

/// Runs the loop: breather, spawn a wave, wait until it's cleared, repeat.
/// In Endless there is no dawn: the waves keep coming.
class WaveManager extends Component with HasGameReference<DuskHordeGame> {
  WaveManager({this.plan = const ZombiePlan(), this.firstBreather = 3});

  WavePlan plan;
  final double firstBreather;
  bool endless = false;

  WavePhase phase = WavePhase.breather;
  int wave = 0;
  double breatherLeft = 0;

  /// The boss of the current wave while it lives (for the HUD bar).
  Enemy? boss;

  /// Enemies currently alive (spawned and not yet killed).
  final List<Enemy> alive = [];
  final List<EnemyType> _queue = [];
  double _spawnTimer = 0;
  int _spawnIndex = 0;
  int kills = 0;

  /// Enemies still to beat this wave, including ones not yet spawned.
  int get remaining => alive.length + _queue.length;

  @override
  void onMount() {
    super.onMount();
    reset();
  }

  void reset() {
    for (final e in [...alive]) {
      e.removeFromParent();
    }
    alive.clear();
    _queue.clear();
    boss = null;
    wave = 0;
    kills = 0;
    phase = WavePhase.breather;
    breatherLeft = firstBreather;
  }

  void onEnemyKilled(Enemy e) {
    alive.remove(e);
    kills++;
    if (identical(e, boss)) boss = null;
    game.onKill(e);
  }

  @override
  void update(double dt) {
    switch (phase) {
      case WavePhase.breather:
        breatherLeft -= dt;
        if (breatherLeft <= 0) _startWave();
      case WavePhase.spawning:
        _spawnTimer -= dt;
        if (_spawnTimer <= 0 && alive.length < plan.maxOnScreen) {
          _spawnOne();
          _spawnTimer = plan.spawnInterval(wave);
        }
        if (_queue.isEmpty) phase = WavePhase.fighting;
      case WavePhase.fighting:
        if (alive.isEmpty) {
          game.onWaveCleared(wave);
          if (!endless && wave >= plan.finalWave) {
            phase = WavePhase.dawn;
            game.onDawn();
          } else {
            phase = WavePhase.breather;
            breatherLeft = game.progress.testMode
                ? 3
                : WavePlan.breatherSeconds;
            game.onBreather();
          }
        }
      case WavePhase.dawn:
        break;
    }
  }

  void _startWave() {
    wave++;
    game.onWaveStarted(wave);
    final spec = plan.wave(wave, game.random, endless: endless);
    _queue
      ..clear()
      ..addAll(spec.enemies);
    _spawnTimer = 0;
    phase = WavePhase.spawning;
    _growPods(spec.pods);
  }

  /// Brood Pods appear on hive spots, as far from the player as possible.
  void _growPods(int count) {
    if (count == 0) return;
    final spots =
        [...(game.level.hives.isEmpty ? game.spawnPoints : game.level.hives)]
          ..shuffle(game.random)
          ..sort(
            (a, b) => b
                .distanceTo(game.player.position)
                .compareTo(a.distanceTo(game.player.position)),
          );
    for (final p in spots.take(count)) {
      addEnemy(
        createEnemy(Aliens.broodPod, p.clone(), hpScale: plan.hpScale(wave)),
      );
    }
  }

  /// Test Mode: ends the current wave on the spot (no scrap for the
  /// skipped enemies), so later waves and the boss can be reached quickly.
  void skipWave() {
    if (phase != WavePhase.spawning && phase != WavePhase.fighting) return;
    _queue.clear();
    for (final e in alive) {
      e.removeFromParent();
    }
    alive.clear();
    boss = null;
    phase = WavePhase.fighting;
  }

  /// Puts an enemy into play mid-wave (spawns, pods, the Warden's packs).
  void addEnemy(Enemy e) {
    alive.add(e);
    game.world.add(e);
  }

  void _spawnOne() {
    final type = _queue.removeLast();
    // Packs (Skitters) arrive together from one spawn point.
    var extra = 0;
    while (extra < type.pack - 1 && _queue.isNotEmpty && _queue.last == type) {
      _queue.removeLast();
      extra++;
    }
    final points = game.spawnPoints;
    // Rotate through spawn points, skipping any right next to the player.
    var p = points[_spawnIndex++ % points.length];
    for (var i = 0; i < points.length; i++) {
      if (p.distanceTo(game.player.position) > 140) break;
      p = points[_spawnIndex++ % points.length];
    }
    for (var i = 0; i <= extra; i++) {
      final jitter = Vector2(
        (game.random.nextDouble() - 0.5) * (24 + 6 * extra),
        (game.random.nextDouble() - 0.5) * (24 + 6 * extra),
      );
      final e = createEnemy(
        type,
        p + jitter,
        hpScale: plan.hpScale(wave, boss: type.isBoss),
      );
      if (type.isBoss) boss = e;
      addEnemy(e);
    }
  }
}

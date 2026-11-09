import 'package:flame/components.dart';

import '../dusk_horde_game.dart';
import '../enemies/enemy.dart';
import '../enemies/enemy_type.dart';
import 'wave_plan.dart';

enum WavePhase { breather, spawning, fighting }

/// Runs the loop: breather, spawn a wave, wait until it's cleared, repeat.
class WaveManager extends Component with HasGameReference<DuskHordeGame> {
  WaveManager({this.plan = const WavePlan(), this.firstBreather = 3});

  final WavePlan plan;
  final double firstBreather;

  WavePhase phase = WavePhase.breather;
  int wave = 0;
  double breatherLeft = 0;

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
    wave = 0;
    kills = 0;
    phase = WavePhase.breather;
    breatherLeft = firstBreather;
  }

  void onEnemyKilled(Enemy e) {
    alive.remove(e);
    kills++;
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
          phase = WavePhase.breather;
          breatherLeft = WavePlan.breatherSeconds;
        }
    }
  }

  void _startWave() {
    wave++;
    _queue
      ..clear()
      ..addAll(plan.wave(wave, game.random).enemies);
    _spawnTimer = 0;
    phase = WavePhase.spawning;
  }

  void _spawnOne() {
    final type = _queue.removeLast();
    final points = game.spawnPoints;
    // Rotate through spawn points, skipping any right next to the player.
    var p = points[_spawnIndex++ % points.length];
    for (var i = 0; i < points.length; i++) {
      if (p.distanceTo(game.player.position) > 140) break;
      p = points[_spawnIndex++ % points.length];
    }
    final jitter = Vector2(
      (game.random.nextDouble() - 0.5) * 24,
      (game.random.nextDouble() - 0.5) * 24,
    );
    final e = Enemy(type, p + jitter, hpScale: plan.hpScale(wave));
    alive.add(e);
    game.world.add(e);
  }
}

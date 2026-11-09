import 'dart:math';

import '../enemies/enemy_type.dart';

/// What one wave contains. Pure data, built by [WavePlan].
class WaveSpec {
  const WaveSpec(this.number, this.enemies);

  final int number;
  final List<EnemyType> enemies;

  int countOf(EnemyType t) => enemies.where((e) => e == t).length;
}

/// Level 1, from the design plan: zombie count = 6 + 3 x wave, a new type no
/// earlier than wave 3, HP +8% per wave, a mini-boss on wave 5, the Brute
/// on wave 10.
class WavePlan {
  const WavePlan({this.maxOnScreen = 60, this.finalWave = 10});

  final int maxOnScreen;

  /// Clearing this wave means dawn: the level is beaten.
  final int finalWave;

  WaveSpec wave(int n, Random random) {
    if (n >= finalWave) return _bossWave(n, random);
    final total = 6 + 3 * n;
    final runnerShare = n < 3 ? 0.0 : min(0.15 + 0.05 * (n - 3), 0.4);
    final bloaterShare = n < 6 ? 0.0 : 0.1;
    final runners = (total * runnerShare).round();
    final bloaters = (total * bloaterShare).round();
    final elites = n == 5 ? 1 : 0;
    final list = <EnemyType>[
      for (var i = 0; i < total - runners - bloaters - elites; i++)
        Zombies.shambler,
      for (var i = 0; i < runners; i++) Zombies.runner,
      for (var i = 0; i < bloaters; i++) Zombies.bloater,
    ]..shuffle(random);
    // The elite comes last, once the crowd has thinned.
    for (var i = 0; i < elites; i++) {
      list.insert(0, Zombies.eliteShambler);
    }
    return WaveSpec(n, list);
  }

  /// The Brute plus an escort. It arrives last (spawn order runs from the
  /// end of the list), after the escort has started pouring in.
  WaveSpec _bossWave(int n, Random random) {
    final escort = <EnemyType>[
      for (var i = 0; i < 12; i++) Zombies.shambler,
      for (var i = 0; i < 6; i++) Zombies.runner,
      for (var i = 0; i < 3; i++) Zombies.bloater,
    ]..shuffle(random);
    return WaveSpec(n, [
      ...escort.sublist(0, 9),
      Zombies.brute,
      ...escort.sublist(9),
    ]);
  }

  /// HP multiplier for wave [n]. Bosses get half the bonus.
  double hpScale(int n, {bool boss = false}) =>
      1 + (boss ? 0.04 : 0.08) * (n - 1);

  /// Seconds between spawns; waves pour in faster as they grow.
  double spawnInterval(int n) => max(0.25, 0.9 - 0.06 * n);

  static const breatherSeconds = 15.0;
}

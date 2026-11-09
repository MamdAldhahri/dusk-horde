import 'dart:math';

import '../enemies/enemy_type.dart';

/// What one wave contains. Pure data, built by [WavePlan].
class WaveSpec {
  const WaveSpec(this.number, this.enemies);

  final int number;
  final List<EnemyType> enemies;

  int countOf(EnemyType t) => enemies.where((e) => e == t).length;
}

/// Starting numbers from the design plan: zombie count = 6 + 3 x wave, a new
/// type no earlier than wave 3, HP +8% per wave.
class WavePlan {
  const WavePlan({this.maxOnScreen = 60});

  final int maxOnScreen;

  /// Level 1, waves 1 to 10. Bloater and the Brute join in M3.
  WaveSpec wave(int n, Random random) {
    final total = 6 + 3 * n;
    final runnerShare = n < 3 ? 0.0 : min(0.15 + 0.05 * (n - 3), 0.4);
    final runners = (total * runnerShare).round();
    final list = <EnemyType>[
      for (var i = 0; i < total - runners; i++) Zombies.shambler,
      for (var i = 0; i < runners; i++) Zombies.runner,
    ]..shuffle(random);
    return WaveSpec(n, list);
  }

  /// HP multiplier for wave [n].
  double hpScale(int n) => 1 + 0.08 * (n - 1);

  /// Seconds between spawns; waves pour in faster as they grow.
  double spawnInterval(int n) => max(0.25, 0.9 - 0.06 * n);

  static const breatherSeconds = 15.0;
}

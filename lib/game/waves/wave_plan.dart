import 'dart:math';

import '../enemies/enemy_type.dart';

/// What one wave contains. Pure data, built by a [WavePlan].
class WaveSpec {
  const WaveSpec(this.number, this.enemies, {this.pods = 0});

  final int number;

  /// Spawn order runs from the END of this list.
  final List<EnemyType> enemies;

  /// Brood Pods that grow on the hive when the wave starts.
  final int pods;

  int countOf(EnemyType t) => enemies.where((e) => e == t).length;
}

/// How a level's waves grow. Each apocalypse has its own subclass.
abstract class WavePlan {
  const WavePlan({this.maxOnScreen = 60, required this.finalWave});

  final int maxOnScreen;

  /// Clearing this wave means dawn: the level is beaten. Endless ignores it.
  final int finalWave;

  WaveSpec wave(int n, Random random, {bool endless = false});

  /// Story mode: the final wave. Endless: every 10th wave.
  bool isBossWave(int n, {bool endless = false}) =>
      endless ? n % 10 == 0 : n >= finalWave;

  /// Mini-boss waves: 5, 15, 25... (and 10 in story mode when it's not the
  /// final wave).
  bool isEliteWave(int n, {bool endless = false}) =>
      n % 5 == 0 && !isBossWave(n, endless: endless);

  /// HP multiplier for wave [n]. Bosses get half the bonus.
  double hpScale(int n, {bool boss = false}) =>
      1 + (boss ? 0.04 : 0.08) * (n - 1);

  /// Seconds between spawns; waves pour in faster as they grow.
  double spawnInterval(int n) => max(0.25, 0.9 - 0.06 * n);

  static const breatherSeconds = 15.0;
}

/// Level 1, from the design plan: zombie count = 6 + 3 x wave, a new type no
/// earlier than wave 3, HP +8% per wave, a mini-boss on wave 5, the Brute
/// on wave 10.
class ZombiePlan extends WavePlan {
  const ZombiePlan({super.maxOnScreen, super.finalWave = 10});

  @override
  WaveSpec wave(int n, Random random, {bool endless = false}) {
    if (isBossWave(n, endless: endless)) return _bossWave(n, random);
    final total = 6 + 3 * n;
    final runnerShare = n < 3 ? 0.0 : min(0.15 + 0.05 * (n - 3), 0.4);
    final bloaterShare = n < 6 ? 0.0 : 0.1;
    final runners = (total * runnerShare).round();
    final bloaters = (total * bloaterShare).round();
    final elites = isEliteWave(n, endless: endless) ? 1 : 0;
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
}

/// Level 2: Skitter packs from wave 1, Lancers from 3, Stalkers from 6,
/// Brood Pods from 8, an elite Lancer on 5 and 10, the Warden on 15.
class AlienPlan extends WavePlan {
  const AlienPlan({super.maxOnScreen, super.finalWave = 15});

  @override
  WaveSpec wave(int n, Random random, {bool endless = false}) {
    if (isBossWave(n, endless: endless)) return _bossWave(n, random);
    final total = 6 + 3 * n;
    final lancerShare = n < 3 ? 0.0 : min(0.15 + 0.03 * (n - 3), 0.3);
    final stalkerShare = n < 6 ? 0.0 : min(0.1 + 0.02 * (n - 6), 0.2);
    final lancers = (total * lancerShare).round();
    final stalkers = (total * stalkerShare).round();
    final skitters = total - lancers - stalkers;
    final pods = n < 8 ? 0 : (n < 11 ? 1 : min(3, 2 + (n - 11) ~/ 10));
    final list = _mix(
      random,
      skitters: skitters,
      singles: [
        for (var i = 0; i < lancers; i++) Aliens.lancer,
        for (var i = 0; i < stalkers; i++) Aliens.stalker,
      ],
    );
    if (isEliteWave(n, endless: endless)) list.insert(0, Aliens.eliteLancer);
    return WaveSpec(n, list, pods: pods);
  }

  /// The Warden walks in after its escort, and drops Skitters itself.
  WaveSpec _bossWave(int n, Random random) {
    final escort = _mix(
      random,
      skitters: 14,
      singles: [
        for (var i = 0; i < 4; i++) Aliens.lancer,
        for (var i = 0; i < 2; i++) Aliens.stalker,
      ],
    );
    final cut = escort.length ~/ 2;
    return WaveSpec(n, [
      ...escort.sublist(0, cut),
      Aliens.warden,
      ...escort.sublist(cut),
    ]);
  }

  /// Skitters stay together in packs; packs and singles are shuffled.
  static List<EnemyType> _mix(
    Random random, {
    required int skitters,
    required List<EnemyType> singles,
  }) {
    final units = <List<EnemyType>>[
      for (final s in singles) [s],
    ];
    var left = skitters;
    while (left > 0) {
      final size = min(left, Aliens.skitter.pack);
      units.add(List.filled(size, Aliens.skitter));
      left -= size;
    }
    units.shuffle(random);
    return [for (final u in units) ...u];
  }
}

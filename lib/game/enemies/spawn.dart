import 'package:flame/components.dart';

import 'aliens.dart';
import 'brute.dart';
import 'enemy.dart';
import 'enemy_type.dart';
import 'warden.dart';

/// Builds the right class for an [EnemyType].
Enemy createEnemy(EnemyType type, Vector2 at, {double hpScale = 1}) =>
    switch (type.kind) {
      EnemyKind.basic => Enemy(type, at, hpScale: hpScale),
      EnemyKind.brute => Brute(at, hpScale: hpScale),
      EnemyKind.skitter => Skitter(at, hpScale: hpScale),
      EnemyKind.lancer => Lancer(type, at, hpScale: hpScale),
      EnemyKind.stalker => Stalker(at, hpScale: hpScale),
      EnemyKind.broodPod => BroodPod(at, hpScale: hpScale),
      EnemyKind.warden => Warden(at, hpScale: hpScale),
    };

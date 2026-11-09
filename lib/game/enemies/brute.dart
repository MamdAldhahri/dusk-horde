import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import 'enemy.dart';
import 'enemy_type.dart';

enum BruteState { chase, windup, charge, stunned }

/// The Level 1 boss. Walks toward you, then winds up and charges in a
/// straight line. Hitting a wreck or wall stuns it, and stunned it takes
/// 1.5x damage, so the trick is to dodge sideways near cover.
class Brute extends Enemy {
  Brute(Vector2 at, {super.hpScale}) : super(Zombies.brute, at);

  static const windupTime = 0.8;
  static const chargeTime = 1.0;
  static const chargeSpeed = 330.0;
  static const stunTime = 1.4;
  static const chargeCooldown = 3.0;
  static const chargeDamage = 28.0;

  BruteState state = BruteState.chase;
  double _timer = 0;
  double _cooldown = 2;
  final Vector2 _chargeDir = Vector2.zero();

  @override
  double get damageTakenScale => state == BruteState.stunned ? 1.5 : 1;

  @override
  double get contactDamage =>
      state == BruteState.charge ? chargeDamage : type.biteDamage;

  @override
  Vector2 desiredVelocity(double dt, Vector2 toPlayer, double dist) {
    _cooldown -= dt;
    _timer -= dt;
    switch (state) {
      case BruteState.chase:
        if (_cooldown <= 0 && dist < 220) {
          state = BruteState.windup;
          _timer = windupTime;
          _chargeDir.setFrom(toPlayer.normalized());
          add(
            ColorEffect(
              const Color(0xFFFF3020),
              EffectController(
                duration: windupTime / 2,
                reverseDuration: windupTime / 2,
              ),
              opacityTo: 0.6,
            ),
          );
          return Vector2.zero();
        }
        return super.desiredVelocity(dt, toPlayer, dist);
      case BruteState.windup:
        // Keeps tracking you while it winds up, then commits.
        _chargeDir.setFrom(toPlayer.normalized());
        if (_timer <= 0) {
          state = BruteState.charge;
          _timer = chargeTime;
          biteTimer = 0;
          game.shake(3);
        }
        return Vector2.zero();
      case BruteState.charge:
        if (_timer <= 0) _endCharge(stunned: false);
        return _chargeDir * chargeSpeed;
      case BruteState.stunned:
        if (_timer <= 0) state = BruteState.chase;
        return Vector2.zero();
    }
  }

  @override
  void faceToward(Vector2 v) {
    if (state == BruteState.charge || state == BruteState.windup) {
      angle = atan2(_chargeDir.y, _chargeDir.x);
    } else if (state != BruteState.stunned) {
      super.faceToward(v);
    }
  }

  @override
  void onBumpedObstacle() {
    if (state == BruteState.charge) _endCharge(stunned: true);
  }

  void _endCharge({required bool stunned}) {
    _cooldown = chargeCooldown;
    if (stunned) {
      state = BruteState.stunned;
      _timer = stunTime;
      game.shake(7);
    } else {
      state = BruteState.chase;
    }
  }
}

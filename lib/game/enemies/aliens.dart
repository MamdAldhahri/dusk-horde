import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import 'enemy.dart';
import 'enemy_type.dart';
import 'plasma_bolt.dart';

/// Fast and fragile, comes in packs, and leaps the last few tiles.
class Skitter extends Enemy {
  Skitter(Vector2 at, {super.hpScale}) : super(Aliens.skitter, at);

  static const leapRange = 70.0;
  static const leapTime = 0.3;
  static const leapSpeed = 380.0;

  double _leap = 0;
  double _cooldown = 0.5;
  final Vector2 _leapDir = Vector2.zero();
  bool get isLeaping => _leap > 0;

  @override
  Vector2 desiredVelocity(double dt, Vector2 toPlayer, double dist) {
    _cooldown -= dt;
    if (_leap > 0) {
      _leap -= dt;
      return _leapDir * leapSpeed;
    }
    if (_cooldown <= 0 && dist < leapRange && dist > 20) {
      _leap = leapTime;
      _cooldown = 2;
      _leapDir.setFrom(toPlayer.normalized());
      return _leapDir * leapSpeed;
    }
    return super.desiredVelocity(dt, toPlayer, dist);
  }
}

/// Keeps its distance and fires slow plasma bolts you can dodge. Flashes
/// cyan for a moment before each shot.
class Lancer extends Enemy {
  Lancer(super.type, super.at, {super.hpScale});

  static const minRange = 120.0;
  static const maxRange = 200.0;
  static const fireRange = 270.0;
  static const chargeTime = 0.45;

  late double _fireTimer = 1.5 + game.random.nextDouble();
  double _charge = 0;
  double _strafe = 1;
  double _strafeTimer = 2;

  bool get isElite => type == Aliens.eliteLancer;

  @override
  Vector2 desiredVelocity(double dt, Vector2 toPlayer, double dist) {
    _fireTimer -= dt;
    _strafeTimer -= dt;
    if (_strafeTimer <= 0) {
      _strafe = -_strafe;
      _strafeTimer = 1.5 + game.random.nextDouble() * 1.5;
    }
    if (_charge > 0) {
      _charge -= dt;
      if (_charge <= 0) _fire(toPlayer);
      return Vector2.zero();
    }
    if (_fireTimer <= 0 && dist < fireRange) {
      _charge = chargeTime;
      _fireTimer = (isElite ? 2.0 : 2.4) + game.random.nextDouble() * 0.8;
      add(
        ColorEffect(
          const Color(0xFF60E0FF),
          EffectController(duration: chargeTime / 2, reverseDuration: 0.1),
          opacityTo: 0.8,
        ),
      );
      return Vector2.zero();
    }
    if (dist > maxRange) return super.desiredVelocity(dt, toPlayer, dist);
    final dir = toPlayer.normalized();
    if (dist < minRange) return dir..scale(-type.speed);
    return Vector2(-dir.y, dir.x)..scale(type.speed * 0.6 * _strafe);
  }

  void _fire(Vector2 toPlayer) {
    final dir = toPlayer.normalized();
    final from = position + dir * (type.radius + 4);
    final spread = isElite ? [-0.25, 0.0, 0.25] : [0.0];
    for (final a in spread) {
      game.world.add(
        PlasmaBolt(from, dir.clone()..rotate(a), damage: isElite ? 14 : 12),
      );
    }
  }
}

/// Almost invisible: only a faint shimmer in the dark, fully visible in the
/// flashlight beam. Aim assist can only lock on while it's lit.
class Stalker extends Enemy {
  Stalker(Vector2 at, {super.hpScale}) : super(Aliens.stalker, at);

  double visibility = 0;

  @override
  bool get isTargetable => visibility > 0.5;

  @override
  void update(double dt) {
    super.update(dt);
    if (!isAlive) return;
    final lit = game.flashlight.lights(position);
    final shimmer = 0.06 + 0.05 * sin(age * 9);
    final target = lit ? 1.0 : shimmer;
    // Fades in fast when caught in the light, slips away more slowly.
    final rate = lit ? 8.0 : 3.0;
    visibility += (target - visibility) * min(1, rate * dt);
    opacity = visibility.clamp(0.0, 1.0);
  }
}

/// Grows on the hive and births a Skitter every 4 s until destroyed.
class BroodPod extends Enemy {
  BroodPod(Vector2 at, {super.hpScale}) : super(Aliens.broodPod, at);

  static const interval = 4.0;
  double _timer = 2;

  @override
  bool get isStatic => true;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    angle = game.random.nextDouble() * pi * 2;
    add(
      ScaleEffect.to(
        Vector2.all(1.08),
        EffectController(duration: 0.6, reverseDuration: 0.6, infinite: true),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isAlive) return;
    _timer -= dt;
    final waves = game.waves;
    if (_timer <= 0 && waves.alive.length < waves.plan.maxOnScreen) {
      _timer = interval;
      final a = game.random.nextDouble() * pi * 2;
      waves.addEnemy(
        Skitter(position + Vector2(cos(a), sin(a)) * (type.radius + 8)),
      );
    }
  }
}

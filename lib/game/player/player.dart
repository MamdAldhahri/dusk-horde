import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../dusk_horde_game.dart';
import '../fx/muzzle_flash.dart';
import '../game_assets.dart';
import '../weapons/magazine.dart';
import '../world/obstacles.dart';
import 'dodge.dart';

/// The survivor. Left stick moves, right stick aims and auto-fires.
class Player extends SpriteComponent with HasGameReference<DuskHordeGame> {
  Player() : super(anchor: Anchor.center, priority: 10);

  static const moveSpeed = 120.0; // px per second
  static const dodgeSpeed = 360.0;
  static const radius = 10.0;
  static const aimAssistAngle = 15 * pi / 180;
  static const maxHp = 100.0;
  static const hurtGrace = 0.6; // seconds of safety after a bite

  double hp = maxHp;
  bool get isAlive => hp > 0;
  double _hurtTimer = 0;
  final Vector2 _knock = Vector2.zero();

  /// How close an enemy must be to bite.
  double get radiusForBites => radius + 2;

  /// Where the gun and flashlight point, radians (0 = right).
  double aimAngle = 0;

  final dodge = Dodge();
  final pistol = Magazine(size: 12, shotsPerSecond: 4, reloadSeconds: 1.2);
  final Vector2 _dodgeDir = Vector2(1, 0);

  @override
  Future<void> onLoad() async {
    sprite = Sprite(game.images.fromCache(GameAssets.player));
    size = sprite!.srcSize;
    paint = Paint()..filterQuality = FilterQuality.none;
  }

  /// Called by enemies. Dodging and the short grace after a bite ignore it.
  void takeBite(double damage, Vector2 from) {
    if (!isAlive || dodge.isInvincible || _hurtTimer > 0) return;
    hp = max(0, hp - damage);
    _hurtTimer = hurtGrace;
    _knock.setFrom(from..scale(140));
    add(
      ColorEffect(
        const Color(0xFFFF2020),
        EffectController(duration: 0.08, reverseDuration: 0.15),
        opacityTo: 0.7,
      ),
    );
    game.shake(4);
    if (!isAlive) game.onPlayerDied();
  }

  void revive() {
    hp = maxHp;
    _hurtTimer = 0;
    _knock.setZero();
    position.setZero();
    opacity = 1;
  }

  void tryDodge() {
    final move = game.moveStick.vector;
    _dodgeDir.setFrom(
      move.length2 > 0.01
          ? move.normalized()
          : Vector2(cos(aimAngle), sin(aimAngle)),
    );
    if (dodge.tryStart()) {
      add(
        OpacityEffect.to(
          0.45,
          EffectController(
            duration: dodge.duration / 2,
            reverseDuration: dodge.duration / 2,
          ),
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isAlive) return;
    if (_hurtTimer > 0) _hurtTimer -= dt;
    dodge.update(dt);
    pistol.update(dt);

    final move = game.moveStick.vector;
    if (dodge.isRolling) {
      position.addScaled(_dodgeDir, dodgeSpeed * dt);
    } else {
      position.addScaled(move, moveSpeed * dt);
    }
    if (_knock.length2 > 1) {
      position.addScaled(_knock, dt);
      _knock.scale(0.8);
    }
    pushOutOfRects(position, radius, game.obstacles);
    _clampToArena();

    final aim = game.aimStick.vector;
    if (aim.length2 > 0.0001) {
      aimAngle = _assist(atan2(aim.y, aim.x));
      if (aim.length > 0.3 && !dodge.isRolling) _shoot();
    } else if (move.length2 > 0.0001) {
      aimAngle = atan2(move.y, move.x);
    }
    angle = aimAngle;
  }

  void _shoot() {
    if (!pistol.tryFire()) return;
    final dir = Vector2(cos(aimAngle), sin(aimAngle));
    final muzzle = position + dir * 15;
    // Small random spread so it doesn't feel robotic.
    final spread = (game.random.nextDouble() - 0.5) * 0.06;
    game.bullets.fire(muzzle, aimAngle + spread, 10);
    game.world.add(MuzzleFlash(muzzle));
    game.shake(0.8);
  }

  /// Nudges the aim toward the nearest living target within 15 degrees.
  double _assist(double raw) {
    double? best;
    var bestDiff = aimAssistAngle;
    for (final t in game.waves.alive) {
      if (!t.isAlive) continue;
      final to = t.position - position;
      if (to.length > 260) continue;
      final a = atan2(to.y, to.x);
      final diff = atan2(sin(a - raw), cos(a - raw)).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = a;
      }
    }
    return best ?? raw;
  }

  void _clampToArena() {
    final r = game.arena.deflate(radius);
    position.x = position.x.clamp(r.left, r.right);
    position.y = position.y.clamp(r.top, r.bottom);
  }
}

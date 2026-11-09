import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../dusk_horde_game.dart';
import '../world/obstacles.dart';
import 'enemy_type.dart';

/// One enemy of any [EnemyType]: follows the flow field to the player, keeps
/// a little space from its neighbours, bites when close, dies when shot.
/// Special behaviour (the Brute's charge) lives in subclasses.
class Enemy extends SpriteComponent with HasGameReference<DuskHordeGame> {
  Enemy(this.type, Vector2 at, {double hpScale = 1})
    : hp = type.hp * hpScale,
      maxHp = type.hp * hpScale,
      super(position: at, anchor: Anchor.center, priority: 5);

  final EnemyType type;
  final double maxHp;
  double hp;
  bool get isAlive => hp > 0;
  double get hitRadius => type.radius + 2;

  /// Extra damage taken (the Brute is weak while stunned).
  double get damageTakenScale => 1;

  final Vector2 knock = Vector2.zero();
  double biteTimer = 0;
  late final double _wobbleSeed = game.random.nextDouble() * 10;
  double age = 0;

  @override
  Future<void> onLoad() async {
    sprite = Sprite(game.images.fromCache(type.sprite));
    size = sprite!.srcSize * type.scale;
    paint = Paint()..filterQuality = FilterQuality.none;
  }

  void takeHit(double damage, Vector2 direction) {
    if (!isAlive) return;
    hp -= damage * damageTakenScale;
    final push = type.isBoss ? 20.0 : 90.0;
    knock.setFrom(direction.normalized()..scale(push));
    add(
      ColorEffect(
        const Color(0xFFFFFFFF),
        EffectController(duration: 0.05, reverseDuration: 0.07),
        opacityTo: 0.85,
      ),
    );
    game.shake(1.2);
    if (!isAlive) _die();
  }

  void _die() {
    game.shake(type.isBoss ? 10 : 2.5);
    game.waves.onEnemyKilled(this);
    if (type.explodeRadius > 0) {
      game.explode(position.clone(), type.explodeRadius, type.explodeDamage);
    }
    if (game.random.nextDouble() < type.dropChance) {
      game.dropMedkit(position.clone());
    }
    priority = 1; // corpses lie under the living
    add(
      SequenceEffect([
        OpacityEffect.to(0.25, EffectController(duration: 0.2)),
        OpacityEffect.to(0, EffectController(duration: 1.5)),
        RemoveEffect(),
      ]),
    );
  }

  /// Where this enemy wants to go this frame, before separation and
  /// knockback. Pixels per second.
  Vector2 desiredVelocity(double dt, Vector2 toPlayer, double dist) {
    final dir = dist < 48
        ? (toPlayer.clone()..normalize())
        : game.flowField.direction(position);
    if (type.gait == Gait.zigzag && dist > 40 && dir.length2 > 0) {
      final side = Vector2(-dir.y, dir.x)
        ..scale(sin(age * 7 + _wobbleSeed) * 0.6);
      dir
        ..add(side)
        ..normalize();
    }
    return dir..scale(type.speed);
  }

  /// Damage dealt on contact right now.
  double get contactDamage => type.biteDamage;

  @override
  void update(double dt) {
    super.update(dt);
    if (!isAlive) return;
    age += dt;
    biteTimer -= dt;

    final player = game.player;
    final toPlayer = player.position - position;
    final dist = toPlayer.length;

    final wasInside = game.arena.contains(position.toOffset());
    final step = desiredVelocity(dt, toPlayer, dist)..add(_separation());
    position.addScaled(step, dt);
    if (wasInside && !game.arena.contains(position.toOffset())) {
      final r = game.arena.deflate(type.radius);
      position.x = position.x.clamp(r.left, r.right);
      position.y = position.y.clamp(r.top, r.bottom);
      onBumpedObstacle();
    }
    if (knock.length2 > 1) {
      position.addScaled(knock, dt);
      knock.scale(0.82);
    }
    if (game.arena.contains(position.toOffset())) {
      final before = position.clone();
      pushOutOfRects(position, type.radius, game.obstacles);
      if (before.distanceTo(position) > 0.5) onBumpedObstacle();
    }

    faceToward(toPlayer);

    if (dist <= type.radius + player.radiusForBites && biteTimer <= 0) {
      biteTimer = type.biteCooldown;
      player.takeBite(contactDamage, toPlayer.normalized());
    }
  }

  void faceToward(Vector2 v) {
    if (v.length2 > 1) angle = atan2(v.y, v.x);
  }

  /// Hook for subclasses; the Brute stops its charge on walls.
  void onBumpedObstacle() {}

  /// Gentle push away from nearby enemies so they crowd instead of stacking.
  Vector2 _separation() {
    final push = Vector2.zero();
    for (final other in game.waves.alive) {
      if (identical(other, this)) continue;
      final d = position - other.position;
      final min = type.radius + other.type.radius;
      final l2 = d.length2;
      if (l2 > 0.01 && l2 < min * min) {
        final l = sqrt(l2);
        push.addScaled(d, (min - l) / l * (type.isBoss ? 1 : 6));
      }
    }
    return push;
  }
}

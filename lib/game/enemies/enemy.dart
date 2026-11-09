import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../dusk_horde_game.dart';
import '../world/obstacles.dart';
import 'enemy_type.dart';

/// One enemy of any [EnemyType]: follows the flow field to the player, keeps
/// a little space from its neighbours, bites when close, dies when shot.
class Enemy extends SpriteComponent with HasGameReference<DuskHordeGame> {
  Enemy(this.type, Vector2 at, {double hpScale = 1})
    : hp = type.hp * hpScale,
      super(position: at, anchor: Anchor.center, priority: 5);

  final EnemyType type;
  double hp;
  bool get isAlive => hp > 0;
  double get hitRadius => type.radius + 2;

  final Vector2 _knock = Vector2.zero();
  double _biteTimer = 0;
  late final double _wobbleSeed = game.random.nextDouble() * 10;
  double _age = 0;

  @override
  Future<void> onLoad() async {
    sprite = Sprite(game.images.fromCache(type.sprite));
    size = sprite!.srcSize;
    paint = Paint()..filterQuality = FilterQuality.none;
  }

  void takeHit(double damage, Vector2 direction) {
    if (!isAlive) return;
    hp -= damage;
    _knock.setFrom(direction..scale(90));
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
    game.shake(2.5);
    game.waves.onEnemyKilled(this);
    priority = 1; // corpses lie under the living
    add(
      SequenceEffect([
        OpacityEffect.to(0.25, EffectController(duration: 0.2)),
        OpacityEffect.to(0, EffectController(duration: 1.5)),
        RemoveEffect(),
      ]),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isAlive) return;
    _age += dt;
    _biteTimer -= dt;

    final player = game.player;
    final toPlayer = player.position - position;
    final dist = toPlayer.length;

    // Close and nothing in the way: go straight. Otherwise follow the field.
    final dir = dist < 48
        ? (toPlayer.clone()..normalize())
        : game.flowField.direction(position);

    if (type.gait == Gait.zigzag && dist > 40 && dir.length2 > 0) {
      final side = Vector2(-dir.y, dir.x)
        ..scale(sin(_age * 7 + _wobbleSeed) * 0.6);
      dir
        ..add(side)
        ..normalize();
    }

    final step = dir..scale(type.speed);
    step.add(_separation());
    position.addScaled(step, dt);
    if (_knock.length2 > 1) {
      position.addScaled(_knock, dt);
      _knock.scale(0.82);
    }
    if (game.arena.contains(position.toOffset())) {
      pushOutOfRects(position, type.radius, game.obstacles);
    }

    if (dist > 1) angle = atan2(toPlayer.y, toPlayer.x);

    if (dist <= type.radius + player.radiusForBites && _biteTimer <= 0) {
      _biteTimer = type.biteCooldown;
      player.takeBite(type.biteDamage, toPlayer.normalized());
    }
  }

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
        push.addScaled(d, (min - l) / l * 6);
      }
    }
    return push;
  }
}

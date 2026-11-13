import 'dart:ui';

import 'package:flame/components.dart';

import '../dusk_horde_game.dart';
import '../player/player.dart';

/// A Lancer's slow, glowing shot. Slow enough to sidestep, and a dodge roll
/// passes straight through it. Drawn above the darkness so it can be seen.
class PlasmaBolt extends PositionComponent
    with HasGameReference<DuskHordeGame> {
  PlasmaBolt(Vector2 from, Vector2 direction, {this.damage = 12})
    : velocity = direction.normalized()..scale(speed),
      super(position: from.clone(), anchor: Anchor.center, priority: 110);

  static const speed = 150.0;
  static const radius = 4.0;
  static const lifetime = 4.0;

  final Vector2 velocity;
  final double damage;
  double _age = 0;

  static final _core = Paint()..color = const Color(0xFFDDFBFF);
  static final _glow = Paint()..color = const Color(0x6648D8FF);

  @override
  void update(double dt) {
    _age += dt;
    position.addScaled(velocity, dt);
    final o = position.toOffset();
    if (_age > lifetime ||
        !game.arena.contains(o) ||
        game.obstacles.any((r) => r.contains(o))) {
      removeFromParent();
      return;
    }
    final p = game.player;
    if (p.isAlive && p.position.distanceTo(position) < radius + Player.radius) {
      if (p.dodge.isInvincible) return; // rolls through it
      p.takeBite(damage, velocity.normalized());
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset.zero, radius * 2.2, _glow);
    canvas.drawCircle(Offset.zero, radius, _core);
  }
}

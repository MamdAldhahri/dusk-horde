import 'dart:ui';

import 'package:flame/components.dart';

import '../dusk_horde_game.dart';

/// Restores [heal] HP when the player walks over it. Drops fade out after
/// [lifetime] seconds (blinking for the last 4); map pickups never expire.
class Medkit extends PositionComponent with HasGameReference<DuskHordeGame> {
  Medkit(Vector2 at, {this.lifetime})
    : super(
        position: at,
        size: Vector2.all(10),
        anchor: Anchor.center,
        priority: 3,
      );

  static const heal = 25.0;
  static const magnetRange = 36.0;
  static const pickupRange = 12.0;

  final double? lifetime;
  double _age = 0;

  static final _box = Paint()..color = const Color(0xFFE8E2D6);
  static final _cross = Paint()..color = const Color(0xFFC0261E);
  static final _glow = Paint()..color = const Color(0x33FF4040);

  @override
  void update(double dt) {
    _age += dt;
    final life = lifetime;
    if (life != null && _age > life) {
      removeFromParent();
      return;
    }
    final p = game.player;
    if (!p.isAlive || p.hp >= p.maxHealth) return;
    final to = p.position - position;
    final d = to.length;
    if (d < pickupRange) {
      p.heal(heal);
      removeFromParent();
    } else if (d < magnetRange) {
      position.addScaled(to.normalized(), 140 * dt);
    }
  }

  @override
  void render(Canvas canvas) {
    final life = lifetime;
    if (life != null && life - _age < 4 && (_age * 6).floor().isEven) return;
    canvas.drawCircle(const Offset(5, 5), 9, _glow);
    canvas.drawRect(size.toRect(), _box);
    canvas.drawRect(const Rect.fromLTWH(4, 1.5, 2, 7), _cross);
    canvas.drawRect(const Rect.fromLTWH(1.5, 4, 7, 2), _cross);
  }
}

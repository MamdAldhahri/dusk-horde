import 'dart:ui';

import 'package:flame/components.dart';

import '../dusk_horde_game.dart';

/// Tops up guns that use ammo (not the pistol). Fades after 20 s.
class AmmoBox extends PositionComponent with HasGameReference<DuskHordeGame> {
  AmmoBox(Vector2 at)
    : super(
        position: at,
        size: Vector2(10, 7),
        anchor: Anchor.center,
        priority: 3,
      );

  static const share = 0.4;
  static const lifetime = 20.0;
  double _age = 0;

  static final _box = Paint()..color = const Color(0xFF6B6A3A);
  static final _band = Paint()..color = const Color(0xFFE8C860);

  @override
  void update(double dt) {
    _age += dt;
    if (_age > lifetime) {
      removeFromParent();
      return;
    }
    final p = game.player;
    final to = p.position - position;
    if (to.length < 12) {
      p.addAmmoShare(share);
      removeFromParent();
    } else if (to.length < 36) {
      position.addScaled(to.normalized(), 140 * dt);
    }
  }

  @override
  void render(Canvas canvas) {
    if (lifetime - _age < 4 && (_age * 6).floor().isEven) return;
    canvas.drawRect(size.toRect(), _box);
    canvas.drawRect(Rect.fromLTWH(0, 2.5, size.x, 2), _band);
  }
}

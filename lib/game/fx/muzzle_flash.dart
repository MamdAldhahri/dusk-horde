import 'dart:ui';

import 'package:flame/components.dart';

/// A two-frame burst of light at the barrel.
class MuzzleFlash extends PositionComponent {
  MuzzleFlash(Vector2 at) : super(position: at, priority: 110);

  double _life = 0.05;
  static final _paint = Paint()..color = const Color(0xFFFFE7A0);

  @override
  void update(double dt) {
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) => canvas.drawCircle(Offset.zero, 4, _paint);
}

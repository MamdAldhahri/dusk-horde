import 'dart:ui';

import 'package:flame/components.dart';

/// A quick acid-green burst (Bloater death). Damage is dealt by the game;
/// this is only the look.
class Explosion extends PositionComponent {
  Explosion(Vector2 at, this.radius) : super(position: at, priority: 120);

  final double radius;
  double _t = 0;
  static const duration = 0.35;
  final _paint = Paint();

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final k = (_t / duration).clamp(0.0, 1.0);
    _paint.color = Color.fromARGB((200 * (1 - k)).round(), 170, 210, 60);
    canvas.drawCircle(Offset.zero, radius * (0.4 + 0.6 * k), _paint);
    _paint.color = Color.fromARGB((255 * (1 - k)).round(), 255, 240, 160);
    canvas.drawCircle(Offset.zero, radius * 0.35 * (1 - k), _paint);
  }
}

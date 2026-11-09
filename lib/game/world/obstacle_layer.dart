import 'dart:ui';

import 'package:flame/components.dart';

/// Draws the placeholder obstacles (wrecked cars, a dumpster) as dark
/// blocks. Replaced by the Tiled map's collision layer in M3.
class ObstacleLayer extends Component {
  ObstacleLayer(this.rects) : super(priority: -5);

  final List<Rect> rects;

  static final _body = Paint()..color = const Color(0xFF34383F);
  static final _roof = Paint()..color = const Color(0xFF262A30);
  static final _edge = Paint()
    ..color = const Color(0xFF0D0C0F)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  void render(Canvas canvas) {
    for (final r in rects) {
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(4));
      canvas.drawRRect(rr, _body);
      canvas.drawRect(r.deflate(r.shortestSide * 0.22), _roof);
      canvas.drawRRect(rr, _edge);
    }
  }
}

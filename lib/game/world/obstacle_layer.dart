import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import 'level_map.dart';

/// Draws the map's props (wrecked cars, the dumpster, ship debris) from the
/// collision layer. Walls and pumps are drawn by the tiles, so they are skipped.
class ObstacleLayer extends Component {
  ObstacleLayer(List<Blocker> blockers)
    : props = blockers.where((b) => b.kind == 'prop').toList(),
      super(priority: -5);

  final List<Blocker> props;

  static final _car = Paint()..color = const Color(0xFF3A3F47);
  static final _rust = Paint()..color = const Color(0xFF4A3426);
  static final _glass = Paint()..color = const Color(0xFF1B2028);
  static final _bin = Paint()..color = const Color(0xFF2F4A34);
  static final _hull = Paint()..color = const Color(0xFF4A5262);
  static final _hullDark = Paint()..color = const Color(0xFF2E3440);
  static final _ember = Paint()..color = const Color(0xFF8AF0A0);
  static final _edge = Paint()
    ..color = const Color(0xFF0D0C0F)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  void render(Canvas canvas) {
    for (final b in props) {
      final r = b.rect;
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(5));
      if (b.name == 'debris') {
        // A torn slab of the ship's hull.
        final path = Path()
          ..moveTo(r.left + 3, r.top)
          ..lineTo(r.right, r.top + r.height * 0.2)
          ..lineTo(r.right - 4, r.bottom)
          ..lineTo(r.left, r.bottom - r.height * 0.25)
          ..close();
        canvas.drawPath(path, _hull);
        canvas.drawRect(r.deflate(min(r.width, r.height) / 3), _hullDark);
        canvas.drawCircle(r.center.translate(4, -2), 1.5, _ember);
        canvas.drawPath(path, _edge);
        continue;
      }
      if (b.name == 'dumpster') {
        canvas.drawRRect(rr, _bin);
        canvas.drawRect(r.deflate(4), _edge);
      } else {
        canvas.drawRRect(rr, _car);
        // Windscreen and rear window across the short side.
        final along = r.width > r.height;
        final s = along ? r.width : r.height;
        Rect glass(double from, double len) => along
            ? Rect.fromLTWH(r.left + s * from, r.top + 3, s * len, r.height - 6)
            : Rect.fromLTWH(r.left + 3, r.top + s * from, r.width - 6, s * len);
        canvas.drawRect(glass(0.22, 0.14), _glass);
        canvas.drawRect(glass(0.66, 0.1), _glass);
        canvas.drawCircle(r.center.translate(-3, 2), 3, _rust);
      }
      canvas.drawRRect(rr, _edge);
    }
  }
}

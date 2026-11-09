import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

/// Pushes a circle out of any rectangle it overlaps. Used by the player and
/// enemies so nobody walks through cars.
void pushOutOfRects(Vector2 p, double radius, List<Rect> rects) {
  for (final r in rects) {
    final cx = p.x.clamp(r.left, r.right);
    final cy = p.y.clamp(r.top, r.bottom);
    final dx = p.x - cx, dy = p.y - cy;
    final d2 = dx * dx + dy * dy;
    if (d2 >= radius * radius) continue;
    if (d2 > 0.0001) {
      final d = sqrt(d2);
      p.x += dx / d * (radius - d);
      p.y += dy / d * (radius - d);
    } else {
      // Centre is inside the rect: push out the shortest way.
      final left = p.x - r.left, right = r.right - p.x;
      final up = p.y - r.top, down = r.bottom - p.y;
      final m = [left, right, up, down].reduce((a, b) => a < b ? a : b);
      if (m == left) {
        p.x = r.left - radius;
      } else if (m == right) {
        p.x = r.right + radius;
      } else if (m == up) {
        p.y = r.top - radius;
      } else {
        p.y = r.bottom + radius;
      }
    }
  }
}

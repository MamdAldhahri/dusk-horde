import 'dart:collection';
import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

/// A grid over the arena where every walkable cell knows which way leads to
/// the player. One field serves every enemy, which keeps pathfinding cheap on
/// phones even with 60 zombies on screen.
class FlowField {
  FlowField({
    required this.bounds,
    required List<Rect> obstacles,
    this.cellSize = 16,
    double clearance = 8,
  }) : cols = (bounds.width / cellSize).ceil(),
       rows = (bounds.height / cellSize).ceil() {
    _blocked = List.filled(cols * rows, false);
    _cost = List.filled(cols * rows, _unreached);
    for (final o in obstacles) {
      final r = o.inflate(clearance);
      for (var y = 0; y < rows; y++) {
        for (var x = 0; x < cols; x++) {
          if (r.contains(_centreOf(x, y))) _blocked[y * cols + x] = true;
        }
      }
    }
  }

  final Rect bounds;
  final double cellSize;
  final int cols;
  final int rows;

  static const _unreached = 1 << 30;
  late final List<bool> _blocked;
  late final List<int> _cost;
  int _targetCell = -1;

  static const _dirs = [
    (1, 0, 10), (-1, 0, 10), (0, 1, 10), (0, -1, 10), //
    (1, 1, 14), (1, -1, 14), (-1, 1, 14), (-1, -1, 14),
  ];

  Offset _centreOf(int x, int y) => Offset(
    bounds.left + (x + 0.5) * cellSize,
    bounds.top + (y + 0.5) * cellSize,
  );

  int? cellAt(Vector2 p) {
    final x = ((p.x - bounds.left) / cellSize).floor();
    final y = ((p.y - bounds.top) / cellSize).floor();
    if (x < 0 || y < 0 || x >= cols || y >= rows) return null;
    return y * cols + x;
  }

  bool isBlocked(Vector2 p) {
    final c = cellAt(p);
    return c == null || _blocked[c];
  }

  /// Rebuilds the field toward [target]. Skips the work if the target is
  /// still in the same cell as last time.
  void update(Vector2 target) {
    final start = cellAt(target);
    if (start == null || start == _targetCell) return;
    _targetCell = start;
    _cost.fillRange(0, _cost.length, _unreached);
    // Dijkstra with a binary-heap-free trick: costs are small integers, so a
    // simple bucket queue is fast and exact.
    final buckets = SplayTreeMap<int, List<int>>();
    _cost[start] = 0;
    buckets[0] = [start];
    while (buckets.isNotEmpty) {
      final c = buckets.firstKey()!;
      final list = buckets.remove(c)!;
      for (final i in list) {
        if (_cost[i] != c) continue;
        final x = i % cols, y = i ~/ cols;
        for (final (dx, dy, w) in _dirs) {
          final nx = x + dx, ny = y + dy;
          if (nx < 0 || ny < 0 || nx >= cols || ny >= rows) continue;
          final n = ny * cols + nx;
          if (_blocked[n]) continue;
          // No cutting corners past a wall.
          if (dx != 0 &&
              dy != 0 &&
              (_blocked[y * cols + nx] || _blocked[ny * cols + x])) {
            continue;
          }
          final nc = c + w;
          if (nc < _cost[n]) {
            _cost[n] = nc;
            (buckets[nc] ??= []).add(n);
          }
        }
      }
    }
  }

  /// Unit vector to walk along from [p] toward the target, or zero when
  /// there's no path (or already in the target cell).
  Vector2 direction(Vector2 p) {
    final c = cellAt(p);
    if (c == null) {
      // Outside the arena (spawning in): walk straight toward the middle.
      final mid = Vector2(bounds.center.dx, bounds.center.dy);
      return (mid - p)..normalize();
    }
    if (c == _targetCell) return Vector2.zero();
    final x = c % cols, y = c ~/ cols;
    var best = _cost[c];
    int? bx, by;
    for (final (dx, dy, _) in _dirs) {
      final nx = x + dx, ny = y + dy;
      if (nx < 0 || ny < 0 || nx >= cols || ny >= rows) continue;
      final n = ny * cols + nx;
      if (_blocked[n]) continue;
      if (dx != 0 &&
          dy != 0 &&
          (_blocked[y * cols + nx] || _blocked[ny * cols + x])) {
        continue;
      }
      if (_cost[n] < best) {
        best = _cost[n];
        bx = dx;
        by = dy;
      }
    }
    if (bx == null) return Vector2.zero();
    final o = _centreOf(x + bx, y + by!);
    return Vector2(o.dx - p.x, o.dy - p.y)..normalize();
  }

  /// Distance in cells along the path (for tests and debugging).
  double pathCost(Vector2 p) {
    final c = cellAt(p);
    if (c == null || _cost[c] == _unreached) return double.infinity;
    return _cost[c] / 10;
  }

  static double angleOf(Vector2 v) => atan2(v.y, v.x);
}

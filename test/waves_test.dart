import 'dart:math';
import 'dart:ui';

import 'package:dusk_horde/game/enemies/enemy_type.dart';
import 'package:dusk_horde/game/waves/wave_plan.dart';
import 'package:dusk_horde/game/world/flow_field.dart';
import 'package:dusk_horde/game/world/obstacles.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WavePlan', () {
    const plan = WavePlan();
    test('wave 1 is 9 shamblers, no runners yet', () {
      final w = plan.wave(1, Random(1));
      expect(w.enemies.length, 9);
      expect(w.countOf(Zombies.runner), 0);
    });
    test('runners join from wave 3 and grow', () {
      expect(plan.wave(3, Random(1)).countOf(Zombies.runner), greaterThan(0));
      expect(
        plan.wave(8, Random(1)).countOf(Zombies.runner),
        greaterThan(plan.wave(3, Random(1)).countOf(Zombies.runner)),
      );
      expect(plan.wave(9, Random(1)).enemies.length, 33);
    });
    test('hp scales 8% per wave', () {
      expect(plan.hpScale(1), 1);
      expect(plan.hpScale(6), closeTo(1.4, 1e-9));
    });
  });

  group('FlowField', () {
    const bounds = Rect.fromLTRB(-160, -160, 160, 160);
    // A wall across the middle with a gap on the right.
    const wall = Rect.fromLTRB(-160, -8, 100, 8);
    final field = FlowField(bounds: bounds, obstacles: [wall]);

    test('walls are blocked', () {
      expect(field.isBlocked(Vector2(0, 0)), isTrue);
      expect(field.isBlocked(Vector2(0, -60)), isFalse);
    });

    test('path goes around the wall through the gap', () {
      field.update(Vector2(-100, 100)); // target below the wall, left side
      final from = Vector2(-100, -100); // above the wall, left side
      // Straight-line distance is 200 px = 12.5 cells; the detour is longer.
      expect(field.pathCost(from), greaterThan(20));
      // First step heads right, toward the gap.
      expect(field.direction(from).x, greaterThan(0.5));
    });

    test('in the target cell there is nowhere to go', () {
      field.update(Vector2(50, 100));
      expect(field.direction(Vector2(50, 100)).length, 0);
    });
  });

  test('pushOutOfRects moves a circle clear of a box', () {
    final p = Vector2(5, 0);
    pushOutOfRects(p, 4, [const Rect.fromLTRB(-10, -10, 3, 10)]);
    expect(p.x, closeTo(7, 1e-4));
  });
}

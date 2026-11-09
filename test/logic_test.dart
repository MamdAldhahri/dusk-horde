import 'package:dusk_horde/game/input/stick_math.dart';
import 'package:dusk_horde/game/player/dodge.dart';
import 'package:dusk_horde/game/weapons/magazine.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StickMath', () {
    test('dead zone reads as zero', () {
      expect(StickMath.normalise(Vector2(3, 0), 50).length, 0);
    });
    test('full push is length 1 and points the right way', () {
      final v = StickMath.normalise(Vector2(0, 200), 50);
      expect(v.length, closeTo(1, 1e-4));
      expect(v.y, closeTo(1, 1e-4));
    });
    test('half push is about half', () {
      expect(StickMath.normalise(Vector2(25, 0), 50).x, closeTo(0.5, 1e-4));
    });
    test('knob is clamped to the base', () {
      expect(
        StickMath.clampKnob(Vector2(300, 400), 50).length,
        closeTo(50, 1e-4),
      );
    });
  });

  group('Magazine', () {
    test('fire rate limits shots', () {
      final m = Magazine(size: 12, shotsPerSecond: 4, reloadSeconds: 1.2);
      expect(m.tryFire(), isTrue);
      expect(m.tryFire(), isFalse);
      m.update(0.26);
      expect(m.tryFire(), isTrue);
      expect(m.rounds, 10);
    });
    test('empty mag reloads automatically', () {
      final m = Magazine(size: 2, shotsPerSecond: 100, reloadSeconds: 1);
      m.tryFire();
      m.update(0.02);
      m.tryFire();
      expect(m.isReloading, isTrue);
      m.update(0.5);
      expect(m.tryFire(), isFalse);
      m.update(0.6);
      expect(m.rounds, 2);
      expect(m.tryFire(), isTrue);
    });
  });

  group('Dodge', () {
    test('roll, then cooldown, then ready again', () {
      final d = Dodge(duration: 0.25, cooldown: 1.5);
      expect(d.tryStart(), isTrue);
      expect(d.isInvincible, isTrue);
      expect(d.tryStart(), isFalse);
      d.update(0.3);
      expect(d.isRolling, isFalse);
      expect(d.isReady, isFalse);
      d.update(1.3);
      expect(d.isReady, isTrue);
    });
  });
}

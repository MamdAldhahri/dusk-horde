import 'package:flame/components.dart';

/// Pure math for a virtual joystick, kept separate so it can be unit tested.
class StickMath {
  StickMath._();

  /// Turns a knob offset (pixels from the stick centre) into a vector of
  /// length 0..1. Offsets inside [deadZone] (fraction of [radius]) read as 0.
  static Vector2 normalise(
    Vector2 offset,
    double radius, {
    double deadZone = 0.12,
  }) {
    final length = offset.length;
    if (radius <= 0 || length <= radius * deadZone) return Vector2.zero();
    final clamped = length > radius ? radius : length;
    return offset.normalized()..scale(clamped / radius);
  }

  /// Clamps the knob offset so it never leaves the stick base.
  static Vector2 clampKnob(Vector2 offset, double radius) {
    if (offset.length <= radius) return offset.clone();
    return offset.normalized()..scale(radius);
  }
}

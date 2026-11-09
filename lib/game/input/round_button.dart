import 'dart:math';
import 'dart:ui' hide TextStyle;

import 'package:flutter/painting.dart' show TextStyle;

import 'package:flame/components.dart';
import 'package:flame/events.dart';

/// A round HUD button with a label and an optional cooldown ring.
class RoundButton extends PositionComponent with TapCallbacks {
  RoundButton({
    required this.label,
    required this.onPressed,
    this.cooldownFraction,
  }) : super(anchor: Anchor.center);

  final String label;
  final void Function() onPressed;

  /// Returns 0 when ready, up to 1 right after use. Null = no ring.
  final double Function()? cooldownFraction;

  static final _fill = Paint()..color = const Color(0x2EFFFFFF);
  static final _ring = Paint()
    ..color = const Color(0x55FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final _cooldown = Paint()..color = const Color(0x88000000);

  late final TextComponent _text = TextComponent(
    text: label,
    anchor: Anchor.center,
    textRenderer: TextPaint(
      style: const TextStyle(
        color: Color(0xCCFFFFFF),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  @override
  Future<void> onLoad() async => add(_text);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final d = (size.y * 0.15).clamp(48.0, 84.0);
    this.size = Vector2.all(d);
    _text.position = this.size / 2;
  }

  @override
  bool containsLocalPoint(Vector2 point) =>
      (point - size / 2).length <= size.x / 2;

  @override
  void onTapDown(TapDownEvent event) => onPressed();

  @override
  void render(Canvas canvas) {
    final c = (size / 2).toOffset();
    final r = size.x / 2;
    canvas.drawCircle(c, r, _fill);
    canvas.drawCircle(c, r, _ring);
    final f = cooldownFraction?.call() ?? 0;
    if (f > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -pi / 2,
        2 * pi * f,
        true,
        _cooldown,
      );
    }
  }
}

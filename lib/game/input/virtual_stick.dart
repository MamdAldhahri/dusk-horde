import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import 'stick_math.dart';

/// A floating thumb stick that covers one half of the screen. It appears where
/// the thumb lands and reports [vector] (length 0..1) while held.
class VirtualStick extends PositionComponent with DragCallbacks {
  VirtualStick({required this.leftSide});

  final bool leftSide;

  /// Current input, length 0..1. Zero when untouched.
  Vector2 vector = Vector2.zero();

  bool get isActive => _pointer != null;

  int? _pointer;
  final Vector2 _centre = Vector2.zero();
  final Vector2 _knob = Vector2.zero();

  double get _radius => (size.y * 0.16).clamp(36, 80);

  static final _basePaint = Paint()
    ..color = const Color(0x33FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final _baseFill = Paint()..color = const Color(0x1AFFFFFF);
  static final _knobPaint = Paint()..color = const Color(0x66FFFFFF);
  static final _hintPaint = Paint()
    ..color = const Color(0x22FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = Vector2(size.x / 2, size.y);
    position = Vector2(leftSide ? 0 : size.x / 2, 0);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_pointer != null) return;
    _pointer = event.pointerId;
    _centre.setFrom(event.localPosition);
    _knob.setZero();
    vector = Vector2.zero();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (event.pointerId != _pointer) return;
    _knob.add(event.canvasDelta);
    _knob.setFrom(StickMath.clampKnob(_knob, _radius * 1.4));
    vector = StickMath.normalise(_knob, _radius);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (event.pointerId == _pointer) _release();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    if (event.pointerId == _pointer) _release();
  }

  void _release() {
    _pointer = null;
    _knob.setZero();
    vector = Vector2.zero();
  }

  @override
  void render(Canvas canvas) {
    if (_pointer == null) {
      // Faint hint so new players know where to put their thumbs.
      final hint = Offset(
        leftSide ? size.x * 0.28 : size.x * 0.72,
        size.y * 0.72,
      );
      canvas.drawCircle(hint, _radius, _hintPaint);
      return;
    }
    final c = _centre.toOffset();
    final knob = StickMath.clampKnob(_knob, _radius);
    canvas.drawCircle(c, _radius, _baseFill);
    canvas.drawCircle(c, _radius, _basePaint);
    canvas.drawCircle(c + knob.toOffset(), _radius * 0.42, _knobPaint);
  }
}

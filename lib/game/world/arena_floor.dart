import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

/// Placeholder ground: dark asphalt with grit, faded road markings and a hard
/// border. Replaced by a Tiled map in M3.
class ArenaFloor extends PositionComponent {
  ArenaFloor(this.bounds) : super(priority: -10);

  final Rect bounds;
  late final Picture _picture = _paint();

  Picture _paint() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(bounds, Paint()..color = const Color(0xFF222226));
    final rnd = Random(3);
    final grit = Paint();
    for (var i = 0; i < 2600; i++) {
      final v = [28, 31, 40, 46][rnd.nextInt(4)];
      grit.color = Color.fromARGB(255, v, v, v + 3);
      canvas.drawRect(
        Rect.fromLTWH(
          bounds.left + rnd.nextDouble() * bounds.width,
          bounds.top + rnd.nextDouble() * bounds.height,
          1,
          1,
        ),
        grit,
      );
    }
    final mark = Paint()..color = const Color(0xFF6E6544);
    for (var x = bounds.left + 20; x < bounds.right - 40; x += 64) {
      canvas.drawRect(Rect.fromLTWH(x, -1, 30, 3), mark);
    }
    final blood = Paint()..color = const Color(0xFF3E0A0C);
    for (final c in const [
      Offset(-220, -120),
      Offset(260, 140),
      Offset(140, -170),
    ]) {
      canvas.drawOval(Rect.fromCenter(center: c, width: 34, height: 18), blood);
    }
    canvas.drawRect(
      bounds,
      Paint()
        ..color = const Color(0xFF0B0A0C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
    return recorder.endRecording();
  }

  @override
  void render(Canvas canvas) => canvas.drawPicture(_picture);
}

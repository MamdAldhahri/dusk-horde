import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../dusk_horde_game.dart';

/// Darkness over the whole arena with a soft glow around the player and a
/// cone of light where they aim. The core of the horror look.
class Flashlight extends Component with HasGameReference<DuskHordeGame> {
  Flashlight() : super(priority: 100);

  static const coneLength = 240.0;
  static const coneHalfAngle = 0.42; // radians, about 24 degrees
  static const glowRadius = 64.0;

  final _dark = Paint()..color = const Color(0xE6050407);
  final _cut = Paint()..blendMode = BlendMode.dstOut;
  final _layer = Paint();

  /// True when [point] is inside the beam. Stalkers (M5) use this.
  bool lights(Vector2 point) {
    final p = game.player;
    final to = point - p.position;
    if (to.length > coneLength) return to.length < glowRadius;
    var diff = atan2(to.y, to.x) - p.aimAngle;
    diff = atan2(sin(diff), cos(diff));
    return diff.abs() <= coneHalfAngle || to.length < glowRadius;
  }

  @override
  void render(Canvas canvas) {
    final p = game.player.position.toOffset();
    final area = game.arena.inflate(400);
    canvas.saveLayer(area, _layer);
    canvas.drawRect(area, _dark);

    _cut.shader = Gradient.radial(p, glowRadius, const [
      Color(0xDDFFFFFF),
      Color(0x00FFFFFF),
    ]);
    canvas.drawCircle(p, glowRadius, _cut);

    final a = game.player.aimAngle;
    final cone = Path()
      ..moveTo(p.dx, p.dy)
      ..arcTo(
        Rect.fromCircle(center: p, radius: coneLength),
        a - coneHalfAngle,
        coneHalfAngle * 2,
        false,
      )
      ..close();
    _cut.shader = Gradient.radial(
      p,
      coneLength,
      const [Color(0xFFFFFFFF), Color(0xCCFFFFFF), Color(0x00FFFFFF)],
      const [0, 0.55, 1],
    );
    canvas.drawPath(cone, _cut);
    canvas.restore();
  }
}

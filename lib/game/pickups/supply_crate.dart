import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../dusk_horde_game.dart';
import '../waves/wave_manager.dart';

/// Opens during each breather: walk into it to patch up (+[heal] HP) and
/// refill every gun's spare ammo, once per breather.
class SupplyCrate extends PositionComponent
    with HasGameReference<DuskHordeGame> {
  SupplyCrate(Vector2 at)
    : super(
        position: at,
        size: Vector2(22, 16),
        anchor: Anchor.center,
        priority: 2,
      );

  static const heal = 35.0;
  static const useRange = 20.0;

  /// The wave number whose breather was already used.
  int _usedAfterWave = -1;
  double _t = 0;

  bool get isOpen =>
      game.waves.phase == WavePhase.breather &&
      game.waves.wave > 0 &&
      _usedAfterWave != game.waves.wave;

  static final _wood = Paint()..color = const Color(0xFF5A4630);
  static final _band = Paint()..color = const Color(0xFF2E241A);
  static final _glow = Paint()..color = const Color(0xFF7CFF7A);

  void reset() => _usedAfterWave = -1;

  @override
  void update(double dt) {
    _t += dt;
    if (!isOpen) return;
    final p = game.player;
    if (p.position.distanceTo(position) < useRange) {
      if (p.hp < p.maxHealth) p.heal(heal);
      p.refillAmmo();
      _usedAfterWave = game.waves.wave;
    }
  }

  @override
  void render(Canvas canvas) {
    if (isOpen) {
      _glow.color = Color.fromARGB(
        (60 + 50 * sin(_t * 4)).round().clamp(0, 255),
        124,
        255,
        122,
      );
      canvas.drawCircle((size / 2).toOffset(), 20, _glow);
    }
    canvas.drawRect(size.toRect(), _wood);
    canvas.drawRect(Rect.fromLTWH(0, 6, size.x, 3), _band);
    canvas.drawRect(Rect.fromLTWH(9, 0, 4, size.y), _band);
  }
}

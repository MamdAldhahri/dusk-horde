/// Dodge roll timing: a short burst of speed with invincibility, then a
/// cooldown. Pure logic, no rendering.
class Dodge {
  Dodge({this.duration = 0.25, this.cooldown = 1.5});

  final double duration;
  final double cooldown;

  double _active = 0;
  double _cooldown = 0;

  bool get isRolling => _active > 0;
  bool get isInvincible => isRolling;
  bool get isReady => _cooldown <= 0;

  /// 1 right after a roll, falling to 0 when ready again.
  double get cooldownFraction => isReady ? 0 : _cooldown / cooldown;

  bool tryStart() {
    if (!isReady) return false;
    _active = duration;
    _cooldown = cooldown;
    return true;
  }

  void update(double dt) {
    if (_active > 0) _active -= dt;
    if (_cooldown > 0) _cooldown -= dt;
  }
}

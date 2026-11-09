/// Ammo, fire rate and reload for one gun. Pure logic, no rendering.
class Magazine {
  Magazine({
    required this.size,
    required this.shotsPerSecond,
    required this.reloadSeconds,
    this.reserve,
    this.maxReserve,
  }) : rounds = size;

  final int size;
  final double shotsPerSecond;
  final double reloadSeconds;

  int rounds;

  /// Spare rounds. Null = infinite.
  int? reserve;
  final int? maxReserve;

  double _shotTimer = 0;
  double _reloadTimer = 0;

  bool get isReloading => _reloadTimer > 0;
  bool get isInfinite => reserve == null;

  /// Nothing loaded and nothing spare.
  bool get isDry => rounds == 0 && (reserve ?? 1) == 0;

  /// 0..1 progress of the current reload (0 when not reloading).
  double get reloadProgress =>
      isReloading ? 1 - _reloadTimer / reloadSeconds : 0;

  void update(double dt) {
    if (_shotTimer > 0) _shotTimer -= dt;
    if (_reloadTimer > 0) {
      _reloadTimer -= dt;
      if (_reloadTimer <= 0) {
        _reloadTimer = 0;
        final want = size - rounds;
        final spare = reserve;
        if (spare == null) {
          rounds = size;
        } else {
          final take = want < spare ? want : spare;
          rounds += take;
          reserve = spare - take;
        }
      }
    }
  }

  /// Tries to fire one round. Starts a reload automatically when empty.
  bool tryFire() {
    if (isReloading || _shotTimer > 0) return false;
    if (rounds <= 0) {
      reload();
      return false;
    }
    rounds--;
    _shotTimer = 1 / shotsPerSecond;
    if (rounds == 0) reload();
    return true;
  }

  void reload() {
    if (isReloading || rounds == size || (reserve ?? 1) == 0) return;
    _reloadTimer = reloadSeconds;
  }

  /// Adds spare ammo, up to [maxReserve].
  void addReserve(int amount) {
    final r = reserve;
    if (r == null) return;
    final cap = maxReserve;
    reserve = cap == null ? r + amount : (r + amount).clamp(0, cap);
  }
}

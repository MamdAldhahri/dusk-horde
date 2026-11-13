/// Player preferences, saved with [Progress].
class Settings {
  Settings({
    this.stickScale = 1,
    this.aimAssist = 1,
    this.sfxVolume = 0.8,
    this.musicVolume = 0.5,
  });

  /// Thumb-stick size, 0.7 (small) to 1.4 (large).
  double stickScale;

  /// How strongly aim snaps toward targets, 0 (off) to 1 (full 15 degrees).
  double aimAssist;

  /// 0 to 1.
  double sfxVolume;
  double musicVolume;

  static const minStick = 0.7;
  static const maxStick = 1.4;

  Map<String, Object?> toJson() => {
    'stickScale': stickScale,
    'aimAssist': aimAssist,
    'sfxVolume': sfxVolume,
    'musicVolume': musicVolume,
  };

  factory Settings.fromJson(Map<String, Object?>? j) {
    double read(String k, double def, double lo, double hi) =>
        ((j?[k] as num?)?.toDouble() ?? def).clamp(lo, hi);
    return Settings(
      stickScale: read('stickScale', 1, minStick, maxStick),
      aimAssist: read('aimAssist', 1, 0, 1),
      sfxVolume: read('sfxVolume', 0.8, 0, 1),
      musicVolume: read('musicVolume', 0.5, 0, 1),
    );
  }
}

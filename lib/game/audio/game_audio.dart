import 'package:flame_audio/flame_audio.dart';

/// Every sound effect. Files live in `assets/audio/` as `<file>.ogg`;
/// replace one with a real recording of the same name at any time.
enum Sfx {
  pistol('pistol'),
  smg('smg'),
  shotgun('shotgun'),
  rifle('rifle'),
  empty('empty'),
  reload('reload'),
  hit('hit'),
  zombieDie('zombie_die'),
  alienDie('alien_die'),
  explosion('explosion'),
  hurt('hurt'),
  dodge('dodge'),
  pickup('pickup'),
  plasma('plasma'),
  beam('beam'),
  bossRoar('boss_roar'),
  waveStart('wave_start'),
  unlock('unlock'),
  dawn('dawn');

  const Sfx(this.file);
  final String file;
  String get path => '$file.ogg';

  /// Guns fire fast, so they get a pool of players each.
  bool get isGun =>
      this == pistol || this == smg || this == rifle || this == shotgun;
}

/// What the game calls to make noise. The real one plays through
/// flame_audio; tests use [SilentAudio], which just records the calls.
abstract class GameAudio {
  double sfxVolume = 0.8;
  double musicVolume = 0.5;

  /// The same effect at most once per [minGap] seconds, so six shotgun
  /// pellets landing at once make one hit sound, not six stacked ones.
  static const minGap = 0.04;
  final Map<Sfx, double> _last = {};

  /// Seconds since some fixed point; overridable for tests.
  double now() => DateTime.now().microsecondsSinceEpoch / 1e6;

  Future<void> load() async {}

  void play(Sfx s, {double volume = 1}) {
    final t = now();
    final last = _last[s];
    if (last != null && t - last < minGap) return;
    _last[s] = t;
    if (sfxVolume <= 0) return;
    emit(s, (volume * sfxVolume).clamp(0.0, 1.0));
  }

  /// Actually plays [s] at [volume] (already scaled by [sfxVolume]).
  void emit(Sfx s, double volume);

  void playMusic(String file);
  void stopMusic();
  void pauseMusic();
  void resumeMusic();

  /// Applies new volumes, including to music that is already playing.
  void setVolumes({required double sfx, required double music}) {
    sfxVolume = sfx;
    musicVolume = music;
  }
}

/// No sound at all; remembers what would have played.
class SilentAudio extends GameAudio {
  final List<Sfx> played = [];
  String? music;
  bool musicPaused = false;

  @override
  void emit(Sfx s, double volume) => played.add(s);

  @override
  void playMusic(String file) {
    music = file;
    musicPaused = false;
  }

  @override
  void stopMusic() => music = null;

  @override
  void pauseMusic() => musicPaused = true;

  @override
  void resumeMusic() => musicPaused = false;
}

/// Plays through flame_audio: pooled players for guns, one-shots for the
/// rest, and the background-music player for the level loops.
class FlameGameAudio extends GameAudio {
  final Map<Sfx, AudioPool> _pools = {};
  String? _music;

  @override
  Future<void> load() async {
    try {
      await FlameAudio.bgm.initialize();
      await FlameAudio.audioCache.loadAll([
        for (final s in Sfx.values) s.path,
        'music_gas_station.ogg',
        'music_crash_site.ogg',
      ]);
      for (final s in Sfx.values.where((s) => s.isGun)) {
        _pools[s] = await FlameAudio.createPool(
          s.path,
          maxPlayers: s == Sfx.smg ? 6 : 3,
        );
      }
    } on Object {
      // A phone without working audio still plays the game, silently.
    }
  }

  @override
  void emit(Sfx s, double volume) {
    final pool = _pools[s];
    if (pool != null) {
      pool.start(volume: volume).ignore();
    } else {
      FlameAudio.play(s.path, volume: volume).ignore();
    }
  }

  @override
  void playMusic(String file) {
    if (_music == file && FlameAudio.bgm.isPlaying) return;
    _music = file;
    if (musicVolume <= 0) return;
    FlameAudio.bgm.play(file, volume: musicVolume).ignore();
  }

  @override
  void stopMusic() {
    _music = null;
    FlameAudio.bgm.stop().ignore();
  }

  @override
  void pauseMusic() => FlameAudio.bgm.pause().ignore();

  @override
  void resumeMusic() {
    if (_music != null && musicVolume > 0) FlameAudio.bgm.resume().ignore();
  }

  @override
  void setVolumes({required double sfx, required double music}) {
    final wasSilent = musicVolume <= 0;
    super.setVolumes(sfx: sfx, music: music);
    final m = _music;
    if (m == null) return;
    if (music <= 0) {
      FlameAudio.bgm.pause().ignore();
    } else if (wasSilent) {
      FlameAudio.bgm.play(m, volume: music).ignore();
    } else {
      FlameAudio.bgm.audioPlayer.setVolume(music).ignore();
    }
  }
}

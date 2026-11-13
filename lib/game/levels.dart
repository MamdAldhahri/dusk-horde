import 'waves/wave_plan.dart';

/// One playable apocalypse: its map, its waves and its boss.
class LevelDef {
  const LevelDef({
    required this.id,
    required this.number,
    required this.name,
    required this.apocalypse,
    required this.mapFile,
    required this.plan,
    required this.bossName,
    required this.music,
    this.unlockText = '',
  });

  final String id;
  final int number;
  final String name;
  final String apocalypse;

  /// Under `assets/tiles/`.
  final String mapFile;
  final WavePlan plan;
  final String bossName;

  /// Looping track under `assets/audio/`.
  final String music;

  /// How to open it, shown on the workbench while locked.
  final String unlockText;
}

class Levels {
  Levels._();

  static const gasStation = LevelDef(
    id: 'gas_station',
    number: 1,
    name: 'The Gas Station',
    apocalypse: 'Zombie outbreak',
    mapFile: 'gas_station.tmx',
    plan: ZombiePlan(),
    bossName: 'THE BRUTE',
    music: 'music_gas_station.ogg',
  );

  static const crashSite = LevelDef(
    id: 'crash_site',
    number: 2,
    name: 'The Crash Site',
    apocalypse: 'Alien invasion',
    mapFile: 'crash_site.tmx',
    plan: AlienPlan(),
    bossName: 'THE WARDEN',
    music: 'music_crash_site.ogg',
    unlockText: 'Survive the night at the Gas Station',
  );

  static const all = [gasStation, crashSite];

  static LevelDef byId(String id) =>
      all.firstWhere((l) => l.id == id, orElse: () => gasStation);
}

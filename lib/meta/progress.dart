import 'dart:convert';

import 'perks.dart';
import 'settings.dart';
import 'weapon_catalog.dart';

export 'settings.dart';

/// Everything that carries over between runs: banked scrap, boss cores,
/// unlocks, upgrade choices and perks. Saved as JSON.
class Progress {
  Progress({
    this.scrap = 0,
    this.cores = 0,
    this.bestWave = 0,
    Set<String>? unlocked,
    Map<String, List<int?>>? tiers,
    Map<String, int>? perks,
    List<String>? loadout,
    Set<String>? beaten,
    Map<String, int>? bestWaves,
    Map<String, int>? endlessBest,
    this.level = 'gas_station',
    this.endless = false,
    this.testMode = false,
    Settings? settings,
  }) : settings = settings ?? Settings(),
       unlocked = unlocked ?? {'pistol'},
       tiers = tiers ?? {},
       perks = perks ?? {},
       loadout = loadout ?? ['pistol'],
       beaten = beaten ?? {},
       bestWaves = bestWaves ?? {},
       endlessBest = endlessBest ?? {};

  int scrap;
  int cores;
  int bestWave;
  final Set<String> unlocked;

  /// Per weapon: five slots, one per tier. Tiers 1-4 hold the chosen option
  /// (0 or 1), tier 5 holds 0 once bought. Null = not bought.
  final Map<String, List<int?>> tiers;
  final Map<String, int> perks;

  /// The guns taken into a run, in swap order (up to 2).
  final List<String> loadout;

  /// Levels survived until dawn at least once.
  final Set<String> beaten;

  /// Best wave reached per level, story and Endless.
  final Map<String, int> bestWaves;
  final Map<String, int> endlessBest;

  /// The level and mode picked on the workbench.
  String level;
  bool endless;

  /// Stick size, aim assist and volumes.
  final Settings settings;

  /// Test Mode (debug builds only): easy fights, everything open.
  bool testMode;

  /// Owned, or borrowed for Test Mode.
  bool hasGun(String id) => testMode || unlocked.contains(id);

  /// Level 1 is always open; each level opens the next once beaten.
  bool isLevelOpen(String id) =>
      testMode ||
      switch (id) {
        'gas_station' => true,
        'crash_site' => beaten.contains('gas_station'),
        _ => false,
      };

  /// Beating Level 2 opens Endless on both maps.
  bool get endlessOpen => testMode || beaten.contains('crash_site');

  List<int?> tiersOf(String weapon) =>
      tiers.putIfAbsent(weapon, () => List<int?>.filled(5, null));

  /// How many tiers of [weapon] are bought (they are bought in order).
  int tierCount(String weapon) =>
      tiersOf(weapon).takeWhile((t) => t != null).length;

  bool hasSignature(String weapon) => tiersOf(weapon)[4] != null;

  int perkLevel(String id) => perks[id] ?? 0;

  /// Why the next tier can't be bought right now, or null if it can.
  String? whyNotBuyTier(String weapon) {
    if (!hasGun(weapon)) return 'Locked';
    final n = tierCount(weapon);
    if (n >= 5) return 'Maxed';
    if (scrap < tierCosts[n]) return 'Need ${tierCosts[n]} scrap';
    if (n == 4 && cores < tierFiveCores) return 'Need a boss core';
    return null;
  }

  /// Buys the next tier. For tiers 1-4 pass which option (0 or 1).
  bool buyTier(String weapon, {int choice = 0}) {
    if (whyNotBuyTier(weapon) != null) return false;
    final n = tierCount(weapon);
    scrap -= tierCosts[n];
    if (n == 4) cores -= tierFiveCores;
    tiersOf(weapon)[n] = n == 4 ? 0 : choice;
    return true;
  }

  /// Switches an already-bought tier to its other option, for free.
  bool respec(String weapon, int tier, int choice) {
    final t = tiersOf(weapon);
    if (tier >= 4 || t[tier] == null) return false;
    t[tier] = choice;
    return true;
  }

  bool buyPerk(PerkDef perk) {
    final lvl = perkLevel(perk.id);
    if (lvl >= perk.maxLevel || scrap < perk.costs[lvl]) return false;
    scrap -= perk.costs[lvl];
    perks[perk.id] = lvl + 1;
    return true;
  }

  /// [weapon]'s stats with every bought tier applied.
  WeaponStats statsFor(WeaponDef weapon) {
    var s = weapon.base;
    final t = tiersOf(weapon.id);
    for (var i = 0; i < 4; i++) {
      final c = t[i];
      if (c == null) break;
      final (a, b) = standardTiers[i];
      s = (c == 0 ? a : b).apply(s);
    }
    return s;
  }

  double get maxHp => 100 + 15.0 * perkLevel(Perks.tough.id);
  double get dodgeCooldownScale => 1 - 0.15 * perkLevel(Perks.nimble.id);
  double get scrapScale => 1 + 0.2 * perkLevel(Perks.scavenger.id);

  void unlock(String weapon) {
    if (unlocked.add(weapon) && loadout.length < 2) loadout.add(weapon);
  }

  /// Adds a finished run's takings.
  void bank({
    required int scrap,
    required int cores,
    required int wave,
    String level = 'gas_station',
    bool endless = false,
  }) {
    this.scrap += scrap;
    this.cores += cores;
    if (wave > bestWave) bestWave = wave;
    final best = endless ? endlessBest : bestWaves;
    if (wave > (best[level] ?? 0)) best[level] = wave;
  }

  Map<String, Object?> toJson() => {
    'v': 2,
    'scrap': scrap,
    'cores': cores,
    'bestWave': bestWave,
    'unlocked': unlocked.toList(),
    'tiers': tiers,
    'perks': perks,
    'loadout': loadout,
    'beaten': beaten.toList(),
    'bestWaves': bestWaves,
    'endlessBest': endlessBest,
    'level': level,
    'endless': endless,
    'testMode': testMode,
    'settings': settings.toJson(),
  };

  static Map<String, int> _intMap(Object? m) => {
    for (final e in ((m as Map?) ?? {}).entries)
      e.key as String: (e.value as num).toInt(),
  };

  factory Progress.fromJson(Map<String, Object?> j) => Progress(
    scrap: (j['scrap'] as num?)?.toInt() ?? 0,
    cores: (j['cores'] as num?)?.toInt() ?? 0,
    bestWave: (j['bestWave'] as num?)?.toInt() ?? 0,
    unlocked: {...?(j['unlocked'] as List?)?.cast<String>()},
    tiers: {
      for (final e in ((j['tiers'] as Map?) ?? {}).entries)
        e.key as String: [
          for (final v in (e.value as List)) (v as num?)?.toInt(),
        ],
    },
    perks: _intMap(j['perks']),
    loadout: (j['loadout'] as List?)?.cast<String>().toList(),
    beaten: {...?(j['beaten'] as List?)?.cast<String>()},
    bestWaves: _intMap(j['bestWaves']),
    endlessBest: _intMap(j['endlessBest']),
    level: j['level'] as String? ?? 'gas_station',
    endless: j['endless'] as bool? ?? false,
    testMode: j['testMode'] as bool? ?? false,
    settings: Settings.fromJson(
      (j['settings'] as Map?)?.cast<String, Object?>(),
    ),
  )..unlocked.add('pistol');

  String encode() => jsonEncode(toJson());
  static Progress decode(String s) =>
      Progress.fromJson(jsonDecode(s) as Map<String, Object?>);
}

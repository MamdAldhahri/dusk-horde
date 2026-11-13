/// Weapon stats and upgrade trees, as plain data. No Flame here, so all of
/// this is unit tested directly.
library;

/// One gun's numbers after upgrades.
class WeaponStats {
  const WeaponStats({
    required this.damage,
    required this.shotsPerSecond,
    required this.magazine,
    required this.reloadSeconds,
    this.reserve,
    this.spread = 0.06,
    this.pierce = 0,
    this.critChance = 0,
    this.pellets = 1,
    this.range = 390,
  });

  final double damage;
  final double shotsPerSecond;
  final int magazine;
  final double reloadSeconds;

  /// Spare rounds carried. Null = infinite (the pistol).
  final int? reserve;

  /// Random aim wobble, radians.
  final double spread;

  /// Extra enemies a bullet passes through.
  final int pierce;

  /// Chance of a double-damage hit.
  final double critChance;

  /// Bullets per shot, fanned across [spread] (the shotgun).
  final int pellets;

  /// How far a bullet flies, pixels.
  final double range;

  WeaponStats copyWith({
    double? damage,
    double? shotsPerSecond,
    int? magazine,
    double? reloadSeconds,
    int? reserve,
    int? pierce,
    double? critChance,
  }) => WeaponStats(
    damage: damage ?? this.damage,
    shotsPerSecond: shotsPerSecond ?? this.shotsPerSecond,
    magazine: magazine ?? this.magazine,
    reloadSeconds: reloadSeconds ?? this.reloadSeconds,
    reserve: reserve ?? this.reserve,
    spread: spread,
    pierce: pierce ?? this.pierce,
    critChance: critChance ?? this.critChance,
    pellets: pellets,
    range: range,
  );
}

/// One choice inside an upgrade tier.
class UpgradeOption {
  const UpgradeOption(this.label, this.apply);
  final String label;
  final WeaponStats Function(WeaponStats) apply;
}

/// Tier 5: the signature mod that changes how a gun plays.
enum Signature {
  /// Pistol: the last bullet in the magazine deals 3x damage.
  lastWord,

  /// SMG: hits stack a bleed on the target.
  shredder,

  /// Shotgun: pellets set targets on fire.
  dragonsBreath,

  /// Rifle: stand still for a second and the next shot pierces.
  marksman,
}

class WeaponDef {
  const WeaponDef({
    required this.id,
    required this.name,
    required this.base,
    required this.signature,
    required this.signatureName,
    required this.signatureText,
    required this.unlockText,
  });

  final String id;
  final String name;
  final WeaponStats base;
  final Signature signature;
  final String signatureName;
  final String signatureText;

  /// How to unlock it, shown on the workbench while locked.
  final String unlockText;
}

int _pct(int v, double f) => (v * f).round();

/// Tiers 1 to 4, the same tree for every gun: pick one of two per tier.
final List<(UpgradeOption, UpgradeOption)> standardTiers = [
  (
    UpgradeOption('+15% damage', (s) => s.copyWith(damage: s.damage * 1.15)),
    UpgradeOption(
      '+20% magazine',
      (s) => s.copyWith(magazine: _pct(s.magazine, 1.2)),
    ),
  ),
  (
    UpgradeOption(
      '+15% fire rate',
      (s) => s.copyWith(shotsPerSecond: s.shotsPerSecond * 1.15),
    ),
    UpgradeOption(
      '-20% reload time',
      (s) => s.copyWith(reloadSeconds: s.reloadSeconds * 0.8),
    ),
  ),
  (
    UpgradeOption('+1 pierce', (s) => s.copyWith(pierce: s.pierce + 1)),
    UpgradeOption(
      '+25% crit chance',
      (s) => s.copyWith(critChance: s.critChance + 0.25),
    ),
  ),
  (
    UpgradeOption('+20% damage', (s) => s.copyWith(damage: s.damage * 1.2)),
    UpgradeOption(
      '+30% ammo capacity',
      (s) => s.reserve == null
          ? s.copyWith(magazine: _pct(s.magazine, 1.3))
          : s.copyWith(reserve: _pct(s.reserve!, 1.3)),
    ),
  ),
];

/// Scrap price of tiers 1 to 5. Tier 5 also needs one boss core.
const tierCosts = [100, 200, 350, 550, 800];
const tierFiveCores = 1;

class Weapons {
  Weapons._();

  static const pistol = WeaponDef(
    id: 'pistol',
    name: 'Pistol',
    base: WeaponStats(
      damage: 10,
      shotsPerSecond: 4,
      magazine: 12,
      reloadSeconds: 1.2,
    ),
    signature: Signature.lastWord,
    signatureName: 'Last Word',
    signatureText: 'The last bullet in each magazine deals 3x damage.',
    unlockText: '',
  );

  static const smg = WeaponDef(
    id: 'smg',
    name: 'SMG',
    base: WeaponStats(
      damage: 6,
      shotsPerSecond: 11,
      magazine: 30,
      reloadSeconds: 1.6,
      reserve: 150,
      spread: 0.14,
    ),
    signature: Signature.shredder,
    signatureName: 'Shredder',
    signatureText: 'Hits stack a bleed: 2 damage a second per stack, up to 5.',
    unlockText: 'Reach wave 5 at the Gas Station',
  );

  static const shotgun = WeaponDef(
    id: 'shotgun',
    name: 'Shotgun',
    base: WeaponStats(
      damage: 7,
      pellets: 6,
      shotsPerSecond: 1.4,
      magazine: 6,
      reloadSeconds: 2.0,
      reserve: 36,
      spread: 0.42,
      range: 190,
    ),
    signature: Signature.dragonsBreath,
    signatureName: "Dragon's Breath",
    signatureText: 'Pellets set targets on fire: 5 damage a second for 3 s.',
    unlockText: 'Survive the night at the Gas Station',
  );

  static const rifle = WeaponDef(
    id: 'rifle',
    name: 'Assault Rifle',
    base: WeaponStats(
      damage: 15,
      shotsPerSecond: 6.5,
      magazine: 24,
      reloadSeconds: 1.8,
      reserve: 120,
      spread: 0.04,
      range: 520,
    ),
    signature: Signature.marksman,
    signatureName: 'Marksman',
    signatureText:
        'Stand still for 1 s: the next shot pierces 3 targets and hits twice '
        'as hard.',
    unlockText: 'Reach wave 8 at the Crash Site',
  );

  static const all = [pistol, smg, shotgun, rifle];

  static WeaponDef byId(String id) => all.firstWhere((w) => w.id == id);
}

import '../../meta/weapon_catalog.dart';
import 'magazine.dart';

/// A gun in the player's hands for one run: its definition, its upgraded
/// stats and its ammo.
class Gun {
  Gun(this.def, this.stats, {this.hasSignature = false})
    : mag = Magazine(
        size: stats.magazine,
        shotsPerSecond: stats.shotsPerSecond,
        reloadSeconds: stats.reloadSeconds,
        reserve: stats.reserve,
        maxReserve: stats.reserve,
      );

  final WeaponDef def;
  final WeaponStats stats;
  final bool hasSignature;
  final Magazine mag;

  String get name => def.name;
}

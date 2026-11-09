/// Survivor perks: bought with the same scrap as gun upgrades.
class PerkDef {
  const PerkDef(this.id, this.name, this.perLevel, this.costs);
  final String id;
  final String name;

  /// What one level gives, shown on the workbench.
  final String perLevel;
  final List<int> costs;
  int get maxLevel => costs.length;
}

class Perks {
  Perks._();

  static const tough = PerkDef('tough', 'Tough', '+15 max HP', [150, 300, 500]);
  static const nimble = PerkDef('nimble', 'Nimble', '-15% dodge cooldown', [
    200,
    400,
  ]);
  static const scavenger = PerkDef('scavenger', 'Scavenger', '+20% scrap', [
    250,
    500,
  ]);

  static const all = [tough, nimble, scavenger];
}

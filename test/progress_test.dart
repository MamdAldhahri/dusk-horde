import 'package:dusk_horde/game/weapons/magazine.dart';
import 'package:dusk_horde/meta/perks.dart';
import 'package:dusk_horde/meta/progress.dart';
import 'package:dusk_horde/meta/weapon_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Progress', () {
    test('tiers are bought in order and cost scrap', () {
      final p = Progress(scrap: 300);
      expect(p.whyNotBuyTier('pistol'), isNull);
      expect(p.buyTier('pistol', choice: 1), isTrue);
      expect(p.scrap, 200);
      expect(p.tierCount('pistol'), 1);
      expect(p.buyTier('pistol'), isTrue);
      expect(p.scrap, 0);
      expect(p.whyNotBuyTier('pistol'), 'Need 350 scrap');
      expect(p.buyTier('pistol'), isFalse);
    });

    test('locked guns cannot be upgraded', () {
      final p = Progress(scrap: 1000);
      expect(p.whyNotBuyTier('smg'), 'Locked');
      p.unlock('smg');
      expect(p.whyNotBuyTier('smg'), isNull);
      expect(p.loadout, ['pistol', 'smg']);
    });

    test('tier 5 needs a boss core, then the signature is on', () {
      final p = Progress(scrap: 5000);
      for (var i = 0; i < 4; i++) {
        p.buyTier('pistol');
      }
      expect(p.whyNotBuyTier('pistol'), 'Need a boss core');
      p.cores = 1;
      expect(p.buyTier('pistol'), isTrue);
      expect(p.cores, 0);
      expect(p.hasSignature('pistol'), isTrue);
      expect(p.whyNotBuyTier('pistol'), 'Maxed');
    });

    test('respec swaps an owned tier for free', () {
      final p = Progress(scrap: 100)..buyTier('pistol', choice: 0);
      final dmg = p.statsFor(Weapons.pistol).damage;
      expect(p.respec('pistol', 0, 1), isTrue);
      expect(p.scrap, 0);
      expect(p.statsFor(Weapons.pistol).damage, Weapons.pistol.base.damage);
      expect(p.statsFor(Weapons.pistol).magazine, greaterThan(12));
      expect(dmg, closeTo(11.5, 1e-9));
      expect(p.respec('pistol', 1, 0), isFalse, reason: 'not owned yet');
    });

    test('statsFor stacks every bought tier', () {
      final p = Progress(scrap: 5000);
      for (final c in [0, 0, 0, 0]) {
        p.buyTier('pistol', choice: c);
      }
      final s = p.statsFor(Weapons.pistol);
      expect(s.damage, closeTo(10 * 1.15 * 1.2, 1e-9));
      expect(s.pierce, 1);
    });

    test('perks level up and change derived stats', () {
      final p = Progress(scrap: 1000);
      expect(p.maxHp, 100);
      expect(p.buyPerk(Perks.tough), isTrue);
      expect(p.maxHp, 115);
      expect(p.buyPerk(Perks.nimble), isTrue);
      expect(p.dodgeCooldownScale, closeTo(0.85, 1e-9));
      expect(p.scrap, 1000 - 150 - 200);
      p.scrap = 0;
      expect(p.buyPerk(Perks.scavenger), isFalse);
    });

    test('bank adds scrap and keeps the best wave', () {
      final p = Progress()..bank(scrap: 40, cores: 1, wave: 6);
      p.bank(scrap: 10, cores: 0, wave: 3);
      expect(p.scrap, 50);
      expect(p.cores, 1);
      expect(p.bestWave, 6);
    });

    test('survives a JSON round trip', () {
      final p = Progress(scrap: 900, cores: 1, bestWave: 7)
        ..unlock('smg')
        ..buyTier('smg', choice: 1)
        ..buyPerk(Perks.tough);
      final q = Progress.decode(p.encode());
      expect(q.scrap, p.scrap);
      expect(q.cores, 1);
      expect(q.bestWave, 7);
      expect(q.unlocked, {'pistol', 'smg'});
      expect(q.tiersOf('smg'), [1, null, null, null, null]);
      expect(q.perkLevel(Perks.tough.id), 1);
      expect(q.loadout, ['pistol', 'smg']);
    });
  });

  group('Magazine reserve', () {
    Magazine smg() => Magazine(
      size: 3,
      shotsPerSecond: 100,
      reloadSeconds: 0.5,
      reserve: 4,
      maxReserve: 10,
    );

    void empty(Magazine m) {
      while (m.rounds > 0) {
        m.tryFire();
        m.update(0.02);
      }
    }

    test('reloads take from the reserve until it runs dry', () {
      final m = smg();
      empty(m);
      m.update(0.6);
      expect(m.rounds, 3);
      expect(m.reserve, 1);
      empty(m);
      m.update(0.6);
      expect(m.rounds, 1);
      expect(m.reserve, 0);
      empty(m);
      m.update(0.6);
      expect(m.isDry, isTrue);
      expect(m.isReloading, isFalse);
    });

    test('addReserve is capped', () {
      final m = smg()..addReserve(100);
      expect(m.reserve, 10);
    });

    test('infinite guns ignore reserve', () {
      final m = Magazine(size: 2, shotsPerSecond: 100, reloadSeconds: 0.1);
      expect(m.isInfinite, isTrue);
      m.addReserve(5);
      expect(m.reserve, isNull);
    });
  });
}

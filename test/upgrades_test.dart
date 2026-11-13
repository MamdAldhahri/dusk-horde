import 'dart:math';

import 'package:dusk_horde/game/dusk_horde_game.dart';
import 'package:dusk_horde/game/enemies/enemy.dart';
import 'package:dusk_horde/game/enemies/enemy_type.dart';
import 'package:dusk_horde/game/pickups/ammo_box.dart';
import 'package:dusk_horde/game/weapons/bullet.dart';
import 'package:dusk_horde/meta/progress.dart';
import 'package:dusk_horde/meta/save_store.dart';
import 'package:dusk_horde/ui/workbench.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final store = MemorySaveStore();

  DuskHordeGame quiet([Progress? p]) => DuskHordeGame(
    random: Random(1),
    firstBreather: 9999,
    progress: p,
    store: store,
  );

  Future<void> run(DuskHordeGame game, int frames) async {
    for (var i = 0; i < frames; i++) {
      game.update(1 / 60);
      await game.ready();
    }
  }

  Future<Enemy> spawn(DuskHordeGame game, Vector2 at) async {
    final e = Enemy(Zombies.shambler, at);
    game.waves.alive.add(e);
    game.world.add(e);
    await game.ready();
    return e;
  }

  testWithGame<DuskHordeGame>(
    'kills earn scrap, and dying banks it to the save',
    quiet,
    (game) async {
      await game.ready();
      final e = await spawn(game, game.player.position + Vector2(-200, 0));
      e.takeHit(999, Vector2(-1, 0));
      expect(game.runScrap, Zombies.shambler.scrap);
      game.onWaveCleared(2);
      expect(
        game.runScrap,
        Zombies.shambler.scrap + DuskHordeGame.waveBonus * 2,
      );
      game.player.takeBite(999, Vector2(1, 0));
      expect(game.isGameOver, isTrue);
      expect(
        store.saved?.scrap,
        Zombies.shambler.scrap + DuskHordeGame.waveBonus * 2,
      );
    },
  );

  testWithGame<DuskHordeGame>(
    'reaching wave 5 unlocks the SMG, which joins the loadout',
    quiet,
    (game) async {
      await game.ready();
      expect(game.player.guns, hasLength(1));
      game.onWaveStarted(5);
      expect(game.progress.unlocked, contains('smg'));
      expect(game.unlockedThisRun, ['SMG']);
      game.restart();
      expect(game.unlockedThisRun, isEmpty);
      expect(game.player.guns, hasLength(2));
      expect(game.player.gun.def.id, 'pistol');
      game.player.swapGun();
      expect(game.player.gun.def.id, 'smg');
      expect(game.player.gun.mag.reserve, isNotNull);
    },
  );

  testWithGame<DuskHordeGame>(
    'Tough perk raises max HP',
    () => quiet(Progress(perks: {'tough': 2})),
    (game) async {
      await game.ready();
      expect(game.player.maxHealth, 130);
      expect(game.player.hp, 130);
    },
  );

  testWithGame<DuskHordeGame>('a piercing shot hits two in a line', quiet, (
    game,
  ) async {
    await game.ready();
    final from = game.player.position.clone();
    final a = await spawn(game, from + Vector2(-60, 0));
    final b = await spawn(game, from + Vector2(-90, 0));
    game.bullets.fire(from, pi, const ShotPayload(damage: 5, pierce: 1));
    await run(game, 20);
    expect(a.hp, lessThan(30));
    expect(b.hp, lessThan(30));

    final c = await spawn(game, from + Vector2(0, -60));
    final d = await spawn(game, from + Vector2(0, -90));
    game.bullets.fire(from, -pi / 2, const ShotPayload(damage: 5));
    await run(game, 20);
    expect(c.hp, lessThan(30));
    expect(d.hp, 30, reason: 'no pierce stops at the first');
  });

  testWithGame<DuskHordeGame>('bleed ticks damage, then wears off', quiet, (
    game,
  ) async {
    await game.ready();
    final e = await spawn(game, game.player.position + Vector2(-250, 0));
    e
      ..addBleed()
      ..addBleed();
    expect(e.bleedStacks, 2);
    await run(game, 60);
    expect(e.hp, closeTo(26, 0.2));
    await run(game, 150);
    expect(e.bleedStacks, 0);
  });

  testWithGame<DuskHordeGame>(
    'Last Word: the final round in the mag hits three times as hard',
    () => quiet(
      Progress(
        tiers: {
          // Magazine, reload, pierce, ammo: damage stays at 10 and no crit.
          'pistol': [1, 1, 0, 1, 0],
        },
      ),
    ),
    (game) async {
      await game.ready();
      final g = game.player.gun;
      expect(g.hasSignature, isTrue);
      final e = await spawn(game, game.player.position + Vector2(-80, 0));
      g.mag.rounds = 1;
      game.aimStick.vector = Vector2(-1, 0);
      await run(game, 1);
      game.aimStick.vector.setZero();
      await run(game, 30);
      // 10 base x3 = 30: one shot kills a 30 HP shambler.
      expect(e.isAlive, isFalse);
    },
  );

  testWithGame<DuskHordeGame>(
    'an ammo box tops up guns that use ammo',
    () => quiet(Progress()..unlock('smg')),
    (game) async {
      await game.ready();
      final smg = game.player.guns[1].mag;
      smg.reserve = 0;
      game.world.add(AmmoBox(game.player.position.clone()));
      await run(game, 2);
      expect(smg.reserve, (smg.maxReserve! * AmmoBox.share).round());
      expect(game.player.guns[0].mag.reserve, isNull);
    },
  );

  testWidgets('workbench buys a tier and saves', (tester) async {
    tester.view.physicalSize = const Size(1600, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final s = MemorySaveStore();
    final game = DuskHordeGame(progress: Progress(scrap: 120), store: s);
    await tester.pumpWidget(MaterialApp(home: Workbench(game: game)));
    expect(find.text('SCRAP 120'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tier-pistol-0-0')));
    await tester.pump();
    expect(game.progress.scrap, 20);
    expect(game.progress.tierCount('pistol'), 1);
    expect(s.saves, 1);
  });
}

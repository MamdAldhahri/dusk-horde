import 'dart:math';

import 'package:dusk_horde/game/dusk_horde_game.dart';
import 'package:dusk_horde/game/enemies/brute.dart';
import 'package:dusk_horde/game/enemies/enemy.dart';
import 'package:dusk_horde/game/enemies/enemy_type.dart';
import 'package:dusk_horde/game/pickups/medkit.dart';
import 'package:dusk_horde/game/waves/wave_manager.dart';
import 'package:dusk_horde/game/waves/wave_plan.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  DuskHordeGame quiet() =>
      DuskHordeGame(random: Random(1), firstBreather: 9999);

  Future<void> run(DuskHordeGame game, int frames) async {
    for (var i = 0; i < frames; i++) {
      game.update(1 / 60);
      await game.ready();
    }
  }

  Future<T> add<T extends Enemy>(DuskHordeGame game, T e) async {
    game.waves.alive.add(e);
    game.world.add(e);
    await game.ready();
    return e;
  }

  testWithGame<DuskHordeGame>(
    'the Gas Station map loads with its layers',
    quiet,
    (game) async {
      await game.ready();
      expect(game.arena.width, 960);
      expect(game.arena.height, 544);
      expect(game.spawnPoints.length, 8);
      expect(game.level.pickups.length, 5);
      expect(game.crate, isNotNull);
      expect(game.obstacles.length, greaterThanOrEqualTo(8));
      // The player starts on open ground.
      expect(game.flowField.isBlocked(game.player.position), isFalse);
    },
  );

  testWithGame<DuskHordeGame>(
    'a Bloater bursts on death, hurting zombies and the player nearby',
    quiet,
    (game) async {
      await game.ready();
      final p = game.player.position;
      final bloater = await add(
        game,
        Enemy(Zombies.bloater, p + Vector2(30, 0)),
      );
      final buddy = await add(
        game,
        Enemy(Zombies.shambler, p + Vector2(50, 10)),
      );
      bloater.takeHit(999, Vector2(1, 0));
      expect(buddy.isAlive, isFalse); // 60 damage vs 30 HP
      expect(game.player.hp, 100 - Zombies.bloater.explodeDamage);
    },
  );

  testWithGame<DuskHordeGame>(
    'the Brute winds up, charges, and is stunned by a wreck',
    quiet,
    (game) async {
      await game.ready();
      // Player right of the car at (656, 288, 30x60), Brute left of it.
      game.player.position.setValues(740, 318);
      final brute = await add(game, Brute(Vector2(560, 318)));
      final seen = <BruteState>{};
      for (var i = 0; i < 60 * 6; i++) {
        game.player.hp = 100;
        game.player.position.setValues(740, 318);
        await run(game, 1);
        seen.add(brute.state);
        if (brute.state == BruteState.stunned) break;
      }
      expect(seen, containsAll([BruteState.windup, BruteState.charge]));
      expect(brute.state, BruteState.stunned);
      expect(brute.damageTakenScale, 1.5);
    },
  );

  testWithGame<DuskHordeGame>('medkits heal, and only when hurt', quiet, (
    game,
  ) async {
    await game.ready();
    final kit = Medkit(game.player.position.clone());
    game.world.add(kit);
    await run(game, 2);
    expect(kit.isMounted, isTrue); // full health: left for later
    game.player.hp = 50;
    await run(game, 2);
    expect(game.player.hp, 75);
    expect(kit.isMounted, isFalse);
  });

  testWithGame<DuskHordeGame>(
    'the supply crate heals once per breather',
    () => DuskHordeGame(random: Random(1), firstBreather: 0.05),
    (game) async {
      await game.ready();
      final crate = game.crate!;
      game.waves
        ..wave = 1
        ..phase = WavePhase.breather
        ..breatherLeft = 10;
      game.player.position.setFrom(crate.position);
      game.player.hp = 40;
      await run(game, 2);
      expect(game.player.hp, 75);
      await run(game, 2);
      expect(game.player.hp, 75); // already used this breather
    },
  );

  testWithGame<DuskHordeGame>('clearing the final wave brings dawn', quiet, (
    game,
  ) async {
    await game.ready();
    game.waves
      ..wave = const ZombiePlan().finalWave
      ..phase = WavePhase.fighting;
    await run(game, 2);
    expect(game.waves.phase, WavePhase.dawn);
    expect(game.isDawn, isTrue);
    game.restart();
    expect(game.waves.wave, 0);
    expect(game.isDawn, isFalse);
  });

  test('wave plan: elite on 5, bloaters from 6, Brute on 10', () {
    const plan = ZombiePlan();
    expect(plan.wave(5, Random(1)).countOf(Zombies.eliteShambler), 1);
    expect(plan.wave(5, Random(1)).countOf(Zombies.bloater), 0);
    expect(plan.wave(6, Random(1)).countOf(Zombies.bloater), greaterThan(0));
    final boss = plan.wave(10, Random(1));
    expect(boss.countOf(Zombies.brute), 1);
    expect(boss.enemies.length, 22);
  });
}

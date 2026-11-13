import 'dart:math';

import 'package:dusk_horde/game/dusk_horde_game.dart';
import 'package:dusk_horde/game/enemies/aliens.dart';
import 'package:dusk_horde/game/enemies/enemy.dart';
import 'package:dusk_horde/game/enemies/enemy_type.dart';
import 'package:dusk_horde/game/enemies/plasma_bolt.dart';
import 'package:dusk_horde/game/enemies/spawn.dart';
import 'package:dusk_horde/game/enemies/warden.dart';
import 'package:dusk_horde/game/levels.dart';
import 'package:dusk_horde/game/waves/wave_manager.dart';
import 'package:dusk_horde/game/waves/wave_plan.dart';
import 'package:dusk_horde/game/weapons/bullet.dart';
import 'package:dusk_horde/meta/progress.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  DuskHordeGame quiet({
    LevelDef level = Levels.gasStation,
    Progress? progress,
    double firstBreather = 9999,
  }) => DuskHordeGame(
    random: Random(1),
    firstBreather: firstBreather,
    startLevel: level,
    progress: progress,
  );

  Future<void> run(DuskHordeGame game, int frames) async {
    for (var i = 0; i < frames; i++) {
      game.update(1 / 60);
      await game.ready();
    }
  }

  Future<T> add<T extends Enemy>(DuskHordeGame game, T e) async {
    game.waves.addEnemy(e);
    await game.ready();
    return e;
  }

  group('AlienPlan', () {
    const plan = AlienPlan();
    final r = Random(3);

    test('wave 1 is Skitters only, arriving in packs', () {
      final w = plan.wave(1, r);
      expect(w.enemies.every((e) => e == Aliens.skitter), isTrue);
      expect(w.enemies, hasLength(9));
      expect(w.pods, 0);
    });

    test('Lancers from 3, Stalkers from 6, Brood Pods from 8', () {
      expect(plan.wave(2, r).countOf(Aliens.lancer), 0);
      expect(plan.wave(3, r).countOf(Aliens.lancer), greaterThan(0));
      expect(plan.wave(5, r).countOf(Aliens.stalker), 0);
      expect(plan.wave(6, r).countOf(Aliens.stalker), greaterThan(0));
      expect(plan.wave(7, r).pods, 0);
      expect(plan.wave(8, r).pods, 1);
      expect(plan.wave(12, r).pods, 2);
    });

    test('Skitters stay together in packs', () {
      final list = plan.wave(9, r).enemies;
      var run = 0;
      final runs = <int>[];
      for (final e in list) {
        if (e == Aliens.skitter) {
          run++;
        } else if (run > 0) {
          runs.add(run);
          run = 0;
        }
      }
      if (run > 0) runs.add(run);
      // 18 Skitters as packs of 7, 7 and 4: at most three separate runs
      // (fewer when packs land next to each other).
      expect(runs.fold(0, (a, b) => a + b), 18);
      expect(runs.length, lessThanOrEqualTo(3));
    });

    test('elite Lancer on 5 and 10, the Warden on 15', () {
      expect(plan.wave(5, r).countOf(Aliens.eliteLancer), 1);
      expect(plan.wave(10, r).countOf(Aliens.eliteLancer), 1);
      final boss = plan.wave(15, r);
      expect(boss.countOf(Aliens.warden), 1);
      expect(boss.enemies.last, isNot(Aliens.warden));
    });

    test('Endless: a boss every 10 waves, on both maps', () {
      expect(plan.wave(10, r, endless: true).countOf(Aliens.warden), 1);
      expect(plan.wave(15, r, endless: true).countOf(Aliens.warden), 0);
      expect(plan.wave(20, r, endless: true).countOf(Aliens.warden), 1);
      const zombies = ZombiePlan();
      expect(zombies.wave(20, r, endless: true).countOf(Zombies.brute), 1);
      expect(zombies.wave(15, r, endless: true).countOf(Zombies.brute), 0);
    });
  });

  testWithGame<DuskHordeGame>(
    'the Crash Site map loads with spawns and hive spots',
    () => quiet(level: Levels.crashSite),
    (game) async {
      await game.ready();
      expect(game.arena.width, 960);
      expect(game.arena.height, 640);
      expect(game.spawnPoints, hasLength(6));
      expect(game.level.hives, hasLength(5));
      final start = game.level.playerStart.toOffset();
      expect(game.obstacles.any((o) => o.contains(start)), isFalse);
      for (final h in game.level.hives) {
        expect(game.obstacles.any((o) => o.contains(h.toOffset())), isFalse);
      }
    },
  );

  testWithGame<DuskHordeGame>(
    'a Skitter pack spawns together from one point',
    () => quiet(level: Levels.crashSite, firstBreather: 0.05),
    (game) async {
      await game.ready();
      await run(game, 6);
      final alive = game.waves.alive;
      expect(alive.length, anyOf(2, 7));
      final first = alive.first.position;
      expect(alive.every((e) => e.position.distanceTo(first) < 60), isTrue);
    },
  );

  testWithGame<DuskHordeGame>(
    'a Lancer keeps its distance and fires bolts',
    quiet,
    (game) async {
      await game.ready();
      final p = game.player;
      final l = await add(
        game,
        Lancer(Aliens.lancer, p.position + Vector2(-160, 0)),
      );
      var sawBolt = false;
      for (var i = 0; i < 300; i++) {
        await run(game, 1);
        sawBolt |= game.world.children.whereType<PlasmaBolt>().isNotEmpty;
      }
      expect(sawBolt, isTrue);
      expect(p.hp, lessThan(p.maxHealth));
      expect(l.position.distanceTo(p.position), greaterThan(90));
    },
  );

  testWithGame<DuskHordeGame>('dodging rolls through a plasma bolt', quiet, (
    game,
  ) async {
    await game.ready();
    final p = game.player;
    game.world.add(PlasmaBolt(p.position + Vector2(20, 0), Vector2(-1, 0)));
    p.dodge.tryStart();
    await run(game, 20);
    expect(p.hp, p.maxHealth);
  });

  testWithGame<DuskHordeGame>(
    'a Stalker is hidden in the dark and shows up in the beam',
    quiet,
    (game) async {
      await game.ready();
      final p = game.player..aimAngle = 0;
      final s = await add(game, Stalker(p.position + Vector2(-200, 0)));
      await run(game, 30);
      expect(s.opacity, lessThan(0.2));
      expect(s.isTargetable, isFalse);
      p.aimAngle = pi;
      await run(game, 20);
      expect(s.opacity, greaterThan(0.8));
      expect(s.isTargetable, isTrue);
    },
  );

  testWithGame<DuskHordeGame>(
    'a Brood Pod stays put and births Skitters',
    quiet,
    (game) async {
      await game.ready();
      final at = game.player.position + Vector2(-200, 0);
      final pod = await add(game, BroodPod(at.clone()));
      await run(game, 140);
      expect(pod.position, at);
      expect(game.waves.alive.whereType<Skitter>(), isNotEmpty);
      expect(game.waves.alive, contains(pod));
    },
  );

  testWithGame<DuskHordeGame>(
    'the Warden sweeps its beam, then opens its weak spot',
    quiet,
    (game) async {
      await game.ready();
      final p = game.player..hp = 1000;
      final w = await add(game, Warden(p.position + Vector2(-150, 0)));
      expect(w.damageTakenScale, lessThan(1));
      var swept = false;
      for (var i = 0; i < 60 * 9 && w.state != WardenState.exposed; i++) {
        await run(game, 1);
        swept |= w.state == WardenState.sweep;
      }
      expect(swept, isTrue);
      expect(w.state, WardenState.exposed);
      expect(w.damageTakenScale, 2);
      expect(p.hp, lessThan(1000));
    },
  );

  testWithGame<DuskHordeGame>(
    'the shotgun fires six pellets and Dragon\'s Breath burns',
    () => quiet(
      progress: Progress(unlocked: {'pistol', 'shotgun'}, loadout: ['shotgun']),
    ),
    (game) async {
      await game.ready();
      expect(game.player.gun.def.id, 'shotgun');
      game.aimStick.vector = Vector2(-1, 0);
      await run(game, 1);
      game.aimStick.vector.setZero();
      expect(game.bullets.created, 6);

      final e = await add(
        game,
        createEnemy(Zombies.shambler, game.player.position + Vector2(0, -60)),
      );
      game.bullets.fire(
        game.player.position,
        -pi / 2,
        const ShotPayload(damage: 1, burn: true),
      );
      await run(game, 10);
      expect(e.burnTime, greaterThan(0));
      final hp = e.hp;
      await run(game, 60);
      expect(e.hp, lessThan(hp - 4));
    },
  );

  testWithGame<DuskHordeGame>(
    'Marksman: standing still a second makes the next shot hit double',
    () => quiet(
      progress: Progress(
        unlocked: {'pistol', 'rifle'},
        loadout: ['rifle'],
        // Magazine, reload, pierce, ammo: damage stays at 15, no crit.
        tiers: {
          'rifle': [1, 1, 0, 1, 0],
        },
      ),
    ),
    (game) async {
      await game.ready();
      final p = game.player;
      final e = await add(
        game,
        createEnemy(Zombies.shambler, p.position + Vector2(-80, 0)),
      );
      await run(game, 65);
      expect(p.marksmanReady, isTrue);
      game.aimStick.vector = Vector2(-1, 0);
      await run(game, 1);
      game.aimStick.vector.setZero();
      expect(p.marksmanReady, isFalse);
      await run(game, 20);
      expect(e.isAlive, isFalse, reason: '15 x 2 kills a 30 HP shambler');
    },
  );

  group('progression', () {
    testWithGame<DuskHordeGame>(
      'beating the Gas Station opens the shotgun and the Crash Site',
      quiet,
      (game) async {
        await game.ready();
        expect(game.progress.isLevelOpen('crash_site'), isFalse);
        game.onDawn();
        expect(game.progress.unlocked, contains('shotgun'));
        expect(game.progress.isLevelOpen('crash_site'), isTrue);
        expect(game.unlockedThisRun, ['Shotgun', 'The Crash Site']);
      },
    );

    testWithGame<DuskHordeGame>(
      'wave 8 at the Crash Site unlocks the rifle; dawn opens Endless',
      () => quiet(level: Levels.crashSite),
      (game) async {
        await game.ready();
        game.onWaveStarted(8);
        expect(game.progress.unlocked, contains('rifle'));
        expect(game.progress.endlessOpen, isFalse);
        game.onDawn();
        expect(game.progress.endlessOpen, isTrue);
        expect(game.unlockedThisRun, ['Assault Rifle', 'Endless mode']);
      },
    );

    testWithGame<DuskHordeGame>(
      'a boss core only on the first clear, but always in Endless',
      () => quiet(progress: Progress(beaten: {'gas_station'})),
      (game) async {
        await game.ready();
        final b = await add(
          game,
          createEnemy(Zombies.brute, game.player.position + Vector2(-250, 0)),
        );
        b.takeHit(9999, Vector2(-1, 0));
        expect(game.runCores, 0);
        game.endless = true;
        final c = await add(
          game,
          createEnemy(Zombies.brute, game.player.position + Vector2(250, 0)),
        );
        c.takeHit(9999, Vector2(1, 0));
        expect(game.runCores, 1);
      },
    );

    testWithGame<DuskHordeGame>(
      'deploy loads the picked level; Endless has no dawn',
      () => quiet(
        progress: Progress(
          beaten: {'gas_station', 'crash_site'},
          level: 'crash_site',
          endless: true,
        ),
      ),
      (game) async {
        await game.ready();
        expect(game.levelDef, Levels.gasStation);
        await game.deploy();
        await game.ready();
        expect(game.levelDef, Levels.crashSite);
        expect(game.arena.height, 640);
        expect(game.endless, isTrue);
        expect(game.player.position, game.level.playerStart);
        game.waves
          ..wave = 15
          ..phase = WavePhase.fighting;
        await run(game, 2);
        expect(game.waves.phase, WavePhase.breather);
        expect(game.isDawn, isFalse);
        game.player.takeBite(9999, Vector2(1, 0));
        expect(game.progress.endlessBest['crash_site'], 15);
      },
    );

    testWithGame<DuskHordeGame>(
      'deploy falls back to the Gas Station while Level 2 is locked',
      () => quiet(progress: Progress(level: 'crash_site', endless: true)),
      (game) async {
        await game.ready();
        await game.deploy();
        expect(game.levelDef, Levels.gasStation);
        expect(game.endless, isFalse);
      },
    );
  });

  test('progress keeps levels and records through a save', () {
    final p = Progress(beaten: {'gas_station'}, level: 'crash_site')
      ..bank(scrap: 5, cores: 0, wave: 9, level: 'crash_site')
      ..bank(scrap: 5, cores: 0, wave: 12, level: 'gas_station', endless: true);
    final q = Progress.decode(p.encode());
    expect(q.beaten, {'gas_station'});
    expect(q.level, 'crash_site');
    expect(q.bestWaves, {'crash_site': 9});
    expect(q.endlessBest, {'gas_station': 12});
    expect(q.bestWave, 12);
    // An M4 save (no level fields) still loads.
    final old = Progress.decode('{"v":1,"scrap":10,"bestWave":4}');
    expect(old.level, 'gas_station');
    expect(old.beaten, isEmpty);
  });
}

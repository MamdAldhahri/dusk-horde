import 'dart:math';

import 'package:dusk_horde/game/dusk_horde_game.dart';
import 'package:dusk_horde/game/enemies/enemy.dart';
import 'package:dusk_horde/game/enemies/enemy_type.dart';
import 'package:dusk_horde/game/waves/wave_manager.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// No waves for a long time, so tests control what is on the field.
  DuskHordeGame quiet() =>
      DuskHordeGame(random: Random(1), firstBreather: 9999);

  Future<void> run(DuskHordeGame game, int frames) async {
    for (var i = 0; i < frames; i++) {
      game.update(1 / 60);
      await game.ready();
    }
  }

  Future<Enemy> spawn(DuskHordeGame game, EnemyType t, Vector2 at) async {
    final e = Enemy(t, at);
    game.waves.alive.add(e);
    game.world.add(e);
    await game.ready();
    return e;
  }

  testWithGame<DuskHordeGame>(
    'left stick moves the player, but not past the arena edge',
    quiet,
    (game) async {
      await game.ready();
      game.moveStick.vector = Vector2(-1, 0);
      await run(game, 60);
      expect(game.player.position.x, lessThan(-60));
      await run(game, 600);
      expect(game.player.position.x, greaterThanOrEqualTo(game.arena.left));
    },
  );

  testWithGame<DuskHordeGame>(
    'aiming at a zombie fires, hits it, and reuses bullets',
    quiet,
    (game) async {
      await game.ready();
      final target = await spawn(game, Zombies.shambler, Vector2(200, 0));
      game.aimStick.vector = Vector2(1, 0);
      await run(game, 60);
      expect(target.hp, lessThan(Zombies.shambler.hp));
      expect(game.bullets.created, lessThanOrEqualTo(6));
    },
  );

  testWithGame<DuskHordeGame>(
    'a zombie walks around a wreck to reach and bite the player',
    quiet,
    (game) async {
      await game.ready();
      // Player just below the wreck at (-260,-150, 64x30); zombie above it.
      game.player.position.setValues(-228, -100);
      await spawn(game, Zombies.shambler, Vector2(-228, -200));
      await run(game, 60 * 8);
      expect(game.player.hp, lessThan(100));
    },
  );

  testWithGame<DuskHordeGame>('dodging ignores bites', quiet, (game) async {
    await game.ready();
    game.player.tryDodge();
    game.player.takeBite(10, Vector2(1, 0));
    expect(game.player.hp, 100);
  });

  testWithGame<DuskHordeGame>(
    'waves start, get cleared, then a breather follows',
    () => DuskHordeGame(random: Random(2), firstBreather: 0.1),
    (game) async {
      await game.ready();
      await run(game, 20);
      expect(game.waves.wave, 1);
      expect(game.waves.remaining, 9); // 6 + 3 x 1
      // Let them all spawn; keep the player topped up so this test is
      // about waves, not dying.
      for (var i = 0; i < 60 * 10; i++) {
        game.player.hp = 100;
        await run(game, 1);
      }
      for (final e in [...game.waves.alive]) {
        e.takeHit(999, Vector2(1, 0));
      }
      await run(game, 2);
      expect(game.waves.remaining, 0);
      expect(game.waves.phase, WavePhase.breather);
      expect(game.waves.kills, 9);
    },
  );

  testWithGame<DuskHordeGame>(
    'dying shows game over, retry starts fresh',
    quiet,
    (game) async {
      await game.ready();
      for (var i = 0; i < 12; i++) {
        game.player.takeBite(10, Vector2(1, 0));
        await run(game, 40);
      }
      expect(game.player.isAlive, isFalse);
      expect(game.isGameOver, isTrue);
      expect(game.paused, isTrue);
      game.restart();
      expect(game.player.hp, 100);
      expect(game.waves.wave, 0);
      expect(game.isGameOver, isFalse);
    },
  );
}

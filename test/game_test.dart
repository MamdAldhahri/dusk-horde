import 'dart:math';

import 'package:dusk_horde/game/dusk_horde_game.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  DuskHordeGame create() => DuskHordeGame(random: Random(1));

  Future<void> run(DuskHordeGame game, int frames) async {
    for (var i = 0; i < frames; i++) {
      game.update(1 / 60);
    }
    await game.ready();
  }

  testWithGame<DuskHordeGame>(
    'left stick moves the player, but not past the arena edge',
    create,
    (game) async {
      await game.ready();
      game.moveStick.vector = Vector2(-1, 0);
      await run(game, 60);
      expect(game.player.position.x, lessThan(-100));
      await run(game, 600);
      expect(game.player.position.x, greaterThanOrEqualTo(game.arena.left));
    },
  );

  testWithGame<DuskHordeGame>(
    'aiming at a zombie fires, hits it, and reuses bullets',
    create,
    (game) async {
      await game.ready();
      final target = game.targets.first; // shambler at (150, -60)
      final start = target.hp;
      game.aimStick.vector = (target.position - game.player.position)
          .normalized();
      for (var i = 0; i < 120; i++) {
        await run(game, 1);
      }
      expect(target.hp, lessThan(start));
      // 2 seconds at 4 shots/s should need only a handful of bullet objects.
      expect(game.bullets.created, lessThanOrEqualTo(6));
    },
  );

  testWithGame<DuskHordeGame>('dodge starts a cooldown', create, (game) async {
    await game.ready();
    game.player.tryDodge();
    expect(game.player.dodge.isRolling, isTrue);
    await run(game, 30);
    expect(game.player.dodge.isReady, isFalse);
  });
}

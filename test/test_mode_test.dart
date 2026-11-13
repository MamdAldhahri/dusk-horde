import 'dart:math';

import 'package:dusk_horde/game/dusk_horde_game.dart';
import 'package:dusk_horde/game/enemies/enemy_type.dart';
import 'package:dusk_horde/game/enemies/spawn.dart';
import 'package:dusk_horde/game/waves/wave_manager.dart';
import 'package:dusk_horde/meta/progress.dart';
import 'package:dusk_horde/ui/workbench.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> run(DuskHordeGame game, int frames) async {
    for (var i = 0; i < frames; i++) {
      game.update(1 / 60);
      await game.ready();
    }
  }

  test('Test Mode opens every level, Endless and every gun', () {
    final p = Progress(testMode: true);
    expect(p.isLevelOpen('crash_site'), isTrue);
    expect(p.endlessOpen, isTrue);
    expect(p.hasGun('rifle'), isTrue);
    expect(p.unlocked, {'pistol'}, reason: 'nothing is really unlocked');
    expect(Progress.decode(p.encode()).testMode, isTrue);
  });

  testWithGame<DuskHordeGame>(
    'Test Mode: take a fifth of the damage, deal triple',
    () => DuskHordeGame(
      random: Random(1),
      firstBreather: 9999,
      progress: Progress(testMode: true),
    ),
    (game) async {
      await game.ready();
      final p = game.player;
      p.takeBite(50, Vector2(1, 0));
      expect(p.hp, 90);
      final e = createEnemy(Zombies.shambler, p.position + Vector2(-80, 0));
      game.waves.addEnemy(e);
      await game.ready();
      game.aimStick.vector = Vector2(-1, 0);
      await run(game, 1);
      game.aimStick.vector.setZero();
      await run(game, 20);
      expect(e.isAlive, isFalse, reason: 'pistol 10 x 3 = 30');
    },
  );

  testWithGame<DuskHordeGame>(
    'SKIP ends the wave, then a short breather',
    () => DuskHordeGame(
      random: Random(1),
      firstBreather: 0.05,
      progress: Progress(testMode: true),
    ),
    (game) async {
      await game.ready();
      await run(game, 6);
      expect(game.waves.phase, WavePhase.spawning);
      game.waves.skipWave();
      await run(game, 2);
      expect(game.waves.alive, isEmpty);
      expect(game.waves.phase, WavePhase.breather);
      expect(game.waves.breatherLeft, lessThanOrEqualTo(3));
      await run(game, 200);
      expect(game.waves.wave, 2);
    },
  );

  testWidgets('the workbench switch turns Test Mode on and off', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final game = DuskHordeGame(progress: Progress());
    await tester.pumpWidget(MaterialApp(home: Workbench(game: game)));
    // The switch sits at the end of the scrolling level row.
    await tester.scrollUntilVisible(
      find.byKey(const Key('test-mode')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('test-mode')));
    await tester.pump();
    expect(game.progress.testMode, isTrue);
    game.progress.loadout.add('rifle');
    await tester.tap(find.byKey(const Key('test-mode')));
    await tester.pump();
    expect(game.progress.testMode, isFalse);
    expect(game.progress.loadout, ['pistol']);
  });
}

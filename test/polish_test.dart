import 'dart:math';

import 'package:dusk_horde/game/audio/game_audio.dart';
import 'package:dusk_horde/game/dusk_horde_game.dart';
import 'package:dusk_horde/game/enemies/enemy_type.dart';
import 'package:dusk_horde/game/enemies/spawn.dart';
import 'package:dusk_horde/meta/progress.dart';
import 'package:dusk_horde/meta/save_store.dart';
import 'package:dusk_horde/ui/settings_panel.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A clock the test moves by hand.
class TestAudio extends SilentAudio {
  double clock = 0;
  @override
  double now() => clock;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestAudio audio;
  late MemorySaveStore store;

  DuskHordeGame quiet([Progress? p]) {
    audio = TestAudio();
    store = MemorySaveStore();
    return DuskHordeGame(
      random: Random(1),
      firstBreather: 9999,
      progress: p,
      store: store,
      audio: audio,
    );
  }

  Future<void> run(DuskHordeGame game, int frames) async {
    for (var i = 0; i < frames; i++) {
      game.update(1 / 60);
      await game.ready();
    }
  }

  group('audio', () {
    test('the same effect is throttled, different ones are not', () {
      final a = TestAudio();
      a.play(Sfx.hit);
      a.play(Sfx.hit);
      a.play(Sfx.pistol);
      a.clock = 0.05;
      a.play(Sfx.hit);
      expect(a.played, [Sfx.hit, Sfx.pistol, Sfx.hit]);
    });

    test('volume 0 mutes effects', () {
      final a = TestAudio()..setVolumes(sfx: 0, music: 0.5);
      a.play(Sfx.pistol);
      expect(a.played, isEmpty);
    });

    testWithGame<DuskHordeGame>('shooting, kills and waves make noise', quiet, (
      game,
    ) async {
      await game.ready();
      final p = game.player;
      final z = createEnemy(Zombies.shambler, p.position + Vector2(-80, 0));
      final s = createEnemy(Aliens.skitter, p.position + Vector2(0, -150));
      game.waves
        ..addEnemy(z)
        ..addEnemy(s);
      await game.ready();
      game.aimStick.vector = Vector2(-1, 0);
      await run(game, 1);
      game.aimStick.vector.setZero();
      expect(audio.played, contains(Sfx.pistol));
      z.takeHit(999, Vector2(1, 0));
      s.takeHit(999, Vector2(1, 0));
      expect(audio.played, containsAll([Sfx.zombieDie, Sfx.alienDie]));
      game.onWaveStarted(1);
      expect(audio.played, contains(Sfx.waveStart));
    });

    testWithGame<DuskHordeGame>(
      'each level plays its own music; it stops when the run ends',
      () => quiet(Progress(beaten: {'gas_station'}, level: 'crash_site')),
      (game) async {
        await game.ready();
        expect(audio.music, 'music_gas_station.ogg');
        await game.deploy();
        expect(audio.music, 'music_crash_site.ogg');
        game.player.takeBite(9999, Vector2(1, 0));
        expect(audio.music, isNull);
      },
    );
  });

  group('pause', () {
    testWithGame<DuskHordeGame>(
      'pause freezes the run; resume continues',
      quiet,
      (game) async {
        await game.ready();
        game.pauseRun();
        expect(game.isPausedByPlayer, isTrue);
        expect(game.paused, isTrue);
        expect(audio.musicPaused, isTrue);
        game.resumeRun();
        expect(game.isPausedByPlayer, isFalse);
        expect(game.paused, isFalse);
        expect(audio.musicPaused, isFalse);
      },
    );

    testWithGame<DuskHordeGame>('leaving the app mid-run pauses it', quiet, (
      game,
    ) async {
      await game.ready();
      game.lifecycleStateChange(AppLifecycleState.paused);
      expect(game.isPausedByPlayer, isTrue);
      // Coming back keeps the pause menu up instead of resuming the fight.
      game.lifecycleStateChange(AppLifecycleState.resumed);
      expect(game.paused, isTrue);
    });

    testWithGame<DuskHordeGame>('no pause once the run is over', quiet, (
      game,
    ) async {
      await game.ready();
      game.player.takeBite(9999, Vector2(1, 0));
      game.pauseRun();
      expect(game.isPausedByPlayer, isFalse);
    });

    testWithGame<DuskHordeGame>('quitting a run banks its scrap', quiet, (
      game,
    ) async {
      await game.ready();
      game.runScrap = 42;
      game.pauseRun();
      game.quitRun();
      expect(store.saved?.scrap, 42);
      expect(game.isPausedByPlayer, isFalse);
      expect(audio.music, isNull);
    });
  });

  group('settings', () {
    testWithGame<DuskHordeGame>(
      'aim assist off: aim goes exactly where the stick points',
      () => quiet(Progress(settings: Settings(aimAssist: 0))),
      (game) async {
        await game.ready();
        final p = game.player;
        game.waves.addEnemy(
          createEnemy(
            Zombies.shambler,
            p.position + Vector2(-150, 20), // about 7.6 degrees off
          ),
        );
        await game.ready();
        game.aimStick.vector = Vector2(-1, 0);
        await run(game, 1);
        expect(p.aimAngle, closeTo(pi, 1e-4));
      },
    );

    testWithGame<DuskHordeGame>(
      'full aim assist snaps to a target within 15 degrees',
      quiet,
      (game) async {
        await game.ready();
        final p = game.player;
        game.waves.addEnemy(
          createEnemy(Zombies.shambler, p.position + Vector2(-150, 20)),
        );
        await game.ready();
        game.aimStick.vector = Vector2(-1, 0);
        await run(game, 1);
        expect((p.aimAngle - pi).abs(), greaterThan(0.05));
      },
    );

    test('settings are saved and out-of-range values are clamped', () {
      final p = Progress(settings: Settings(stickScale: 1.3, musicVolume: 0));
      final q = Progress.decode(p.encode());
      expect(q.settings.stickScale, 1.3);
      expect(q.settings.musicVolume, 0);
      final bad = Settings.fromJson({'stickScale': 9, 'aimAssist': -1});
      expect(bad.stickScale, Settings.maxStick);
      expect(bad.aimAssist, 0);
      expect(Progress.decode('{"v":2}').settings.sfxVolume, 0.8);
    });

    testWidgets('the settings panel changes volume and saves on close', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 412);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final a = TestAudio();
      final s = MemorySaveStore();
      final game = DuskHordeGame(store: s, audio: a);
      await tester.pumpWidget(MaterialApp(home: SettingsPanel(game: game)));
      await tester.drag(
        find.byKey(const Key('music-volume')),
        const Offset(-400, 0),
      );
      await tester.pump();
      expect(game.progress.settings.musicVolume, 0);
      expect(a.musicVolume, 0);
      await tester.tap(find.byKey(const Key('close-settings')));
      await tester.pump();
      expect(s.saves, 1);
    });
  });
}

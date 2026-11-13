import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/audio/game_audio.dart';
import 'game/dusk_horde_game.dart';
import 'meta/progress.dart';
import 'meta/save_store.dart';
import 'ui/panels.dart';
import 'ui/pause_menu.dart';
import 'ui/settings_panel.dart';
import 'ui/workbench.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final store = PrefsSaveStore();
  // Test Mode is a developer tool: never on in a release build.
  final progress = await store.load()
    ..testMode &= kDebugMode;
  runApp(DuskHordeApp(progress: progress, store: store));
}

class DuskHordeApp extends StatefulWidget {
  const DuskHordeApp({super.key, this.progress, this.store});

  final Progress? progress;
  final SaveStore? store;

  @override
  State<DuskHordeApp> createState() => _DuskHordeAppState();
}

class _DuskHordeAppState extends State<DuskHordeApp> {
  late final _game = DuskHordeGame(
    progress: widget.progress,
    store: widget.store,
    showWorkbenchOnStart: widget.store != null,
    audio: widget.store != null ? FlameGameAudio() : null,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dusk Horde',
      debugShowCheckedModeBanner: false,
      home: GameWidget(
        game: _game,
        overlayBuilderMap: {
          DuskHordeGame.gameOverOverlay: (context, game) =>
              GameOverPanel(game: game as DuskHordeGame),
          DuskHordeGame.dawnOverlay: (context, game) =>
              DawnPanel(game: game as DuskHordeGame),
          DuskHordeGame.workbenchOverlay: (context, game) =>
              Workbench(game: game as DuskHordeGame),
          DuskHordeGame.pauseOverlay: (context, game) =>
              PauseMenu(game: game as DuskHordeGame),
          DuskHordeGame.settingsOverlay: (context, game) =>
              SettingsPanel(game: game as DuskHordeGame),
        },
      ),
    );
  }
}

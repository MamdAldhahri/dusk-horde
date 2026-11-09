import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/dusk_horde_game.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const DuskHordeApp());
}

class DuskHordeApp extends StatefulWidget {
  const DuskHordeApp({super.key});

  @override
  State<DuskHordeApp> createState() => _DuskHordeAppState();
}

class _DuskHordeAppState extends State<DuskHordeApp> {
  final _game = DuskHordeGame();

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
        },
      ),
    );
  }
}

/// Shown when the player dies: how far they got, and a retry button.
class GameOverPanel extends StatelessWidget {
  const GameOverPanel({super.key, required this.game});

  final DuskHordeGame game;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xCC000000),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'YOU DIDN\'T MAKE IT TO DAWN',
              style: TextStyle(
                color: Color(0xFFB3261E),
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reached wave ${game.waves.wave}  ·  ${game.waves.kills} kills',
              style: const TextStyle(color: Color(0xFFB8AFA6), fontSize: 16),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF3A3F47),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              onPressed: game.restart,
              child: const Text('TRY AGAIN', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when the final wave is cleared.
class DawnPanel extends StatelessWidget {
  const DawnPanel({super.key, required this.game});

  final DuskHordeGame game;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xEE2A1A2E), Color(0xEEE07A3A)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'DAWN BREAKS',
              style: TextStyle(
                color: Color(0xFFFFE2B0),
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You survived the night at the Gas Station  ·  ${game.waves.kills} kills',
              style: const TextStyle(color: Color(0xFFFFF3E0), fontSize: 16),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF3A2A1E),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              onPressed: game.restart,
              child: const Text('PLAY AGAIN', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

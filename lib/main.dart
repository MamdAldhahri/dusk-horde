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

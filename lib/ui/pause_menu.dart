import 'package:flutter/material.dart';

import '../game/dusk_horde_game.dart';
import 'theme.dart';

/// Shown by the HUD pause button, or when the app is left mid-run.
class PauseMenu extends StatelessWidget {
  const PauseMenu({super.key, required this.game});

  final DuskHordeGame game;

  @override
  Widget build(BuildContext context) {
    Widget button(String key, String label, VoidCallback onTap, Color c) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: SizedBox(
            width: 230,
            child: FilledButton(
              key: Key(key),
              style: FilledButton.styleFrom(
                backgroundColor: c,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: onTap,
              child: Text(label, style: const TextStyle(fontSize: 16)),
            ),
          ),
        );

    return ColoredBox(
      color: const Color(0xCC000000),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PAUSED',
                style: TextStyle(
                  color: Palette.text,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                ),
              ),
              Text(
                'Wave ${game.waves.wave}  ·  +${game.runScrap} scrap so far',
                style: const TextStyle(color: Palette.muted, fontSize: 14),
              ),
              const SizedBox(height: 16),
              button('resume', 'RESUME', game.resumeRun, Palette.chosen),
              button(
                'open-settings',
                'SETTINGS',
                game.openSettings,
                const Color(0xFF3A3F47),
              ),
              button(
                'quit-run',
                'QUIT RUN (keep scrap)',
                game.quitRun,
                const Color(0xFF4A2A26),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

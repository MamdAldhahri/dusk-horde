import 'package:flutter/material.dart';

import '../game/dusk_horde_game.dart';
import 'theme.dart';

/// What the run earned: scrap, cores and anything unlocked.
class RunRewards extends StatelessWidget {
  const RunRewards({super.key, required this.game, this.color});

  final DuskHordeGame game;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '+${game.runScrap} scrap'
          '${game.runCores > 0 ? '  ·  +${game.runCores} core' : ''}',
          style: TextStyle(
            color: color ?? Palette.scrap,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (game.unlockedThisRun != null) ...[
          const SizedBox(height: 6),
          Text(
            '${game.unlockedThisRun} unlocked!',
            style: const TextStyle(
              color: Palette.core,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _PanelButtons extends StatelessWidget {
  const _PanelButtons({
    required this.game,
    required this.retryLabel,
    required this.color,
  });

  final DuskHordeGame game;
  final String retryLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton(
          key: const Key('retry'),
          style: style,
          onPressed: game.restart,
          child: Text(retryLabel, style: const TextStyle(fontSize: 16)),
        ),
        const SizedBox(width: 16),
        FilledButton(
          key: const Key('workbench'),
          style: style,
          onPressed: game.openWorkbench,
          child: const Text('WORKBENCH', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}

/// Shown when the player dies: how far they got, and what they banked.
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
                color: Palette.blood,
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
            const SizedBox(height: 12),
            RunRewards(game: game),
            const SizedBox(height: 24),
            _PanelButtons(
              game: game,
              retryLabel: 'TRY AGAIN',
              color: const Color(0xFF3A3F47),
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
            const SizedBox(height: 12),
            RunRewards(game: game, color: const Color(0xFFFFE2B0)),
            const SizedBox(height: 24),
            _PanelButtons(
              game: game,
              retryLabel: 'PLAY AGAIN',
              color: const Color(0xFF3A2A1E),
            ),
          ],
        ),
      ),
    );
  }
}

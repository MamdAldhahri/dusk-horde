import 'package:flutter/material.dart';

import '../game/dusk_horde_game.dart';
import '../meta/settings.dart';
import 'theme.dart';

/// Stick size, aim assist and volumes. Opens over the pause menu or the
/// workbench; changes apply live and are saved on close.
class SettingsPanel extends StatefulWidget {
  const SettingsPanel({super.key, required this.game});

  final DuskHordeGame game;

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  Settings get s => widget.game.progress.settings;

  Widget _slider({
    required String key,
    required String label,
    required String value,
    required double current,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(color: Palette.text)),
        ),
        Expanded(
          child: Slider(
            key: Key(key),
            value: current,
            min: min,
            max: max,
            activeColor: Palette.scrap,
            onChanged: (v) {
              setState(() => onChanged(v));
              widget.game.applySettings();
            },
          ),
        ),
        SizedBox(
          width: 56,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Palette.muted),
          ),
        ),
      ],
    );
  }

  String _pct(double v) => '${(v * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xEE0B0A0D),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'SETTINGS',
                  style: TextStyle(
                    color: Palette.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                _slider(
                  key: 'stick-size',
                  label: 'Stick size',
                  value: _pct(s.stickScale),
                  current: s.stickScale,
                  min: Settings.minStick,
                  max: Settings.maxStick,
                  onChanged: (v) => s.stickScale = v,
                ),
                _slider(
                  key: 'aim-assist',
                  label: 'Aim assist',
                  value: s.aimAssist == 0 ? 'Off' : _pct(s.aimAssist),
                  current: s.aimAssist,
                  min: 0,
                  max: 1,
                  onChanged: (v) => s.aimAssist = v,
                ),
                _slider(
                  key: 'sfx-volume',
                  label: 'Sound effects',
                  value: _pct(s.sfxVolume),
                  current: s.sfxVolume,
                  min: 0,
                  max: 1,
                  onChanged: (v) => s.sfxVolume = v,
                ),
                _slider(
                  key: 'music-volume',
                  label: 'Music',
                  value: _pct(s.musicVolume),
                  current: s.musicVolume,
                  min: 0,
                  max: 1,
                  onChanged: (v) => s.musicVolume = v,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    key: const Key('close-settings'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Palette.chosen,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                    ),
                    onPressed: widget.game.closeSettings,
                    child: const Text('DONE'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

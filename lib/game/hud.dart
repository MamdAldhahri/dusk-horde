import 'dart:ui' hide TextStyle;

import 'package:flutter/painting.dart' show TextStyle;

import 'package:flame/components.dart';

import 'dusk_horde_game.dart';
import 'input/round_button.dart';
import 'player/player.dart';
import 'waves/wave_manager.dart';

/// Ammo readout, dodge button and title, drawn in screen space.
class Hud extends PositionComponent with HasGameReference<DuskHordeGame> {
  Hud() : super(priority: 50);

  late final TextComponent _ammo;
  late final TextComponent _wave;
  late final RoundButton _dodge;
  late final RoundButton _reload;

  static final _style = TextPaint(
    style: const TextStyle(
      color: Color(0xFFB8AFA6),
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );

  @override
  Future<void> onLoad() async {
    _ammo = TextComponent(textRenderer: _style);
    _wave = TextComponent(textRenderer: _style, anchor: Anchor.topCenter);
    _dodge = RoundButton(
      label: 'ROLL',
      onPressed: () => game.player.tryDodge(),
      cooldownFraction: () => game.player.dodge.cooldownFraction,
    );
    _reload = RoundButton(
      label: 'R',
      onPressed: () => game.player.pistol.reload(),
      cooldownFraction: () {
        final p = game.player.pistol;
        return p.isReloading ? 1 - p.reloadProgress : 0;
      },
    );
    addAll([
      TextComponent(
        text: 'HP',
        position: Vector2(16, 12),
        textRenderer: TextPaint(
          style: const TextStyle(color: Color(0x88B8AFA6), fontSize: 11),
        ),
      ),
      _ammo,
      _wave,
      _dodge,
      _reload,
    ]);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    final pad = (size.y * 0.06).clamp(16.0, 40.0);
    if (isLoaded) {
      _dodge.position = Vector2(size.x - pad - size.y * 0.09, size.y * 0.30);
      _reload.position = Vector2(size.x - pad - size.y * 0.25, size.y * 0.16);
      _ammo.position = Vector2(size.x - pad - 110, 12);
      _wave.position = Vector2(size.x / 2, 12);
    }
  }

  @override
  void onMount() {
    super.onMount();
    onGameResize(game.size);
  }

  static final _barBack = Paint()..color = const Color(0x55FFFFFF);
  static final _barFill = Paint()..color = const Color(0xFFB3261E);

  @override
  void render(Canvas canvas) {
    const r = Rect.fromLTWH(40, 16, 120, 10);
    canvas.drawRect(r, _barBack);
    final f = (game.player.hp / Player.maxHp).clamp(0.0, 1.0);
    canvas.drawRect(
      Rect.fromLTWH(r.left, r.top, r.width * f, r.height),
      _barFill,
    );
  }

  @override
  void update(double dt) {
    final w = game.waves;
    _wave.text = switch (w.phase) {
      WavePhase.breather when w.wave == 0 =>
        'GET READY  ${w.breatherLeft.ceil()}',
      WavePhase.breather =>
        'WAVE ${w.wave} CLEARED  ·  next in ${w.breatherLeft.ceil()}',
      _ => 'WAVE ${w.wave}  ·  ${w.remaining} left',
    };
    final p = game.player.pistol;
    _ammo.text = p.isReloading
        ? 'PISTOL  reloading'
        : 'PISTOL  ${p.rounds} / ∞';
  }
}

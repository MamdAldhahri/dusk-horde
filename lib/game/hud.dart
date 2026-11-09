import 'dart:ui' hide TextStyle;

import 'package:flutter/painting.dart' show TextStyle;

import 'package:flame/components.dart';

import 'dusk_horde_game.dart';
import 'input/round_button.dart';
import 'waves/wave_manager.dart';

/// Ammo readout, dodge button and title, drawn in screen space.
class Hud extends PositionComponent with HasGameReference<DuskHordeGame> {
  Hud() : super(priority: 50);

  late final TextComponent _ammo;
  late final TextComponent _wave;
  late final RoundButton _dodge;
  late final RoundButton _reload;
  late final RoundButton _swap;
  late final TextComponent _scrap;

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
      onPressed: () => game.player.gun.mag.reload(),
      cooldownFraction: () {
        final m = game.player.gun.mag;
        return m.isReloading ? 1 - m.reloadProgress : 0;
      },
    );
    _swap = RoundButton(label: 'SWAP', onPressed: () => game.player.swapGun());
    _scrap = TextComponent(
      textRenderer: TextPaint(
        style: const TextStyle(color: Color(0xFFD9B45A), fontSize: 12),
      ),
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
      _swap,
      _scrap,
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
      _swap.position = Vector2(size.x - pad - size.y * 0.27, size.y * 0.36);
      _ammo.position = Vector2(size.x - pad - 150, 12);
      _scrap.position = Vector2(16, 32);
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
  static final _bossFill = Paint()..color = const Color(0xFFE08A1E);

  @override
  void render(Canvas canvas) {
    const r = Rect.fromLTWH(40, 16, 120, 10);
    canvas.drawRect(r, _barBack);
    final f = (game.player.hp / game.player.maxHealth).clamp(0.0, 1.0);
    canvas.drawRect(
      Rect.fromLTWH(r.left, r.top, r.width * f, r.height),
      _barFill,
    );

    final boss = game.waves.boss;
    if (boss != null && boss.isAlive) {
      final w = size.x * 0.4;
      final b = Rect.fromLTWH((size.x - w) / 2, 34, w, 8);
      canvas.drawRect(b, _barBack);
      final k = (boss.hp / boss.maxHp).clamp(0.0, 1.0);
      canvas.drawRect(
        Rect.fromLTWH(b.left, b.top, b.width * k, b.height),
        _bossFill,
      );
    }
  }

  @override
  void update(double dt) {
    final w = game.waves;
    final of = w.endless ? 'ENDLESS' : '/ ${w.plan.finalWave}';
    _wave.text = switch (w.phase) {
      WavePhase.breather when w.wave == 0 =>
        'GET READY  ${w.breatherLeft.ceil()}',
      WavePhase.breather =>
        'WAVE ${w.wave} CLEARED  ·  next in ${w.breatherLeft.ceil()}',
      WavePhase.dawn => 'DAWN',
      _ when w.boss != null => 'WAVE ${w.wave}  ·  ${w.boss!.type.name}',
      _ => 'WAVE ${w.wave} $of  ·  ${w.remaining} left',
    };
    final g = game.player.gun;
    final m = g.mag;
    final name = g.name.toUpperCase();
    final spare = m.reserve == null ? '∞' : '${m.reserve}';
    _ammo.text = m.isDry
        ? '$name  empty'
        : m.isReloading
        ? '$name  reloading'
        : '$name  ${m.rounds} / $spare'
              '${game.player.marksmanReady ? '  ·  AIMED' : ''}';
    _scrap.text = 'SCRAP ${game.runScrap}';
    _swap.isVisible = game.player.guns.length > 1;
  }
}

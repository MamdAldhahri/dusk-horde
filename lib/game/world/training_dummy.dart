import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../dusk_horde_game.dart';

/// A zombie that stands still and takes hits, for tuning how shooting feels.
/// Flashes on hit, gets knocked back, falls over and gets back up.
class TrainingDummy extends SpriteComponent
    with HasGameReference<DuskHordeGame> {
  TrainingDummy({
    required this.spritePath,
    required Vector2 home,
    this.maxHp = 30,
    this.hitRadius = 12,
  }) : _home = home.clone(),
       super(anchor: Anchor.center, position: home.clone());

  final String spritePath;
  final double maxHp;
  final double hitRadius;
  final Vector2 _home;

  late double hp = maxHp;
  bool get isAlive => hp > 0;

  final Vector2 _knock = Vector2.zero();

  @override
  Future<void> onLoad() async {
    sprite = Sprite(game.images.fromCache(spritePath));
    size = sprite!.srcSize;
    paint = Paint()..filterQuality = FilterQuality.none;
    angle = _facing(game.player.position - position);
  }

  void takeHit(double damage, Vector2 direction) {
    if (!isAlive) return;
    hp -= damage;
    _knock.setFrom(direction..scale(90));
    add(
      ColorEffect(
        const Color(0xFFFFFFFF),
        EffectController(duration: 0.05, reverseDuration: 0.07),
        opacityTo: 0.85,
      ),
    );
    game.shake(1.2);
    if (!isAlive) _die();
  }

  void _die() {
    game.shake(3);
    add(
      SequenceEffect([
        OpacityEffect.to(0.15, EffectController(duration: 0.25)),
        OpacityEffect.to(0.15, EffectController(duration: 1.75)),
        OpacityEffect.to(1, EffectController(duration: 0.3)),
      ], onComplete: _respawn),
    );
  }

  void _respawn() {
    hp = maxHp;
    position.setFrom(_home);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_knock.length2 > 1) {
      position.addScaled(_knock, dt);
      _knock.scale(0.82);
    }
    // Always face the player, like a zombie would.
    final to = game.player.position - position;
    if (to.length2 > 1) angle = _facing(to);
  }

  static double _facing(Vector2 v) => atan2(v.y, v.x);
}

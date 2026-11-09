import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import 'game_assets.dart';

/// M0 placeholder scene: a dark arena with the player in the middle and a few
/// zombies standing around, to prove assets, camera and landscape all work.
class DuskHordeGame extends FlameGame {
  DuskHordeGame()
    : super(
        camera: CameraComponent.withFixedResolution(width: 640, height: 360),
      );

  static const _background = Color(0xFF141217);

  @override
  Color backgroundColor() => _background;

  @override
  Future<void> onLoad() async {
    await images.loadAll(GameAssets.all);

    world.add(_sprite(GameAssets.player, Vector2.zero()));
    world.add(
      _sprite(GameAssets.zombieShambler, Vector2(120, -40), angle: 3.14),
    );
    world.add(_sprite(GameAssets.zombieRunner, Vector2(-140, 60), angle: -0.5));
    world.add(_sprite(GameAssets.zombieBloater, Vector2(160, 80), angle: 3.6));
    world.add(_sprite(GameAssets.zombieBrute, Vector2(-180, -90), angle: 0.6));

    camera.viewport.add(
      TextComponent(
        text: 'DUSK HORDE  ·  M0',
        position: Vector2(12, 10),
        textRenderer: TextPaint(
          style: const TextStyle(color: Color(0xFFB8AFA6), fontSize: 12),
        ),
      ),
    );
  }

  SpriteComponent _sprite(String path, Vector2 position, {double angle = 0}) {
    final sprite = Sprite(images.fromCache(path));
    return SpriteComponent(
      sprite: sprite,
      position: position,
      size: sprite.srcSize * 2,
      anchor: Anchor.center,
      angle: angle,
      paint: Paint()..filterQuality = FilterQuality.none,
    );
  }
}

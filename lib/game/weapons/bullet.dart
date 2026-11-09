import 'dart:ui';

import 'package:flame/components.dart';

import '../dusk_horde_game.dart';
import '../enemies/enemy.dart';

/// What a bullet does when it lands.
class ShotPayload {
  const ShotPayload({
    required this.damage,
    this.pierce = 0,
    this.bleed = false,
  });
  final double damage;

  /// How many extra enemies it passes through.
  final int pierce;

  /// Adds a bleed stack (SMG Shredder).
  final bool bleed;
}

/// A pooled round. Inactive bullets stay out of the world and are reused,
/// so firing never allocates new components mid-fight.
class Bullet extends PositionComponent with HasGameReference<DuskHordeGame> {
  Bullet() : super(size: Vector2(7, 2), anchor: Anchor.center);

  static const speed = 560.0;
  static const lifetime = 0.7;

  final Vector2 velocity = Vector2.zero();
  ShotPayload payload = const ShotPayload(damage: 10);
  int _piercesLeft = 0;
  final Set<Enemy> _hit = {};
  double _age = 0;

  static final _paint = Paint()..color = const Color(0xFFFFE9A8);

  void launch(Vector2 from, double direction, ShotPayload payload) {
    position.setFrom(from);
    angle = direction;
    velocity
      ..setValues(1, 0)
      ..rotate(direction)
      ..scale(speed);
    this.payload = payload;
    _piercesLeft = payload.pierce;
    _hit.clear();
    _age = 0;
  }

  @override
  void update(double dt) {
    _age += dt;
    position.addScaled(velocity, dt);
    final o = position.toOffset();
    if (_age > lifetime ||
        !game.arena.contains(o) ||
        game.obstacles.any((r) => r.contains(o))) {
      game.bullets.release(this);
      return;
    }
    final hit = game.targetHitBy(position, except: _hit);
    if (hit != null) {
      _hit.add(hit);
      hit.takeHit(payload.damage, velocity.normalized());
      if (payload.bleed) hit.addBleed();
      if (_piercesLeft-- <= 0) game.bullets.release(this);
    }
  }

  @override
  void render(Canvas canvas) => canvas.drawRect(size.toRect(), _paint);
}

/// Keeps spent bullets for reuse.
class BulletPool {
  BulletPool(this._world);

  final World _world;
  final List<Bullet> _free = [];
  int _created = 0;

  /// How many Bullet objects exist in total (for tests and tuning).
  int get created => _created;

  Bullet obtain() {
    if (_free.isNotEmpty) return _free.removeLast();
    _created++;
    return Bullet();
  }

  void fire(Vector2 from, double direction, ShotPayload payload) {
    final b = obtain()..launch(from, direction, payload);
    _world.add(b);
  }

  void release(Bullet b) {
    if (!b.isMounted || b.isRemoving) return;
    b.removeFromParent();
    _free.add(b);
  }
}

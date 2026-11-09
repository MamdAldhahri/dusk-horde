import 'dart:ui';

import 'package:flame/components.dart';

import '../dusk_horde_game.dart';

/// A pooled pistol round. Inactive bullets stay out of the world and are
/// reused, so firing never allocates new components mid-fight.
class Bullet extends PositionComponent with HasGameReference<DuskHordeGame> {
  Bullet() : super(size: Vector2(7, 2), anchor: Anchor.center);

  static const speed = 560.0;
  static const lifetime = 0.7;

  final Vector2 velocity = Vector2.zero();
  double damage = 10;
  double _age = 0;

  static final _paint = Paint()..color = const Color(0xFFFFE9A8);

  void launch(Vector2 from, double direction, double damage) {
    position.setFrom(from);
    angle = direction;
    velocity
      ..setValues(1, 0)
      ..rotate(direction)
      ..scale(speed);
    this.damage = damage;
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
    final hit = game.targetHitBy(position);
    if (hit != null) {
      hit.takeHit(damage, velocity.normalized());
      game.bullets.release(this);
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

  void fire(Vector2 from, double direction, double damage) {
    final b = obtain()..launch(from, direction, damage);
    _world.add(b);
  }

  void release(Bullet b) {
    if (!b.isMounted || b.isRemoving) return;
    b.removeFromParent();
    _free.add(b);
  }
}

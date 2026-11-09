import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../dusk_horde_game.dart';
import '../player/player.dart';
import 'aliens.dart';
import 'enemy.dart';
import 'enemy_type.dart';

enum WardenState { walk, aim, sweep, exposed }

/// The Level 2 boss, a three-legged walker. It stalks you, plants itself,
/// shows where its beam will start, then sweeps the beam across you. After
/// each sweep a glowing weak spot opens on its back for a few seconds:
/// it takes double damage then, and a little over half otherwise. Every
/// other sweep it also drops a pack of Skitters.
class Warden extends Enemy {
  Warden(Vector2 at, {super.hpScale}) : super(Aliens.warden, at);

  static const walkTime = 3.0;
  static const aimTime = 0.9;
  static const sweepTime = 1.8;
  static const exposedTime = 2.5;
  static const sweepHalfArc = 0.9; // radians either side of the player
  static const beamLength = 280.0;
  static const beamHalfWidth = 7.0;
  static const beamDamage = 22.0;

  WardenState state = WardenState.walk;
  double _timer = walkTime;
  int _cycles = 0;
  double _sweepFrom = 0;
  double _sweepTo = 0;

  /// Current beam angle and reach (shortened by walls), for the FX layer.
  double beamAngle = 0;
  double beamReach = beamLength;

  late final WardenFx fx = WardenFx(this);

  @override
  double get damageTakenScale => state == WardenState.exposed ? 2 : 0.6;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    game.world.add(fx);
  }

  @override
  void onRemove() {
    fx.removeFromParent();
    super.onRemove();
  }

  @override
  Vector2 desiredVelocity(double dt, Vector2 toPlayer, double dist) {
    _timer -= dt;
    switch (state) {
      case WardenState.walk:
        if (_timer <= 0 && dist < beamLength) {
          state = WardenState.aim;
          _timer = aimTime;
          final at = atan2(toPlayer.y, toPlayer.x);
          final side = _cycles.isEven ? 1 : -1;
          _sweepFrom = at - sweepHalfArc * side;
          _sweepTo = at + sweepHalfArc * side;
          beamAngle = _sweepFrom;
          return Vector2.zero();
        }
        return super.desiredVelocity(dt, toPlayer, dist);
      case WardenState.aim:
        beamReach = _reach(beamAngle);
        if (_timer <= 0) {
          state = WardenState.sweep;
          _timer = sweepTime;
          game.shake(3);
        }
        return Vector2.zero();
      case WardenState.sweep:
        final t = (1 - _timer / sweepTime).clamp(0.0, 1.0);
        beamAngle = _sweepFrom + (_sweepTo - _sweepFrom) * t;
        beamReach = _reach(beamAngle);
        _burnPlayer();
        if (_timer <= 0) {
          state = WardenState.exposed;
          _timer = exposedTime;
          if (_cycles.isOdd) _dropPack();
          _cycles++;
        }
        return Vector2.zero();
      case WardenState.exposed:
        if (_timer <= 0) {
          state = WardenState.walk;
          _timer = walkTime;
        }
        return Vector2.zero();
    }
  }

  @override
  void faceToward(Vector2 v) {
    if (state == WardenState.aim || state == WardenState.sweep) {
      angle = beamAngle;
    } else if (state == WardenState.walk) {
      super.faceToward(v);
    }
  }

  /// How far the beam gets before a wall or wreck stops it.
  double _reach(double a) {
    final dir = Vector2(cos(a), sin(a));
    for (var d = type.radius; d < beamLength; d += 6) {
      final p = position + dir * d;
      final o = p.toOffset();
      if (!game.arena.contains(o) || game.obstacles.any((r) => r.contains(o))) {
        return d;
      }
    }
    return beamLength;
  }

  void _burnPlayer() {
    final p = game.player;
    final dir = Vector2(cos(beamAngle), sin(beamAngle));
    final to = p.position - position;
    final along = to.dot(dir);
    if (along < 0 || along > beamReach) return;
    final across = (to - dir * along).length;
    if (across <= beamHalfWidth + Player.radius) {
      p.takeBite(beamDamage, Vector2(-dir.y, dir.x));
    }
  }

  void _dropPack() {
    for (var i = 0; i < 5; i++) {
      final a = i / 5 * pi * 2;
      game.waves.addEnemy(
        Skitter(position + Vector2(cos(a), sin(a)) * (type.radius + 10)),
      );
    }
  }

  /// Where the weak spot sits: on its back, away from the beam emitter.
  Vector2 get weakSpot => position - Vector2(cos(angle), sin(angle)) * 8;
}

/// The Warden's glowing parts, drawn above the darkness: the aiming line,
/// the beam, and the open weak spot.
class WardenFx extends Component with HasGameReference<DuskHordeGame> {
  WardenFx(this.warden) : super(priority: 110);

  final Warden warden;

  static final _aim = Paint()
    ..color = const Color(0xAAFF5040)
    ..strokeWidth = 1.5;
  static final _beamGlow = Paint()
    ..color = const Color(0x66FF6A3A)
    ..strokeWidth = Warden.beamHalfWidth * 2 + 6
    ..strokeCap = StrokeCap.round;
  static final _beamCore = Paint()
    ..color = const Color(0xFFFFE0B0)
    ..strokeWidth = 4
    ..strokeCap = StrokeCap.round;
  static final _spotGlow = Paint()..color = const Color(0x88FF9A3C);
  static final _spot = Paint()..color = const Color(0xFFFFC060);

  @override
  void render(Canvas canvas) {
    final w = warden;
    if (!w.isAlive) return;
    final from = w.position.toOffset();
    final dir = Offset(cos(w.beamAngle), sin(w.beamAngle));
    final to = from + dir * w.beamReach;
    switch (w.state) {
      case WardenState.aim:
        // Blinks faster as the sweep gets close.
        final blink = (w._timer * 12).floor().isEven;
        if (blink) canvas.drawLine(from, to, _aim);
      case WardenState.sweep:
        canvas.drawLine(from, to, _beamGlow);
        canvas.drawLine(from, to, _beamCore);
      case WardenState.exposed:
        final s = w.weakSpot.toOffset();
        final pulse = 1 + 0.25 * sin(w.age * 10);
        canvas.drawCircle(s, 9 * pulse, _spotGlow);
        canvas.drawCircle(s, 4, _spot);
      case WardenState.walk:
        break;
    }
  }
}

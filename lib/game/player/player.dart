import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../dusk_horde_game.dart';
import '../fx/muzzle_flash.dart';
import '../game_assets.dart';
import '../../meta/weapon_catalog.dart';
import '../weapons/bullet.dart';
import '../weapons/gun.dart';
import '../world/obstacles.dart';
import 'dodge.dart';

/// The survivor. Left stick moves, right stick aims and auto-fires.
class Player extends SpriteComponent with HasGameReference<DuskHordeGame> {
  Player() : super(anchor: Anchor.center, priority: 10);

  static const moveSpeed = 120.0; // px per second
  static const dodgeSpeed = 360.0;
  static const radius = 10.0;
  static const aimAssistAngle = 15 * pi / 180;
  static const hurtGrace = 0.6; // seconds of safety after a bite

  /// Test Mode: you take a fifth of the damage and deal three times as much.
  static const testDamageTaken = 0.2;
  static const testDamageDealt = 3.0;

  late double hp = maxHealth;
  double get maxHealth => game.progress.maxHp;

  void heal(double amount) {
    if (!isAlive) return;
    hp = min(maxHealth, hp + amount);
    add(
      ColorEffect(
        const Color(0xFF60FF70),
        EffectController(duration: 0.1, reverseDuration: 0.2),
        opacityTo: 0.5,
      ),
    );
  }

  bool get isAlive => hp > 0;
  double _hurtTimer = 0;
  final Vector2 _knock = Vector2.zero();

  /// How close an enemy must be to bite.
  double get radiusForBites => radius + 2;

  /// Where the gun and flashlight point, radians (0 = right).
  double aimAngle = 0;

  late Dodge dodge;

  /// The loadout for this run, in swap order.
  final List<Gun> guns = [];
  int _gunIndex = 0;
  Gun get gun => guns[_gunIndex];
  final Vector2 _dodgeDir = Vector2(1, 0);

  /// Seconds standing still (the rifle's Marksman signature).
  double stillTime = 0;
  static const marksmanDelay = 1.0;

  bool get marksmanReady =>
      gun.hasSignature &&
      gun.def.signature == Signature.marksman &&
      stillTime >= marksmanDelay;

  @override
  Future<void> onLoad() async {
    sprite = Sprite(game.images.fromCache(GameAssets.player));
    size = sprite!.srcSize;
    paint = Paint()..filterQuality = FilterQuality.none;
    equip();
  }

  /// Builds this run's guns and perks from saved progress.
  void equip() {
    final p = game.progress;
    dodge = Dodge(cooldown: 1.5 * p.dodgeCooldownScale);
    guns
      ..clear()
      ..addAll([
        for (final id in p.loadout)
          if (p.hasGun(id))
            Gun(
              Weapons.byId(id),
              p.statsFor(Weapons.byId(id)),
              hasSignature: p.hasSignature(id),
            ),
      ]);
    if (guns.isEmpty) guns.add(Gun(Weapons.pistol, Weapons.pistol.base));
    _gunIndex = 0;
  }

  void swapGun() {
    if (guns.length < 2) return;
    _gunIndex = (_gunIndex + 1) % guns.length;
  }

  /// Ammo box: tops up every gun that uses ammo by 40% of its capacity.
  void addAmmoShare(double share) {
    for (final g in guns) {
      final cap = g.mag.maxReserve;
      if (cap != null) g.mag.addReserve((cap * share).round());
    }
  }

  void refillAmmo() {
    for (final g in guns) {
      final cap = g.mag.maxReserve;
      if (cap != null) g.mag.addReserve(cap);
    }
  }

  /// Called by enemies. Dodging and the short grace after a bite ignore it.
  void takeBite(double damage, Vector2 from) {
    if (!isAlive || dodge.isInvincible || _hurtTimer > 0) return;
    if (game.progress.testMode) damage *= testDamageTaken;
    hp = max(0, hp - damage);
    _hurtTimer = hurtGrace;
    _knock.setFrom(from..scale(140));
    add(
      ColorEffect(
        const Color(0xFFFF2020),
        EffectController(duration: 0.08, reverseDuration: 0.15),
        opacityTo: 0.7,
      ),
    );
    game.shake(4);
    if (!isAlive) game.onPlayerDied();
  }

  void revive() {
    equip();
    hp = maxHealth;
    _hurtTimer = 0;
    _knock.setZero();
    stillTime = 0;
    position.setFrom(game.level.playerStart);
    opacity = 1;
  }

  void tryDodge() {
    final move = game.moveStick.vector;
    _dodgeDir.setFrom(
      move.length2 > 0.01
          ? move.normalized()
          : Vector2(cos(aimAngle), sin(aimAngle)),
    );
    if (dodge.tryStart()) {
      add(
        OpacityEffect.to(
          0.45,
          EffectController(
            duration: dodge.duration / 2,
            reverseDuration: dodge.duration / 2,
          ),
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isAlive) return;
    if (_hurtTimer > 0) _hurtTimer -= dt;
    dodge.update(dt);
    for (final g in guns) {
      g.mag.update(dt);
    }

    final move = game.moveStick.vector;
    if (move.length2 < 0.01 && !dodge.isRolling) {
      stillTime += dt;
    } else {
      stillTime = 0;
    }
    if (dodge.isRolling) {
      position.addScaled(_dodgeDir, dodgeSpeed * dt);
    } else {
      position.addScaled(move, moveSpeed * dt);
    }
    if (_knock.length2 > 1) {
      position.addScaled(_knock, dt);
      _knock.scale(0.8);
    }
    _keepOffStatics();
    pushOutOfRects(position, radius, game.obstacles);
    _clampToArena();

    final aim = game.aimStick.vector;
    if (aim.length2 > 0.0001) {
      aimAngle = _assist(atan2(aim.y, aim.x));
      if (aim.length > 0.3 && !dodge.isRolling) _shoot();
    } else if (move.length2 > 0.0001) {
      aimAngle = atan2(move.y, move.x);
    }
    angle = aimAngle;
  }

  void _shoot() {
    final g = gun;
    if (!g.mag.tryFire()) return;
    final s = g.stats;
    final dir = Vector2(cos(aimAngle), sin(aimAngle));
    final muzzle = position + dir * 15;
    final sig = g.hasSignature ? g.def.signature : null;
    var damage = s.damage;
    if (game.progress.testMode) damage *= testDamageDealt;
    var pierce = s.pierce;
    // Last Word: the magazine's final round hits three times as hard.
    if (sig == Signature.lastWord && g.mag.rounds == 0) damage *= 3;
    // Marksman: a shot after standing still pierces and hits twice as hard.
    if (marksmanReady) {
      damage *= 2;
      pierce += 3;
      stillTime = 0;
    }
    for (var i = 0; i < s.pellets; i++) {
      // Pellets fan evenly across the spread; single shots wobble randomly.
      final offset = s.pellets > 1
          ? s.spread * (i / (s.pellets - 1) - 0.5) +
                (game.random.nextDouble() - 0.5) * 0.06
          : (game.random.nextDouble() - 0.5) * s.spread;
      final crit = game.random.nextDouble() < s.critChance;
      game.bullets.fire(
        muzzle,
        aimAngle + offset,
        ShotPayload(
          damage: crit ? damage * 2 : damage,
          pierce: pierce,
          bleed: sig == Signature.shredder,
          burn: sig == Signature.dragonsBreath,
          range: s.range,
        ),
      );
    }
    game.world.add(MuzzleFlash(muzzle));
    game.shake(switch (g.def.id) {
      'smg' => 0.5,
      'shotgun' => 2.2,
      _ => 0.8,
    });
  }

  /// Nudges the aim toward the nearest living target within 15 degrees.
  double _assist(double raw) {
    double? best;
    var bestDiff = aimAssistAngle;
    for (final t in game.waves.alive) {
      if (!t.isAlive || !t.isTargetable) continue;
      final to = t.position - position;
      if (to.length > 260) continue;
      final a = atan2(to.y, to.x);
      final diff = atan2(sin(a - raw), cos(a - raw)).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = a;
      }
    }
    return best ?? raw;
  }

  /// Enemies step out of your way (see Enemy), but rooted ones like Brood
  /// Pods can't, so you are the one stopped at their edge.
  void _keepOffStatics() {
    for (final e in game.waves.alive) {
      if (!e.isStatic || !e.isAlive) continue;
      final away = position - e.position;
      final minDist = e.type.radius + radius;
      final d = away.length;
      if (d >= minDist || d < 0.0001) continue;
      position.addScaled(away, (minDist - d) / d);
    }
  }

  void _clampToArena() {
    final r = game.arena.deflate(radius);
    position.x = position.x.clamp(r.left, r.right);
    position.y = position.y.clamp(r.top, r.bottom);
  }
}

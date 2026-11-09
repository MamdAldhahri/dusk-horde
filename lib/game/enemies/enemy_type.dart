import '../game_assets.dart';

/// How an enemy moves on top of following the flow field.
enum Gait {
  /// Straight along the path.
  walk,

  /// Weaves side to side, harder to hit.
  zigzag,
}

/// Everything that makes one enemy kind different, as plain data. New
/// apocalypses add entries here plus their sprites; the Enemy class stays.
class EnemyType {
  const EnemyType({
    required this.id,
    required this.sprite,
    required this.hp,
    required this.speed,
    required this.radius,
    required this.biteDamage,
    this.gait = Gait.walk,
    this.biteCooldown = 1.0,
  });

  final String id;
  final String sprite;
  final double hp;

  /// Pixels per second. The player walks at 120.
  final double speed;
  final double radius;
  final double biteDamage;
  final double biteCooldown;
  final Gait gait;
}

/// Level 1 roster. Speeds follow the plan: Shambler 50%, Runner 130% of the
/// player's walking speed.
class Zombies {
  Zombies._();

  static const shambler = EnemyType(
    id: 'shambler',
    sprite: GameAssets.zombieShambler,
    hp: 30,
    speed: 60,
    radius: 10,
    biteDamage: 10,
  );

  static const runner = EnemyType(
    id: 'runner',
    sprite: GameAssets.zombieRunner,
    hp: 20,
    speed: 156,
    radius: 9,
    biteDamage: 6,
    biteCooldown: 0.7,
    gait: Gait.zigzag,
  );
}

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
    this.scale = 1,
    this.dropChance = 0.06,
    this.explodeRadius = 0,
    this.explodeDamage = 0,
    this.isBoss = false,
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

  /// Drawn bigger than the sprite (elites).
  final double scale;

  /// Chance to drop a medkit on death.
  final double dropChance;

  /// If above 0, bursts on death, hurting everything within this radius.
  final double explodeRadius;
  final double explodeDamage;
  final bool isBoss;
}

/// Level 1 roster. Speeds follow the plan as a share of the player's 120:
/// Shambler 50%, Runner 130%, Bloater 40%, Brute 60%.
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

  /// The wave 5 mini-boss: a big, tough Shambler.
  static const eliteShambler = EnemyType(
    id: 'elite_shambler',
    sprite: GameAssets.zombieShambler,
    hp: 120,
    speed: 66,
    radius: 13,
    biteDamage: 18,
    scale: 1.4,
    dropChance: 1,
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

  static const bloater = EnemyType(
    id: 'bloater',
    sprite: GameAssets.zombieBloater,
    hp: 80,
    speed: 48,
    radius: 13,
    biteDamage: 15,
    dropChance: 0.2,
    explodeRadius: 52,
    explodeDamage: 30,
  );

  static const brute = EnemyType(
    id: 'brute',
    sprite: GameAssets.zombieBrute,
    hp: 300,
    speed: 72,
    radius: 18,
    biteDamage: 20,
    biteCooldown: 1.2,
    dropChance: 1,
    isBoss: true,
  );
}

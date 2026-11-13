import '../game_assets.dart';

/// How an enemy moves on top of following the flow field.
enum Gait {
  /// Straight along the path.
  walk,

  /// Weaves side to side, harder to hit.
  zigzag,
}

/// Which class runs the enemy. Data picks the behaviour, so wave plans stay
/// plain lists of [EnemyType].
enum EnemyKind { basic, brute, skitter, lancer, stalker, broodPod, warden }

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
    this.scrap = 2,
    this.kind = EnemyKind.basic,
    this.pack = 1,
    this.name = '',
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

  /// Scrap earned for the kill.
  final int scrap;

  final EnemyKind kind;

  /// Spawns this many at once from the same point (Skitter packs).
  final int pack;

  /// Shown on the boss bar.
  final String name;
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
    scrap: 15,
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
    scrap: 3,
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
    scrap: 6,
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
    scrap: 60,
    kind: EnemyKind.brute,
    name: 'THE BRUTE',
  );
}

/// Level 2 roster, from the plan: Skitter 150%, Lancer 70%, Stalker 110%,
/// Brood Pod static, the Warden 40% of the player's 120.
class Aliens {
  Aliens._();

  static const skitter = EnemyType(
    id: 'skitter',
    sprite: GameAssets.alienSkitter,
    hp: 12,
    speed: 180,
    radius: 7,
    biteDamage: 5,
    biteCooldown: 0.6,
    dropChance: 0.03,
    kind: EnemyKind.skitter,
    pack: 7,
  );

  static const lancer = EnemyType(
    id: 'lancer',
    sprite: GameAssets.alienLancer,
    hp: 45,
    speed: 84,
    radius: 10,
    biteDamage: 8,
    scrap: 5,
    kind: EnemyKind.lancer,
  );

  /// Mini-boss on waves 5 and 10: fires three bolts at once.
  static const eliteLancer = EnemyType(
    id: 'elite_lancer',
    sprite: GameAssets.alienLancer,
    hp: 160,
    speed: 80,
    radius: 13,
    biteDamage: 12,
    scale: 1.4,
    dropChance: 1,
    scrap: 15,
    kind: EnemyKind.lancer,
  );

  static const stalker = EnemyType(
    id: 'stalker',
    sprite: GameAssets.alienStalker,
    hp: 50,
    speed: 132,
    radius: 10,
    biteDamage: 14,
    biteCooldown: 0.9,
    scrap: 6,
    kind: EnemyKind.stalker,
  );

  static const broodPod = EnemyType(
    id: 'brood_pod',
    sprite: GameAssets.alienBroodPod,
    hp: 150,
    speed: 0,
    radius: 14,
    biteDamage: 0,
    dropChance: 0.3,
    scrap: 10,
    kind: EnemyKind.broodPod,
  );

  static const warden = EnemyType(
    id: 'warden',
    sprite: GameAssets.alienWarden,
    hp: 1200,
    speed: 48,
    radius: 24,
    biteDamage: 25,
    biteCooldown: 1.2,
    dropChance: 1,
    isBoss: true,
    scrap: 150,
    kind: EnemyKind.warden,
    name: 'THE WARDEN',
  );
}

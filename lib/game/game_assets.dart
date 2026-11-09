/// Every sprite the game loads, in one place.
///
/// Art is placeholder and will be replaced: drop a new PNG in
/// `assets/images/sprites/` with the same file name and nothing else changes.
/// Rules: one PNG per character, facing right, 32 x 32 (Brute 48 x 48,
/// Warden 64 x 64).
class GameAssets {
  GameAssets._();

  static const player = 'sprites/player.png';

  static const zombieShambler = 'sprites/zombie_shambler.png';
  static const zombieRunner = 'sprites/zombie_runner.png';
  static const zombieBloater = 'sprites/zombie_bloater.png';
  static const zombieBrute = 'sprites/zombie_brute.png';
  static const zombieSpitter = 'sprites/zombie_spitter.png';

  static const alienSkitter = 'sprites/alien_skitter.png';
  static const alienLancer = 'sprites/alien_lancer.png';
  static const alienStalker = 'sprites/alien_stalker.png';
  static const alienBroodPod = 'sprites/alien_brood_pod.png';
  static const alienWarden = 'sprites/alien_warden.png';

  /// Loaded up front by [DuskHordeGame.onLoad].
  static const all = [
    player,
    zombieShambler,
    zombieRunner,
    zombieBloater,
    zombieBrute,
    zombieSpitter,
    alienSkitter,
    alienLancer,
    alienStalker,
    alienBroodPod,
    alienWarden,
  ];
}

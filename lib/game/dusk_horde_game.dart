import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';

import '../meta/progress.dart';
import '../meta/save_store.dart';
import 'audio/game_audio.dart';
import 'enemies/enemy.dart';
import 'enemies/plasma_bolt.dart';
import 'fx/explosion.dart';
import 'fx/flashlight.dart';
import 'game_assets.dart';
import 'hud.dart';
import 'input/virtual_stick.dart';
import 'levels.dart';
import 'pickups/ammo_box.dart';
import 'pickups/medkit.dart';
import 'pickups/supply_crate.dart';
import 'player/player.dart';
import 'waves/wave_manager.dart';
import 'weapons/bullet.dart';
import 'world/flow_field.dart';
import 'world/level_map.dart';
import 'world/obstacle_layer.dart';

/// The whole game: one level at a time (the Gas Station or the Crash Site),
/// in story mode (survive until dawn) or Endless.
class DuskHordeGame extends FlameGame {
  DuskHordeGame({
    Random? random,
    this.firstBreather = 3,
    this.startLevel = Levels.gasStation,
    this.endless = false,
    Progress? progress,
    SaveStore? store,
    this.showWorkbenchOnStart = false,
    GameAudio? audio,
  }) : random = random ?? Random(),
       progress = progress ?? Progress(),
       store = store ?? MemorySaveStore(),
       audio = audio ?? SilentAudio();

  /// Height of the visible world in game pixels, whatever the phone.
  static const viewHeight = 360.0;
  static const gameOverOverlay = 'gameOver';
  static const dawnOverlay = 'dawn';
  static const workbenchOverlay = 'workbench';
  static const pauseOverlay = 'pause';
  static const settingsOverlay = 'settings';

  /// Wave reached at the Gas Station that unlocks the SMG.
  static const smgUnlockWave = 5;

  /// Wave reached at the Crash Site that unlocks the rifle.
  static const rifleUnlockWave = 8;

  final Random random;
  final double firstBreather;
  final LevelDef startLevel;
  final Progress progress;
  final SaveStore store;
  final bool showWorkbenchOnStart;
  final GameAudio audio;

  /// The level being played and whether this run is Endless.
  late LevelDef levelDef;
  bool endless;

  /// Scrap and boss cores earned this run; banked when the run ends.
  int runScrap = 0;
  int runCores = 0;

  /// What this run unlocked, for the end-of-run panel.
  final List<String> unlockedThisRun = [];

  late LevelMap level;
  Rect get arena => level.bounds;
  late List<Rect> obstacles;
  List<Vector2> get spawnPoints => level.spawns;

  late final Player player;
  late final BulletPool bullets;
  late FlowField flowField;
  late final WaveManager waves;
  late final VirtualStick moveStick;
  late final VirtualStick aimStick;
  late final Flashlight flashlight;
  ObstacleLayer? _obstacleLayer;
  SupplyCrate? crate;

  bool isGameOver = false;
  bool isDawn = false;

  /// Paused from the HUD button or by leaving the app mid-run.
  bool isPausedByPlayer = false;

  /// A run is going on: not on the workbench, not over.
  bool get inRun =>
      !isGameOver && !isDawn && !overlays.isActive(workbenchOverlay);
  double _shake = 0;

  @override
  Color backgroundColor() => const Color(0xFF050407);

  @override
  Future<void> onLoad() async {
    await images.loadAll(GameAssets.all);
    _applyVolumes();
    await audio.load();
    bullets = BulletPool(world);
    player = Player();
    waves = WaveManager(plan: startLevel.plan, firstBreather: firstBreather)
      ..endless = endless;
    flashlight = Flashlight();
    await _loadLevel(startLevel);
    player.position = level.playerStart.clone();

    world.addAll([player, flashlight]);
    add(waves);

    double stickScale() => progress.settings.stickScale;
    moveStick = VirtualStick(leftSide: true, scale: stickScale);
    aimStick = VirtualStick(leftSide: false, scale: stickScale);
    camera.viewport.addAll([moveStick, aimStick, Hud()]);
    if (showWorkbenchOnStart) {
      openWorkbench();
    } else {
      _startMusic();
    }
  }

  void _startMusic() => audio.playMusic(levelDef.music);

  void _applyVolumes() => audio.setVolumes(
    sfx: progress.settings.sfxVolume,
    music: progress.settings.musicVolume,
  );

  /// Swaps the map, its collision and its waves for [def].
  Future<void> _loadLevel(LevelDef def) async {
    final next = await LevelMap.load(def.mapFile);
    if (isLoaded) {
      level.component.removeFromParent();
      _obstacleLayer?.removeFromParent();
      crate?.removeFromParent();
      crate = null;
    }
    levelDef = def;
    level = next;
    obstacles = level.obstacles;
    flowField = FlowField(bounds: arena, obstacles: obstacles);
    waves.plan = def.plan;
    world.addAll([
      level.component,
      _obstacleLayer = ObstacleLayer(level.blockers),
    ]);
    final cratePos = level.supplyCrate;
    if (cratePos != null) world.add(crate = SupplyCrate(cratePos));
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    camera.viewfinder.zoom = size.y / viewHeight;
  }

  /// Adds camera shake; strongest request wins, then it fades.
  void shake(double amount) => _shake = max(_shake, amount);

  /// The first living enemy a point at [p] touches, if any.
  Enemy? targetHitBy(Vector2 p, {Set<Enemy> except = const {}}) {
    for (final e in waves.alive) {
      if (except.contains(e)) continue;
      if (e.position.distanceTo(p) <= e.hitRadius) return e;
    }
    return null;
  }

  /// A burst that hurts the player and other enemies (Bloater death).
  /// Enemies take double, so popping a Bloater in a crowd pays off.
  void explode(Vector2 at, double radius, double damage) {
    world.add(Explosion(at, radius));
    audio.play(Sfx.explosion);
    shake(5);
    if (player.position.distanceTo(at) <= radius + Player.radius) {
      player.takeBite(damage, (player.position - at)..normalize());
    }
    for (final e in [...waves.alive]) {
      final d = e.position - at;
      if (d.length <= radius + e.type.radius) {
        e.takeHit(damage * 2, d.length2 > 0 ? d : Vector2(1, 0));
      }
    }
  }

  void dropMedkit(Vector2 at) => world.add(Medkit(at, lifetime: 20));

  /// Scrap for every kill. A boss gives a core the first time its level is
  /// beaten, and every time in Endless. Guns that use ammo make enemies
  /// drop ammo boxes now and then.
  void onKill(Enemy e) {
    runScrap += (e.type.scrap * progress.scrapScale).round();
    if (e.type.isBoss && (endless || !progress.beaten.contains(levelDef.id))) {
      runCores++;
    }
    final usesAmmo = player.guns.any((g) => !g.mag.isInfinite);
    if (usesAmmo && random.nextDouble() < 0.08) {
      world.add(AmmoBox(e.position.clone()));
    }
  }

  void onWaveStarted(int wave) {
    audio.play(Sfx.waveStart, volume: 0.7);
    if (levelDef == Levels.gasStation && wave >= smgUnlockWave) {
      _unlockGun('smg', 'SMG');
    }
    if (levelDef == Levels.crashSite && wave >= rifleUnlockWave) {
      _unlockGun('rifle', 'Assault Rifle');
    }
  }

  void _unlockGun(String id, String name) {
    if (progress.unlocked.contains(id)) return;
    progress.unlock(id);
    unlockedThisRun.add(name);
    audio.play(Sfx.unlock);
    store.save(progress);
  }

  /// Bonus scrap for clearing a wave: [waveBonus] x the wave number. Tuned
  /// so a first clear pays about 700 (Gas Station) and 1,400 (Crash Site),
  /// together enough to max out one gun.
  static const waveBonus = 3;

  void onWaveCleared(int wave) {
    runScrap += (waveBonus * wave * progress.scrapScale).round();
  }

  /// Puts the run's takings into saved progress and writes it to disk.
  void _bankRun() {
    progress.bank(
      scrap: runScrap,
      cores: runCores,
      wave: waves.wave,
      level: levelDef.id,
      endless: endless,
    );
    store.save(progress);
  }

  /// Between waves: put a medkit on up to two empty pickup spots.
  void onBreather() {
    final taken = world.children.whereType<Medkit>().map((m) => m.position);
    final free =
        level.pickups
            .where((p) => taken.every((t) => t.distanceTo(p) > 8))
            .toList()
          ..shuffle(random);
    for (final p in free.take(2)) {
      world.add(Medkit(p.clone()));
    }
  }

  void onPlayerDied() {
    isGameOver = true;
    audio.stopMusic();
    _bankRun();
    shake(8);
    _showOverlay(gameOverOverlay);
    pauseEngine();
  }

  /// The final wave is cleared: the level is beaten. A first clear opens
  /// what comes next.
  void onDawn() {
    isDawn = true;
    audio
      ..stopMusic()
      ..play(Sfx.dawn);
    final first = progress.beaten.add(levelDef.id);
    if (levelDef == Levels.gasStation) {
      _unlockGun('shotgun', 'Shotgun');
      if (first) unlockedThisRun.add('The Crash Site');
    } else if (levelDef == Levels.crashSite && first) {
      unlockedThisRun.add('Endless mode');
    }
    _bankRun();
    _showOverlay(dawnOverlay);
    pauseEngine();
  }

  void _showOverlay(String name) {
    if (overlays.registeredOverlays.contains(name)) overlays.add(name);
  }

  /// Pauses on the workbench (main menu).
  void openWorkbench() {
    audio.stopMusic();
    overlays.removeAll([gameOverOverlay, dawnOverlay, pauseOverlay]);
    _showOverlay(workbenchOverlay);
    pauseEngine();
  }

  /// Starts a run on the level and mode picked on the workbench, loading
  /// that map first if it isn't the current one.
  Future<void> deploy() async {
    final def = Levels.byId(progress.level);
    final open = progress.isLevelOpen(def.id);
    final target = open ? def : Levels.gasStation;
    if (target != levelDef) await _loadLevel(target);
    endless = progress.endless && progress.endlessOpen;
    restart();
  }

  /// Back to wave 1 with full health and the current loadout.
  void restart() {
    isGameOver = false;
    isDawn = false;
    runScrap = 0;
    runCores = 0;
    unlockedThisRun.clear();
    isPausedByPlayer = false;
    overlays.removeAll([
      gameOverOverlay,
      dawnOverlay,
      workbenchOverlay,
      pauseOverlay,
      settingsOverlay,
    ]);
    waves
      ..endless = endless
      ..reset();
    for (final c in [
      ...world.children.whereType<Medkit>(),
      ...world.children.whereType<AmmoBox>(),
      ...world.children.whereType<PlasmaBolt>(),
    ]) {
      c.removeFromParent();
    }
    crate?.reset();
    player.revive();
    moveStick.vector.setZero();
    aimStick.vector.setZero();
    resumeEngine();
    _startMusic();
  }

  /// Freezes the run and shows the pause menu.
  void pauseRun() {
    if (!inRun || isPausedByPlayer) return;
    isPausedByPlayer = true;
    moveStick.vector.setZero();
    aimStick.vector.setZero();
    audio.pauseMusic();
    _showOverlay(pauseOverlay);
    pauseEngine();
  }

  void resumeRun() {
    if (!isPausedByPlayer) return;
    isPausedByPlayer = false;
    overlays.removeAll([pauseOverlay, settingsOverlay]);
    audio.resumeMusic();
    resumeEngine();
  }

  /// Gives up the run from the pause menu. Scrap earned so far is banked,
  /// the same as dying.
  void quitRun() {
    isPausedByPlayer = false;
    isGameOver = true;
    _bankRun();
    openWorkbench();
  }

  void openSettings() => _showOverlay(settingsOverlay);

  /// Saves and applies whatever the settings panel changed.
  void closeSettings() {
    overlays.remove(settingsOverlay);
    applySettings();
    store.save(progress);
  }

  void applySettings() => _applyVolumes();

  /// Leaving the app mid-run opens the pause menu, so coming back never
  /// drops you straight into a fight.
  @override
  void lifecycleStateChange(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      if (isLoaded) pauseRun();
    }
    super.lifecycleStateChange(state);
  }

  @override
  void update(double dt) {
    flowField.update(player.position);
    super.update(dt);
    final offset = _shake > 0.05
        ? (Vector2(random.nextDouble() - 0.5, random.nextDouble() - 0.5)
            ..scale(_shake * 2))
        : Vector2.zero();
    _shake *= pow(0.0005, dt).toDouble();
    camera.viewfinder.position = _cameraTarget() + offset;
  }

  /// Follows the player but stops at the map edge.
  Vector2 _cameraTarget() {
    final zoom = camera.viewfinder.zoom;
    final halfW = size.x / zoom / 2;
    final halfH = size.y / zoom / 2;
    double clampAxis(double v, double lo, double hi, double half) =>
        hi - lo <= half * 2 ? (lo + hi) / 2 : v.clamp(lo + half, hi - half);
    return Vector2(
      clampAxis(player.position.x, arena.left, arena.right, halfW),
      clampAxis(player.position.y, arena.top, arena.bottom, halfH),
    );
  }
}

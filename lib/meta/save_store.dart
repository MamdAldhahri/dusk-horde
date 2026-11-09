import 'package:shared_preferences/shared_preferences.dart';

import 'progress.dart';

/// Where [Progress] lives between app launches.
abstract class SaveStore {
  Future<Progress> load();
  Future<void> save(Progress p);
}

/// The phone's local storage.
class PrefsSaveStore implements SaveStore {
  static const _key = 'dusk_horde.progress';

  @override
  Future<Progress> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return Progress();
    try {
      return Progress.decode(raw);
    } on Object {
      // A broken save should never stop the game from starting.
      return Progress();
    }
  }

  @override
  Future<void> save(Progress p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, p.encode());
  }
}

/// Keeps progress in memory only (tests, or before storage is ready).
class MemorySaveStore implements SaveStore {
  Progress? saved;
  int saves = 0;

  @override
  Future<Progress> load() async => saved ?? Progress();

  @override
  Future<void> save(Progress p) async {
    saved = Progress.decode(p.encode());
    saves++;
  }
}

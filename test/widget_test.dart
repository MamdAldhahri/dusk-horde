import 'dart:io';

import 'package:dusk_horde/game/game_assets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every listed sprite lives under sprites/', () {
    expect(GameAssets.all, isNotEmpty);
    for (final path in GameAssets.all) {
      expect(path, startsWith('sprites/'));
      expect(path, endsWith('.png'));
      expect(File('assets/images/$path').existsSync(), isTrue, reason: path);
    }
  });
}

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/dusk_horde_game.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const DuskHordeApp());
}

class DuskHordeApp extends StatelessWidget {
  const DuskHordeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dusk Horde',
      debugShowCheckedModeBanner: false,
      home: GameWidget(game: DuskHordeGame()),
    );
  }
}

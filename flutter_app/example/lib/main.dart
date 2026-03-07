import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:renpy_flutter/renpy_flutter.dart';

import 'screens/game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const RenpyFlutterApp());
}

class RenpyFlutterApp extends StatelessWidget {
  const RenpyFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ren\'Py Flutter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const _GameLoader(),
    );
  }
}

class _GameLoader extends StatefulWidget {
  const _GameLoader();

  @override
  State<_GameLoader> createState() => _GameLoaderState();
}

class _GameLoaderState extends State<_GameLoader> {
  GameExecutor? _executor;
  late final CharacterRegistry _characters;
  late final ImageCache _imageCache;
  String? _error;

  @override
  void initState() {
    super.initState();
    _characters = CharacterRegistry();
    _imageCache = ImageCache();
    _initGame();
  }

  Future<void> _initGame() async {
    try {
      // Register characters
      _characters.register(const Character(
        id: 'e',
        name: 'Eileen',
        color: Color(0xFFC8A0FF),
      ));
      _characters.register(const Character(
        id: 'n',
        name: 'Narrator',
        color: Colors.white,
      ));

      // Load script
      final manager = ScriptManager();
      await manager.loadAssets(['assets/scripts/script.rpy']);

      if (!manager.hasLabel('start')) {
        throw Exception('No "start" label found in script.');
      }

      final executor = GameExecutor(
        labels: manager.labels,
        initialState: GameState.initial('start'),
      );

      setState(() => _executor = executor);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _executor?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_executor == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return GameScreen(
      executor: _executor!,
      characterRegistry: _characters,
      imageCache: _imageCache,
    );
  }
}

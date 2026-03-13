import 'package:flutter/material.dart';
import 'package:renpy_flutter/renpy_flutter.dart';

import 'scene_config.dart';
import 'screens/game_screen.dart';

/// Loads a [SceneConfig] asynchronously, then renders [GameScreen].
class SceneLoaderPage extends StatefulWidget {
  final SceneConfig config;

  const SceneLoaderPage({super.key, required this.config});

  @override
  State<SceneLoaderPage> createState() => _SceneLoaderPageState();
}

class _SceneLoaderPageState extends State<SceneLoaderPage> {
  GameExecutor? _executor;
  final _characters = CharacterRegistry();
  final _imageCache = ImageCache();
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      for (final char in widget.config.characters) {
        _characters.register(char);
      }
      final manager = ScriptManager();
      await manager.loadAssets(widget.config.scripts);
      setState(() {
        _executor = GameExecutor(
          labels: manager.labels,
          initialState: GameState.initial(widget.config.startLabel),
        );
      });
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
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
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

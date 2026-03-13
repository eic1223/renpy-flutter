/// Main game screen — wires executor events to display/UI layers.
library;

import 'package:flutter/material.dart';
import 'package:renpy_flutter/renpy_flutter.dart';

// ─── What's being shown ───────────────────────────────────────────────────────

sealed class _DisplayMode {}

class _Idle extends _DisplayMode {}

class _ShowingDialogue extends _DisplayMode {
  final Character character;
  final String text;
  _ShowingDialogue(this.character, this.text);
}

class _ShowingMenu extends _DisplayMode {
  final List<MenuChoice> choices;
  _ShowingMenu(this.choices);
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class GameScreen extends StatefulWidget {
  final GameExecutor executor;
  final CharacterRegistry characterRegistry;
  final ImageCache imageCache;

  const GameScreen({
    super.key,
    required this.executor,
    required this.characterRegistry,
    required this.imageCache,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  _DisplayMode _mode = _Idle();
  LayerState _layers = const LayerState();

  @override
  void initState() {
    super.initState();
    widget.executor.events.listen(_handleEvent);
    // Start running the script.
    widget.executor.run();
  }

  void _handleEvent(GameEvent event) {
    switch (event) {
      case ShowDialogueEvent():
        setState(() {
          _mode = _ShowingDialogue(
            widget.characterRegistry.resolve(event.characterId),
            event.text,
          );
        });

      case ShowMenuEvent():
        setState(() => _mode = _ShowingMenu(event.choices));

      case ShowSceneEvent():
        final transition = resolveTransition(event.with_);
        setState(() {
          _layers = _layers.copyWith(
            background: event.imageName,
            clearBackground: event.imageName == null,
            sprites: {}, // scene clears sprites
            transition: transition,
          );
          _mode = _Idle();
        });

      case ShowImageEvent():
        final tag = event.imageName.split(' ').first;
        final sprites = Map.of(_layers.sprites)
          ..[tag] = SpriteInfo(imageName: event.imageName);
        final transition = resolveTransition(event.with_);
        setState(() {
          _layers = _layers.copyWith(sprites: sprites, transition: transition);
        });

      case HideImageEvent():
        final tag = event.imageName.split(' ').first;
        final sprites = Map.of(_layers.sprites)..remove(tag);
        final transition = resolveTransition(event.with_);
        setState(() {
          _layers = _layers.copyWith(sprites: sprites, transition: transition);
        });

      case PlayAudioEvent():
      case StopAudioEvent():
        // Audio handled by AudioController (Phase 4).
        break;

      case PauseEvent():
        setState(() => _mode = _Idle());

      case GameEndedEvent():
        setState(() => _mode = _Idle());
        _showEndDialog();
    }
  }

  void _showEndDialog() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text('THE END', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onAdvance() => widget.executor.advance();

  void _onSelectChoice(int index) => widget.executor.selectChoice(index);

  @override
  Widget build(BuildContext context) {
    final mode = _mode;

    Widget? overlay;
    if (mode is _ShowingDialogue) {
      overlay = DialogueBox(
        character: mode.character,
        text: mode.text,
        onTap: _onAdvance,
      );
    } else if (mode is _ShowingMenu) {
      overlay = MenuWidget(
        choices: mode.choices,
        onSelect: _onSelectChoice,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: GameLayerWidget(
                  layerState: _layers,
                  imageCache: widget.imageCache,
                  overlay: overlay,
                ),
              ),
            ),
            if (Navigator.canPop(context))
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white54, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

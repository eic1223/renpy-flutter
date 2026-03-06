/// Game layer system — renders background + sprites as a stacked widget.
/// Layers (bottom → top): background, sprites, text/UI
library;

import 'package:flutter/material.dart';

import 'image_cache.dart';
import 'transitions.dart';

// ─── Layer model ──────────────────────────────────────────────────────────────

/// Represents the current display state passed down to [GameLayerWidget].
class LayerState {
  final String? background;
  final Map<String, SpriteInfo> sprites; // tag → info
  final TransitionType transition;

  const LayerState({
    this.background,
    this.sprites = const {},
    this.transition = TransitionType.dissolve,
  });

  LayerState copyWith({
    String? background,
    bool clearBackground = false,
    Map<String, SpriteInfo>? sprites,
    TransitionType? transition,
  }) {
    return LayerState(
      background: clearBackground ? null : (background ?? this.background),
      sprites: sprites ?? Map.of(this.sprites),
      transition: transition ?? this.transition,
    );
  }

  static const empty = LayerState();
}

class SpriteInfo {
  final String imageName;
  final Alignment alignment;
  final double? xpos;

  const SpriteInfo({
    required this.imageName,
    this.alignment = Alignment.bottomCenter,
    this.xpos,
  });
}

// ─── Widget ───────────────────────────────────────────────────────────────────

class GameLayerWidget extends StatelessWidget {
  final LayerState layerState;
  final ImageCache imageCache;
  final Widget? overlay; // dialogue / menu on top

  const GameLayerWidget({
    super.key,
    required this.layerState,
    required this.imageCache,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Background ──
        _BackgroundLayer(
          imageName: layerState.background,
          imageCache: imageCache,
          transition: layerState.transition,
        ),
        // ── Sprites ──
        for (final entry in layerState.sprites.entries)
          _SpriteLayer(
            key: ValueKey(entry.key),
            info: entry.value,
            imageCache: imageCache,
            transition: layerState.transition,
          ),
        // ── UI overlay ──
        if (overlay != null) overlay!,
      ],
    );
  }
}

// ─── Background ───────────────────────────────────────────────────────────────

class _BackgroundLayer extends StatelessWidget {
  final String? imageName;
  final ImageCache imageCache;
  final TransitionType transition;

  const _BackgroundLayer({
    required this.imageName,
    required this.imageCache,
    required this.transition,
  });

  @override
  Widget build(BuildContext context) {
    return LayerTransition(
      type: transition,
      child: imageName == null
          ? Container(key: const ValueKey('bg_empty'), color: Colors.black)
          : SizedBox.expand(
              key: ValueKey('bg_$imageName'),
              child: imageCache.buildImage(imageName!, fit: BoxFit.cover),
            ),
    );
  }
}

// ─── Sprite ───────────────────────────────────────────────────────────────────

class _SpriteLayer extends StatelessWidget {
  final SpriteInfo info;
  final ImageCache imageCache;
  final TransitionType transition;

  const _SpriteLayer({
    super.key,
    required this.info,
    required this.imageCache,
    required this.transition,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = imageCache.buildImage(info.imageName, fit: BoxFit.contain);

    Widget positioned;
    if (info.xpos != null) {
      positioned = Positioned(
        left: MediaQuery.sizeOf(context).width * info.xpos!,
        bottom: 0,
        child: image,
      );
    } else {
      positioned = Align(
        alignment: info.alignment,
        child: image,
      );
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: 1.0,
      child: positioned,
    );
  }
}

// ─── Entering / Leaving sprite animation ─────────────────────────────────────

class AnimatedSprite extends StatefulWidget {
  final Widget child;
  final bool visible;
  final Duration duration;

  const AnimatedSprite({
    super.key,
    required this.child,
    this.visible = true,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  State<AnimatedSprite> createState() => _AnimatedSpriteState();
}

class _AnimatedSpriteState extends State<AnimatedSprite> {
  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: widget.duration,
      opacity: widget.visible ? 1.0 : 0.0,
      child: widget.child,
    );
  }
}

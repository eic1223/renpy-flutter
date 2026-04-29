/// Transition definitions matching common Ren'Py built-in transitions.
library;

import 'package:flutter/material.dart';

enum TransitionType {
  dissolve,
  fade,
  pixellate,
  blinds,
  none,
}

TransitionType resolveTransition(String? name) {
  return switch (name) {
    'dissolve' => TransitionType.dissolve,
    'fade' => TransitionType.fade,
    'pixellate' => TransitionType.pixellate,
    'blinds' => TransitionType.blinds,
    _ => TransitionType.dissolve,
  };
}

/// Wraps an [AnimatedSwitcher] child with a matching transition effect.
class LayerTransition extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final TransitionType type;

  const LayerTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.type = TransitionType.dissolve,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (child, animation) => _buildTransition(child, animation),
      child: child,
    );
  }

  Widget _buildTransition(Widget child, Animation<double> animation) {
    return switch (type) {
      TransitionType.dissolve => FadeTransition(opacity: animation, child: child),
      TransitionType.fade => FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(animation),
          child: child,
        ),
      TransitionType.pixellate => _PixellateTransition(animation: animation, child: child),
      TransitionType.blinds => _BlindsTransition(animation: animation, child: child),
      TransitionType.none => child,
    };
  }
}

// ─── Pixellate ────────────────────────────────────────────────────────────────

class _PixellateTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _PixellateTransition({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    // Simulate pixellation via scale + fade
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final t = animation.value;
        return Transform.scale(
          scale: 0.95 + 0.05 * t,
          child: Opacity(opacity: t, child: child),
        );
      },
    );
  }
}

// ─── Blinds ───────────────────────────────────────────────────────────────────

class _BlindsTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  static const _slats = 8;

  const _BlindsTransition({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => ClipRect(
        child: CustomPaint(
          foregroundPainter: _BlindsPainter(animation.value),
          child: child,
        ),
      ),
    );
  }
}

class _BlindsPainter extends CustomPainter {
  final double progress;
  const _BlindsPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const slats = _BlindsTransition._slats;
    final slatHeight = size.height / slats;
    final paint = Paint()..color = Colors.black.withOpacity(1 - progress);
    for (var i = 0; i < slats; i++) {
      final top = i * slatHeight;
      final coverHeight = slatHeight * (1 - progress);
      canvas.drawRect(Rect.fromLTWH(0, top, size.width, coverHeight), paint);
    }
  }

  @override
  bool shouldRepaint(_BlindsPainter old) => old.progress != progress;
}

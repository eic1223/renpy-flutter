/// Dialogue box widget — displays character name + typewriter text.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../models/character.dart';

class DialogueBox extends StatefulWidget {
  final Character character;
  final String text;
  final VoidCallback onTap;
  final Duration charInterval;

  const DialogueBox({
    super.key,
    required this.character,
    required this.text,
    required this.onTap,
    this.charInterval = const Duration(milliseconds: 30),
  });

  @override
  State<DialogueBox> createState() => _DialogueBoxState();
}

class _DialogueBoxState extends State<DialogueBox> {
  String _displayed = '';
  bool _done = false;
  Timer? _timer;
  int _charIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTypewriter();
  }

  @override
  void didUpdateWidget(DialogueBox old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _timer?.cancel();
      _displayed = '';
      _charIndex = 0;
      _done = false;
      _startTypewriter();
    }
  }

  void _startTypewriter() {
    _timer = Timer.periodic(widget.charInterval, (_) {
      if (_charIndex >= widget.text.length) {
        _timer?.cancel();
        setState(() => _done = true);
        return;
      }
      setState(() {
        _displayed += widget.text[_charIndex];
        _charIndex++;
      });
    });
  }

  void _handleTap() {
    if (!_done) {
      // Skip to end
      _timer?.cancel();
      setState(() {
        _displayed = widget.text;
        _done = true;
      });
    } else {
      widget.onTap();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNarrator = widget.character.id.isEmpty;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isNarrator) ...[
                _CharacterNameTag(
                  name: widget.character.name,
                  color: widget.character.color,
                ),
                const SizedBox(height: 8),
              ],
              _DialogueText(text: _displayed),
              if (_done) const _AdvanceIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _CharacterNameTag extends StatelessWidget {
  final String name;
  final Color color;
  const _CharacterNameTag({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      style: TextStyle(
        color: color,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
      ),
    );
  }
}

class _DialogueText extends StatelessWidget {
  final String text;
  const _DialogueText({required this.text});

  @override
  Widget build(BuildContext context) {
    return _parseRichText(text);
  }

  Widget _parseRichText(String raw) {
    // Basic tag support: {b}, {i}, {color=#rrggbb}
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'\{([^}]+)\}([^{]*)\{/[^}]+\}|([^{]+)');
    final matches = pattern.allMatches(raw);

    if (matches.isEmpty) {
      return Text(raw, style: _baseStyle);
    }

    for (final m in matches) {
      if (m.group(3) != null) {
        // plain text
        spans.add(TextSpan(text: m.group(3)));
      } else {
        final tag = m.group(1)!;
        final content = m.group(2) ?? '';
        TextStyle style = const TextStyle();
        if (tag == 'b') {
          style = const TextStyle(fontWeight: FontWeight.bold);
        } else if (tag == 'i') {
          style = const TextStyle(fontStyle: FontStyle.italic);
        } else if (tag.startsWith('color=')) {
          final hexStr = tag.substring(6).replaceFirst('#', '');
          final colorVal = int.tryParse('FF$hexStr', radix: 16);
          if (colorVal != null) {
            style = TextStyle(color: Color(colorVal));
          }
        }
        spans.add(TextSpan(text: content, style: style));
      }
    }

    return RichText(
      text: TextSpan(style: _baseStyle, children: spans),
    );
  }

  static const _baseStyle = TextStyle(
    color: Colors.white,
    fontSize: 16,
    height: 1.5,
    shadows: [Shadow(color: Colors.black, blurRadius: 2)],
  );
}

class _AdvanceIndicator extends StatefulWidget {
  const _AdvanceIndicator();

  @override
  State<_AdvanceIndicator> createState() => _AdvanceIndicatorState();
}

class _AdvanceIndicatorState extends State<_AdvanceIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: FadeTransition(
        opacity: _anim,
        child: const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 20),
        ),
      ),
    );
  }
}

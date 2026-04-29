/// GameExecutor: walks AST nodes and emits GameEvents.
/// This is the core engine — it does NOT know about Flutter widgets.
library;

import 'dart:async';

import '../ast/nodes.dart';
import '../models/game_state.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

sealed class GameEvent {}

class ShowDialogueEvent extends GameEvent {
  final String? characterId;
  final String text;
  ShowDialogueEvent(this.characterId, this.text);
}

class ShowMenuEvent extends GameEvent {
  final List<MenuChoice> choices;
  ShowMenuEvent(this.choices);
}

class ShowImageEvent extends GameEvent {
  final String imageName;
  final String? at;
  final String? with_;
  ShowImageEvent(this.imageName, {this.at, this.with_});
}

class ShowSceneEvent extends GameEvent {
  final String? imageName;
  final String? with_;
  ShowSceneEvent(this.imageName, {this.with_});
}

class HideImageEvent extends GameEvent {
  final String imageName;
  final String? with_;
  HideImageEvent(this.imageName, {this.with_});
}

class PlayAudioEvent extends GameEvent {
  final String channel;
  final String filename;
  final bool loop;
  final double? fadeIn;
  PlayAudioEvent(this.channel, this.filename, {this.loop = false, this.fadeIn});
}

class StopAudioEvent extends GameEvent {
  final String channel;
  final double? fadeOut;
  StopAudioEvent(this.channel, {this.fadeOut});
}

class PauseEvent extends GameEvent {
  final double? duration;
  PauseEvent(this.duration);
}

class GameEndedEvent extends GameEvent {}

// ─── Executor ─────────────────────────────────────────────────────────────────

class GameExecutor {
  /// Flat map of all labels in the script.
  final Map<String, LabelNode> labels;

  GameState _state;
  GameState get state => _state;

  final _eventController = StreamController<GameEvent>.broadcast();
  Stream<GameEvent> get events => _eventController.stream;

  // Waiting for player input (tap / menu choice)
  bool _waitingForInput = false;
  bool get waitingForInput => _waitingForInput;

  Completer<void>? _inputCompleter;
  Completer<int>? _menuCompleter;

  GameExecutor({required this.labels, required GameState initialState})
      : _state = initialState;

  // ─── Public control ────────────────────────────────────────────────────────

  /// Start running from the current state.
  Future<void> run() async {
    await _executeLabel(_state.label, _state.index);
  }

  /// Player tapped to advance (dismiss dialogue / resume pause).
  void advance() {
    _inputCompleter?.complete();
    _inputCompleter = null;
    _waitingForInput = false;
  }

  /// Player selected a menu choice.
  void selectChoice(int index) {
    _menuCompleter?.complete(index);
    _menuCompleter = null;
    _waitingForInput = false;
  }

  void dispose() {
    _eventController.close();
  }

  // ─── Execution ─────────────────────────────────────────────────────────────

  Future<void> _executeLabel(String labelName, [int startIndex = 0]) async {
    final label = labels[labelName];
    if (label == null) return; // label not found — silently stop

    final block = label.block;
    for (var i = startIndex; i < block.length; i++) {
      _state = _state.copyWith(label: labelName, index: i);
      final done = await _executeNode(block[i]);
      if (done) return; // jump/call/return handled execution redirect
    }
    // Fell off end of label — check call stack
    if (_state.callStack.isNotEmpty) {
      final frame = _state.callStack.last;
      final newStack = List.of(_state.callStack)..removeLast();
      _state = _state.copyWith(callStack: newStack);
      await _executeLabel(frame.$1, frame.$2 + 1);
    } else {
      _emit(GameEndedEvent());
    }
  }

  /// Returns true if execution should stop (jump/call/return handled).
  Future<bool> _executeNode(AstNode node) async {
    switch (node) {
      case SayNode():
        _emit(ShowDialogueEvent(node.who, node.what));
        await _waitInput();
        return false;

      case ShowNode():
        // Extract sprite tag (first word of imageName)
        final tag = node.imageName.split(' ').first;
        final sprites = Map.of(_state.sprites)..[tag] = node.imageName;
        _state = _state.copyWith(sprites: sprites);
        _emit(ShowImageEvent(node.imageName, at: node.at, with_: node.with_));
        return false;

      case SceneNode():
        final sprites = <String, String>{};
        if (node.imageName != null) {
          sprites['bg'] = node.imageName!;
        }
        _state = _state.copyWith(
          sprites: sprites,
          background: node.imageName,
          clearBackground: node.imageName == null,
        );
        _emit(ShowSceneEvent(node.imageName, with_: node.with_));
        return false;

      case HideNode():
        final tag = node.imageName.split(' ').first;
        final sprites = Map.of(_state.sprites)..remove(tag);
        _state = _state.copyWith(sprites: sprites);
        _emit(HideImageEvent(node.imageName, with_: node.with_));
        return false;

      case JumpNode():
        await _executeLabel(node.target);
        return true;

      case CallNode():
        final returnFrame = (_state.label, _state.index);
        final newStack = List.of(_state.callStack)..add(returnFrame);
        _state = _state.copyWith(callStack: newStack);
        await _executeLabel(node.target);
        return true;

      case ReturnNode():
        if (_state.callStack.isNotEmpty) {
          final frame = _state.callStack.last;
          final newStack = List.of(_state.callStack)..removeLast();
          _state = _state.copyWith(callStack: newStack);
          await _executeLabel(frame.$1, frame.$2 + 1);
        }
        return true;

      case MenuNode():
        _emit(ShowMenuEvent(node.choices));
        final chosen = await _waitMenu();
        final choice = node.choices[chosen];
        for (final n in choice.block) {
          final done = await _executeNode(n);
          if (done) return true;
        }
        return false;

      case PythonNode():
        _executePython(node.code);
        return false;

      case IfNode():
        for (final branch in node.branches) {
          if (branch.condition == null || _evalCondition(branch.condition!)) {
            for (final n in branch.block) {
              final done = await _executeNode(n);
              if (done) return true;
            }
            break;
          }
        }
        return false;

      case PlayNode():
        _emit(PlayAudioEvent(node.channel, node.filename,
            loop: node.loop, fadeIn: node.fadeIn));
        return false;

      case StopNode():
        _emit(StopAudioEvent(node.channel, fadeOut: node.fadeOut));
        return false;

      case PauseNode():
        _emit(PauseEvent(node.duration));
        if (node.duration != null) {
          await Future.delayed(Duration(milliseconds: (node.duration! * 1000).toInt()));
        } else {
          await _waitInput();
        }
        return false;

      case WithNode():
        // standalone with — handled visually by the display layer
        return false;

      default:
        return false;
    }
  }

  // ─── Input waiting ─────────────────────────────────────────────────────────

  Future<void> _waitInput() async {
    _waitingForInput = true;
    _inputCompleter = Completer<void>();
    await _inputCompleter!.future;
  }

  Future<int> _waitMenu() async {
    _waitingForInput = true;
    _menuCompleter = Completer<int>();
    return _menuCompleter!.future;
  }

  // ─── Python mini-interpreter ───────────────────────────────────────────────

  void _executePython(String code) {
    // Supports: var = expression, var += expr, var -= expr, var *= expr
    final assignMatch =
        RegExp(r'^(\w+)\s*([+\-*]?=)\s*(.+)$').firstMatch(code.trim());
    if (assignMatch == null) return;

    final varName = assignMatch.group(1)!;
    final op = assignMatch.group(2)!;
    final expr = assignMatch.group(3)!.trim();
    final value = _evalExpr(expr);

    final vars = Map<String, dynamic>.of(_state.variables);
    if (op == '=') {
      vars[varName] = value;
    } else {
      final current = vars[varName] ?? 0;
      vars[varName] = switch (op) {
        '+=' => _add(current, value),
        '-=' => _sub(current, value),
        '*=' => _mul(current, value),
        _ => value,
      };
    }
    _state = _state.copyWith(variables: vars);
  }

  dynamic _add(dynamic a, dynamic b) {
    if (a is num && b is num) return a + b;
    return '$a$b';
  }

  dynamic _sub(dynamic a, dynamic b) {
    if (a is num && b is num) return a - b;
    return a;
  }

  dynamic _mul(dynamic a, dynamic b) {
    if (a is num && b is num) return a * b;
    return a;
  }

  dynamic _evalExpr(String expr) {
    // literal int
    final intVal = int.tryParse(expr);
    if (intVal != null) return intVal;
    // literal float
    final floatVal = double.tryParse(expr);
    if (floatVal != null) return floatVal;
    // string literal
    if ((expr.startsWith('"') && expr.endsWith('"')) ||
        (expr.startsWith("'") && expr.endsWith("'"))) {
      return expr.substring(1, expr.length - 1);
    }
    // True / False
    if (expr == 'True') return true;
    if (expr == 'False') return false;
    // variable lookup
    if (RegExp(r'^\w+$').hasMatch(expr)) {
      return _state.variables[expr];
    }
    // simple arithmetic: a + b, a - b, a * b, a / b
    final arithMatch = RegExp(r'^(.+?)\s*([+\-*/])\s*(.+)$').firstMatch(expr);
    if (arithMatch != null) {
      final left = _evalExpr(arithMatch.group(1)!.trim());
      final right = _evalExpr(arithMatch.group(3)!.trim());
      final op = arithMatch.group(2)!;
      if (left is num && right is num) {
        return switch (op) {
          '+' => left + right,
          '-' => left - right,
          '*' => left * right,
          '/' => left / right,
          _ => left,
        };
      }
    }
    return null;
  }

  bool _evalCondition(String condition) {
    final trimmed = condition.trim();
    // Compound: and / or
    if (trimmed.contains(' and ')) {
      return trimmed.split(' and ').every(_evalCondition);
    }
    if (trimmed.contains(' or ')) {
      return trimmed.split(' or ').any(_evalCondition);
    }
    if (trimmed.startsWith('not ')) {
      return !_evalCondition(trimmed.substring(4));
    }
    // Comparison
    final cmpMatch = RegExp(r'^(.+?)\s*(==|!=|>=|<=|>|<)\s*(.+)$').firstMatch(trimmed);
    if (cmpMatch != null) {
      final left = _evalExpr(cmpMatch.group(1)!.trim());
      final right = _evalExpr(cmpMatch.group(3)!.trim());
      final op = cmpMatch.group(2)!;
      return switch (op) {
        '==' => left == right,
        '!=' => left != right,
        '>=' => (left as num) >= (right as num),
        '<=' => (left as num) <= (right as num),
        '>' => (left as num) > (right as num),
        '<' => (left as num) < (right as num),
        _ => false,
      };
    }
    // Truthy
    final val = _evalExpr(trimmed);
    return val == true || (val is num && val != 0) || (val is String && val.isNotEmpty);
  }

  void _emit(GameEvent event) => _eventController.add(event);
}

// ─── Script loader helper ─────────────────────────────────────────────────────

Map<String, LabelNode> buildLabelMap(List<AstNode> nodes) {
  final map = <String, LabelNode>{};
  for (final node in nodes) {
    if (node is LabelNode) {
      map[node.name] = node;
    }
  }
  return map;
}

import 'character.dart';

/// Snapshot of game state — used for save/load and rollback.
class GameState {
  /// Current label name.
  final String label;

  /// Index within the label's block.
  final int index;

  /// Call stack for `call`/`return`.
  final List<(String, int)> callStack;

  /// Game variables ($ assignments).
  final Map<String, dynamic> variables;

  /// Current background image name.
  final String? background;

  /// Shown sprites: tag → image name.
  final Map<String, String> sprites;

  const GameState({
    required this.label,
    required this.index,
    required this.callStack,
    required this.variables,
    this.background,
    required this.sprites,
  });

  GameState copyWith({
    String? label,
    int? index,
    List<(String, int)>? callStack,
    Map<String, dynamic>? variables,
    String? background,
    bool clearBackground = false,
    Map<String, String>? sprites,
  }) {
    return GameState(
      label: label ?? this.label,
      index: index ?? this.index,
      callStack: callStack ?? List.of(this.callStack),
      variables: variables ?? Map.of(this.variables),
      background: clearBackground ? null : (background ?? this.background),
      sprites: sprites ?? Map.of(this.sprites),
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'index': index,
    'callStack': callStack.map((e) => [e.$1, e.$2]).toList(),
    'variables': variables,
    'background': background,
    'sprites': sprites,
  };

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      label: json['label'] as String,
      index: json['index'] as int,
      callStack: (json['callStack'] as List)
          .map((e) => ((e[0] as String), (e[1] as int)))
          .toList(),
      variables: Map<String, dynamic>.from(json['variables'] as Map),
      background: json['background'] as String?,
      sprites: Map<String, String>.from(json['sprites'] as Map),
    );
  }

  static GameState initial(String startLabel) => GameState(
    label: startLabel,
    index: 0,
    callStack: [],
    variables: {},
    sprites: {},
  );
}

/// Encapsulates all character definitions in the game.
class CharacterRegistry {
  final Map<String, Character> _chars = {};

  void register(Character c) => _chars[c.id] = c;

  Character? operator [](String id) => _chars[id];

  Character resolve(String? id) =>
      id == null || id.isEmpty ? Character.narrator : (_chars[id] ?? Character(id: id, name: id));
}

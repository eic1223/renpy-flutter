/// ScriptManager: loads .rpy files from assets and builds label maps.
library;

import 'package:flutter/services.dart';

import '../ast/nodes.dart';
import '../parser/parser.dart';
import 'game_executor.dart';

class ScriptManager {
  final Map<String, LabelNode> _labels = {};

  /// Load all scripts from a list of asset paths.
  Future<void> loadAssets(List<String> assetPaths) async {
    for (final path in assetPaths) {
      final source = await rootBundle.loadString(path);
      _loadSource(source);
    }
  }

  /// Load a script from a raw string (useful for testing).
  void loadSource(String source) => _loadSource(source);

  void _loadSource(String source) {
    final parser = RenpyParser.fromSource(source);
    final nodes = parser.parseAll();
    _labels.addAll(buildLabelMap(nodes));
  }

  Map<String, LabelNode> get labels => Map.unmodifiable(_labels);

  bool hasLabel(String name) => _labels.containsKey(name);
}

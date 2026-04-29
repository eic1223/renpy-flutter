import 'package:flutter_test/flutter_test.dart';
import 'package:renpy_flutter/src/executor/game_executor.dart';
import 'package:renpy_flutter/src/executor/script_manager.dart';
import 'package:renpy_flutter/src/models/game_state.dart';

void main() {
  group('GameExecutor', () {
    Future<List<GameEvent>> runScript(String source) async {
      final manager = ScriptManager()..loadSource(source);
      final executor = GameExecutor(
        labels: manager.labels,
        initialState: GameState.initial('start'),
      );

      final events = <GameEvent>[];
      executor.events.listen(events.add);

      // Run and auto-advance all dialogue/pauses.
      executor.run().ignore();

      await Future.delayed(const Duration(milliseconds: 50));

      // Auto-advance any waiting input.
      while (executor.waitingForInput) {
        executor.advance();
        await Future.delayed(const Duration(milliseconds: 10));
      }

      executor.dispose();
      return events;
    }

    test('emits ShowDialogueEvent for say nodes', () async {
      const src = '''
label start:
    "안녕하세요."
    e "반가워요!"
''';
      final events = await runScript(src);
      final dialogues = events.whereType<ShowDialogueEvent>().toList();
      expect(dialogues, hasLength(2));
      expect(dialogues[0].characterId, isNull);
      expect(dialogues[0].text, '안녕하세요.');
      expect(dialogues[1].characterId, 'e');
    });

    test('emits ShowSceneEvent and ShowImageEvent', () async {
      const src = '''
label start:
    scene bg_room with dissolve
    show eileen happy
''';
      final events = await runScript(src);
      expect(events.whereType<ShowSceneEvent>(), isNotEmpty);
      expect(events.whereType<ShowImageEvent>(), isNotEmpty);
    });

    test('evaluates python variables', () async {
      const src = '''
label start:
    \$ coins = 5
    \$ coins += 3
    "끝"
''';
      final manager = ScriptManager()..loadSource(src);
      final executor = GameExecutor(
        labels: manager.labels,
        initialState: GameState.initial('start'),
      );
      executor.run().ignore();
      await Future.delayed(const Duration(milliseconds: 50));
      // After $ coins = 5 and $ coins += 3, state.variables['coins'] == 8
      expect(executor.state.variables['coins'], 8);
      executor.dispose();
    });

    test('jump navigates to target label', () async {
      const src = '''
label start:
    jump other

label other:
    "도착했습니다."
''';
      final events = await runScript(src);
      final dialogues = events.whereType<ShowDialogueEvent>().toList();
      expect(dialogues, hasLength(1));
      expect(dialogues[0].text, '도착했습니다.');
    });

    test('emits GameEndedEvent at end of script', () async {
      const src = '''
label start:
    "끝."
''';
      final events = await runScript(src);
      expect(events.whereType<GameEndedEvent>(), isNotEmpty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:renpy_flutter/src/ast/nodes.dart';
import 'package:renpy_flutter/src/parser/parser.dart';

void main() {
  group('Lexer + Parser', () {
    test('parses label with say nodes', () {
      const src = '''
label start:
    "안녕하세요."
    e "반가워요!"
''';
      final parser = RenpyParser.fromSource(src);
      final nodes = parser.parseAll();
      expect(nodes, hasLength(1));

      final label = nodes.first as LabelNode;
      expect(label.name, 'start');
      expect(label.block, hasLength(2));

      final narration = label.block[0] as SayNode;
      expect(narration.who, isNull);
      expect(narration.what, '안녕하세요.');

      final say = label.block[1] as SayNode;
      expect(say.who, 'e');
      expect(say.what, '반가워요!');
    });

    test('parses scene and show', () {
      const src = '''
label start:
    scene bg_room with dissolve
    show eileen happy at left with dissolve
    hide eileen
''';
      final parser = RenpyParser.fromSource(src);
      final nodes = parser.parseAll();
      final block = (nodes.first as LabelNode).block;

      final scene = block[0] as SceneNode;
      expect(scene.imageName, 'bg_room');
      expect(scene.with_, 'dissolve');

      final show = block[1] as ShowNode;
      expect(show.imageName, 'eileen happy');
      expect(show.at, 'left');
      expect(show.with_, 'dissolve');

      final hide = block[2] as HideNode;
      expect(hide.imageName, 'eileen');
    });

    test('parses jump and call', () {
      const src = '''
label start:
    jump route_a
    call intro
    return
''';
      final nodes = RenpyParser.fromSource(src).parseAll();
      final block = (nodes.first as LabelNode).block;

      expect((block[0] as JumpNode).target, 'route_a');
      expect((block[1] as CallNode).target, 'intro');
      expect(block[2], isA<ReturnNode>());
    });

    test('parses menu with choices', () {
      const src = '''
label start:
    menu:
        "선택지 A":
            jump route_a
        "선택지 B":
            jump route_b
''';
      final nodes = RenpyParser.fromSource(src).parseAll();
      final block = (nodes.first as LabelNode).block;
      final menu = block[0] as MenuNode;

      expect(menu.choices, hasLength(2));
      expect(menu.choices[0].label, '선택지 A');
      expect(menu.choices[1].label, '선택지 B');

      final jump0 = menu.choices[0].block[0] as JumpNode;
      expect(jump0.target, 'route_a');
    });

    test('parses python assignment', () {
      const src = '''
label start:
    \$ score = 0
    \$ score += 10
''';
      final nodes = RenpyParser.fromSource(src).parseAll();
      final block = (nodes.first as LabelNode).block;

      expect((block[0] as PythonNode).code, 'score = 0');
      expect((block[1] as PythonNode).code, 'score += 10');
    });

    test('parses if/elif/else', () {
      const src = '''
label start:
    if score >= 10:
        e "잘 했어요!"
    elif score >= 5:
        e "그럭저럭이에요."
    else:
        e "아쉽네요."
''';
      final nodes = RenpyParser.fromSource(src).parseAll();
      final block = (nodes.first as LabelNode).block;
      final ifNode = block[0] as IfNode;

      expect(ifNode.branches, hasLength(3));
      expect(ifNode.branches[0].condition, 'score >= 10');
      expect(ifNode.branches[1].condition, 'score >= 5');
      expect(ifNode.branches[2].condition, isNull); // else
    });

    test('parses play and stop', () {
      const src = '''
label start:
    play music bg.ogg loop fadein 1.0
    stop music fadeout 0.5
''';
      final nodes = RenpyParser.fromSource(src).parseAll();
      final block = (nodes.first as LabelNode).block;

      final play = block[0] as PlayNode;
      expect(play.channel, 'music');
      expect(play.filename, 'bg.ogg');
      expect(play.loop, isTrue);
      expect(play.fadeIn, 1.0);

      final stop = block[1] as StopNode;
      expect(stop.channel, 'music');
      expect(stop.fadeOut, 0.5);
    });
  });
}

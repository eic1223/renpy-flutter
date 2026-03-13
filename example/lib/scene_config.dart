import 'package:flutter/material.dart';
import 'package:renpy_flutter/renpy_flutter.dart';

class SceneConfig {
  final String title;
  final String description;
  final String startLabel;
  final List<String> scripts;
  final List<Character> characters;
  final Color accentColor;

  const SceneConfig({
    required this.title,
    required this.description,
    required this.startLabel,
    required this.scripts,
    required this.characters,
    required this.accentColor,
  });
}

const kScenes = [
  SceneConfig(
    title: '교실의 유나',
    description: '방과 후 교실에서 만난 유나와의 짧은 대화.',
    startLabel: 'classroom',
    scripts: ['assets/scripts/scene_classroom.rpy'],
    characters: [
      Character(id: 'yuna', name: '유나', color: Color(0xFFFFB7C5)),
    ],
    accentColor: Color(0xFFFFB7C5),
  ),
  SceneConfig(
    title: '카페의 민호',
    description: '단골 카페에서 우연히 마주친 민호와의 이야기.',
    startLabel: 'cafe',
    scripts: ['assets/scripts/scene_cafe.rpy'],
    characters: [
      Character(id: 'minho', name: '민호', color: Color(0xFF90CAF9)),
    ],
    accentColor: Color(0xFF90CAF9),
  ),
  SceneConfig(
    title: '공원의 소라',
    description: '저녁 산책 중 벤치에 앉아 있던 소라를 만나다.',
    startLabel: 'park',
    scripts: ['assets/scripts/scene_park.rpy'],
    characters: [
      Character(id: 'sora', name: '소라', color: Color(0xFFA5D6A7)),
    ],
    accentColor: Color(0xFFA5D6A7),
  ),
];

import 'package:flutter/material.dart';

/// Represents a Ren'Py `define` character.
class Character {
  final String id;       // variable name, e.g. 'e'
  final String name;     // display name, e.g. 'Eileen'
  final Color color;     // name color in dialogue box
  final String? image;   // default image tag

  const Character({
    required this.id,
    required this.name,
    this.color = Colors.white,
    this.image,
  });

  static const narrator = Character(id: '', name: '');
}

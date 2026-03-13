/// Simple asset image resolver.
/// Maps Ren'Py image names like "bg room" or "eileen happy"
/// to Flutter asset paths.
library;

import 'package:flutter/material.dart';

class ImageCache {
  /// Base path for image assets.
  final String basePath;

  /// Optional explicit mapping: image name → asset path.
  final Map<String, String> _registry = {};

  ImageCache({this.basePath = 'assets/images'});

  /// Register an image name → asset file mapping.
  void register(String imageName, String assetPath) {
    _registry[imageName.toLowerCase()] = assetPath;
  }

  /// Resolve image name to an asset path.
  /// Priority: explicit registry → auto-resolve by convention.
  String? resolve(String imageName) {
    final key = imageName.toLowerCase();
    if (_registry.containsKey(key)) return _registry[key];

    // Convention: "eileen happy" → "assets/images/eileen_happy.png"
    final filename = key.replaceAll(' ', '_');
    return '$basePath/$filename.png';
  }

  /// Build an [ImageProvider] for the given image name, or null if not found.
  ImageProvider? provider(String imageName) {
    final path = resolve(imageName);
    if (path == null) return null;
    return AssetImage(path);
  }

  Widget buildImage(String imageName, {BoxFit fit = BoxFit.contain}) {
    final path = resolve(imageName);
    if (path == null) return const SizedBox.shrink();
    return Image.asset(
      path,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}

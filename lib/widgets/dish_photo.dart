import 'package:flutter/material.dart';

import '../models.dart';
import '../services/photo_service.dart';

/// Big dish photo from Wikipedia, or a styled card when none is found.
class DishPhoto extends StatelessWidget {
  const DishPhoto({super.key, required this.recipe, this.height});

  final Recipe recipe;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: FutureBuilder<String?>(
        future: PhotoService.instance.photoFor(recipe),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return DishFallback(recipe: recipe, loading: true);
          }
          final url = snap.data;
          if (url == null) return DishFallback(recipe: recipe);
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : DishFallback(recipe: recipe, loading: true),
                errorBuilder: (context, error, stack) => DishFallback(recipe: recipe),
              ),
              const Positioned(right: 8, bottom: 8, child: _Credit()),
            ],
          );
        },
      ),
    );
  }
}

class _Credit extends StatelessWidget {
  const _Credit();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(120),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Photo: Wikipedia',
        style: TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }
}

/// Shown while loading and whenever there is no photo for a dish.
class DishFallback extends StatelessWidget {
  const DishFallback({super.key, required this.recipe, this.loading = false});

  final Recipe recipe;
  final bool loading;

  static const _palettes = <List<Color>>[
    [Color(0xFFE8590C), Color(0xFFFFA94D)],
    [Color(0xFFC92A2A), Color(0xFFFF8787)],
    [Color(0xFF2B8A3E), Color(0xFF8CE99A)],
    [Color(0xFF9C36B5), Color(0xFFE599F7)],
    [Color(0xFF1864AB), Color(0xFF74C0FC)],
    [Color(0xFFB08900), Color(0xFFFFD43B)],
  ];

  @override
  Widget build(BuildContext context) {
    final seed = recipe.id.codeUnits.fold<int>(0, (a, b) => a + b);
    final colors = _palettes[seed % _palettes.length];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(recipe.emoji, style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    recipe.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (loading)
            const Positioned(
              right: 12,
              bottom: 12,
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

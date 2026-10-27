import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../screens/recipe_screen.dart';
import '../services/matcher.dart';
import 'dish_photo.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({super.key, required this.recipe, this.match});

  final Recipe recipe;
  final RecipeMatch? match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = match;
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => RecipeScreen(recipe: recipe)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                DishPhoto(recipe: recipe, height: 210),
                if (m != null) Positioned(top: 12, left: 12, child: _MatchBadge(match: m)),
                Positioned(top: 6, right: 6, child: FavButton(recipe: recipe)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      VegMark(veg: recipe.veg),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          recipe.name,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      _Info(icon: Icons.schedule, text: '${recipe.minutes} min'),
                      _Info(icon: Icons.bar_chart, text: recipe.level),
                      _Info(icon: Icons.people_outline, text: 'Serves ${recipe.serves}'),
                    ],
                  ),
                  if (m != null && !m.isReady) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Missing: ${_missingText(m)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _missingText(RecipeMatch m) {
    final names = m.missing.map((i) => i.name).toList();
    final shown = names.take(3).join(', ');
    return names.length > 3 ? '$shown +${names.length - 3} more' : shown;
  }
}

class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.match});

  final RecipeMatch match;

  @override
  Widget build(BuildContext context) {
    final ready = match.isReady;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ready ? const Color(0xFF2B8A3E) : const Color(0xFF343A40),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        ready ? 'Ready to cook' : 'You have ${match.haveCount}/${match.totalCount}',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }
}

/// Indian-style veg / non-veg marker.
class VegMark extends StatelessWidget {
  const VegMark({super.key, required this.veg});

  final bool veg;

  @override
  Widget build(BuildContext context) {
    final color = veg ? const Color(0xFF2B8A3E) : const Color(0xFFC92A2A);
    return Container(
      width: 18,
      height: 18,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(3),
      ),
      child: DecoratedBox(decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    );
  }
}

class FavButton extends StatelessWidget {
  const FavButton({super.key, required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final fav = state.isFavorite(recipe);
    return Container(
      decoration: BoxDecoration(color: Colors.white.withAlpha(225), shape: BoxShape.circle),
      child: IconButton(
        tooltip: fav ? 'Remove from saved' : 'Save recipe',
        onPressed: () => state.toggleFavorite(recipe),
        icon: Icon(
          fav ? Icons.favorite : Icons.favorite_border,
          color: const Color(0xFFC92A2A),
        ),
      ),
    );
  }
}

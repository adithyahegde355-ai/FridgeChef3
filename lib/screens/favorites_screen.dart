import 'package:flutter/material.dart';

import '../app_state.dart';
import '../widgets/recipe_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final saved = state.favoriteRecipes;
    final matchById = {for (final m in state.matches) m.recipe.id: m};

    return SafeArea(
      child: saved.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No saved recipes yet. Tap the heart on any recipe to keep it here.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Saved recipes',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                for (final r in saved) RecipeCard(recipe: r, match: matchById[r.id]),
              ],
            ),
    );
  }
}

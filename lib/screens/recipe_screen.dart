import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../util.dart';
import '../widgets/dish_photo.dart';
import '../widgets/recipe_card.dart';
import 'cook_screen.dart';

class RecipeScreen extends StatelessWidget {
  const RecipeScreen({super.key, required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final needed = recipe.ingredients.where((i) => !i.optional).toList();
    final missing = needed.where((i) => !state.has(i)).length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            leading: Padding(
              padding: const EdgeInsets.all(6),
              child: Container(
                decoration:
                    BoxDecoration(color: Colors.white.withAlpha(225), shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(6),
                child: FavButton(recipe: recipe),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(background: DishPhoto(recipe: recipe)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      VegMark(veg: recipe.veg),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          recipe.name,
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(avatar: const Icon(Icons.schedule, size: 18), label: Text('${recipe.minutes} min')),
                      Chip(avatar: const Icon(Icons.bar_chart, size: 18), label: Text(recipe.level)),
                      Chip(avatar: const Icon(Icons.people_outline, size: 18), label: Text('Serves ${recipe.serves}')),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Ingredients',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.ingredients.isEmpty
                        ? 'Add ingredients on the home screen to see what you have.'
                        : missing == 0
                            ? 'You have everything you need.'
                            : 'You are missing $missing item${missing == 1 ? '' : 's'}.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: missing == 0 && state.ingredients.isNotEmpty
                          ? const Color(0xFF2B8A3E)
                          : theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final i in recipe.ingredients) _IngredientRow(ingredient: i),
                  const SizedBox(height: 20),
                  Text(
                    'Method',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  for (var n = 0; n < recipe.steps.length; n++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text('${n + 1}', style: const TextStyle(fontSize: 13)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(recipe.steps[n].text)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => CookScreen(recipe: recipe)),
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start cooking'),
            ),
          ),
        ),
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.ingredient});

  final Ingredient ingredient;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final have = state.has(ingredient);

    final IconData icon;
    final Color color;
    String? tag;
    if (have) {
      icon = Icons.check_circle;
      color = const Color(0xFF2B8A3E);
      if (ingredient.staple && !state.ingredients.contains(ingredient.name)) tag = 'Pantry';
    } else if (ingredient.optional) {
      icon = Icons.circle_outlined;
      color = theme.colorScheme.outline;
      tag = 'Optional';
    } else {
      icon = Icons.error_outline;
      color = theme.colorScheme.error;
      tag = 'Missing';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: titleCase(ingredient.name),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: '  ${ingredient.qty}',
                    style: TextStyle(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
          ),
          if (tag != null) Text(tag, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

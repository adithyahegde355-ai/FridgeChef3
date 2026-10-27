import 'package:flutter/material.dart';

import '../app_state.dart';
import '../services/matcher.dart';
import '../widgets/recipe_card.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final matches = state.matches;

    final items = <Object>[];
    void section(String title, List<RecipeMatch> list) {
      if (list.isEmpty) return;
      items.add('$title (${list.length})');
      items.addAll(list);
    }

    section('Ready to cook', matches.where((m) => m.missingCount == 0).toList());
    section('Missing 1 or 2 items',
        matches.where((m) => m.missingCount >= 1 && m.missingCount <= 2).toList());
    section('More ideas', matches.where((m) => m.missingCount >= 3).toList());

    return Scaffold(
      appBar: AppBar(title: const Text('Recipes for you')),
      body: items.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No recipes match yet. Go back and add a few more ingredients.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                if (item is String) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 12),
                    child: Text(
                      item,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  );
                }
                final m = item as RecipeMatch;
                return RecipeCard(recipe: m.recipe, match: m);
              },
            ),
    );
  }
}

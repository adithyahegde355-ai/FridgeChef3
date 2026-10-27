import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_chef/models.dart';
import 'package:fridge_chef/services/matcher.dart';

void main() {
  final recipes = RecipeRepository.parse(File('assets/recipes.json').readAsStringSync());
  final catalog = IngredientCatalog(recipes);

  test('dataset is sane', () {
    expect(recipes.map((r) => r.id).toSet().length, recipes.length);
    for (final r in recipes) {
      expect(r.steps, isNotEmpty, reason: r.id);
      expect(r.ingredients.where((i) => !i.staple && !i.optional), isNotEmpty, reason: r.id);
    }
  });

  test('typed names map to canonical ingredients', () {
    expect(catalog.canon('Aloo'), 'potato');
    expect(catalog.canon('Tomatoes'), 'tomato');
    expect(catalog.canon('  Green   Chillies '), 'green chili');
    expect(catalog.canon('Eggs'), 'egg');
    expect(catalog.canon('paneer'), 'paneer');
    expect(catalog.canon('Dhania'), 'coriander leaves');
  });

  test('suggestions skip chosen items and match aliases', () {
    expect(catalog.suggestions('alo'), contains('potato'));
    expect(catalog.suggestions('pot', exclude: {'potato'}), isNot(contains('potato')));
    expect(catalog.suggestions(''), isEmpty);
  });

  test('masala omelette is ready with staples assumed', () {
    final have = {'egg', 'onion', 'tomato', 'green chili', 'coriander leaves'};
    final ms = matchRecipes(recipes, have);
    final omelette = ms.firstWhere((m) => m.recipe.id == 'masala-omelette');
    expect(omelette.isReady, isTrue);
    expect(ms.first.missingCount, 0);
  });

  test('without staples the same fridge is not enough', () {
    final have = {'egg', 'onion', 'tomato', 'green chili', 'coriander leaves'};
    final ms = matchRecipes(recipes, have, assumeStaples: false);
    final omelette = ms.firstWhere((m) => m.recipe.id == 'masala-omelette');
    expect(omelette.isReady, isFalse);
    expect(omelette.missing.map((i) => i.name), contains('salt'));
  });

  test('results are sorted by fewest missing items', () {
    final ms = matchRecipes(recipes, {'potato', 'onion', 'tomato', 'peas'});
    for (var i = 1; i < ms.length; i++) {
      expect(ms[i].missingCount >= ms[i - 1].missingCount, isTrue);
    }
  });

  test('veg only hides non-veg dishes', () {
    final ms = matchRecipes(recipes, {'egg', 'chicken', 'potato', 'onion'}, vegOnly: true);
    expect(ms.every((m) => m.recipe.veg), isTrue);
  });

  test('typing only a staple finds nothing when staples are assumed', () {
    expect(matchRecipes(recipes, {'salt'}), isEmpty);
  });

  test('photo lookup tries the wiki title first, then the dish name', () {
    final butter = recipes.firstWhere((r) => r.id == 'butter-chicken');
    expect(butter.photoTitles.first, 'Butter chicken');
    final poha = recipes.firstWhere((r) => r.id == 'poha');
    expect(poha.photoTitles.first, 'Poha');
  });
}

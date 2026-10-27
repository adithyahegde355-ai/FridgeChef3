import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class Ingredient {
  const Ingredient({
    required this.name,
    required this.qty,
    this.staple = false,
    this.optional = false,
  });

  /// Canonical lowercase name, e.g. "potato" or "red chili powder".
  final String name;
  final String qty;

  /// Pantry staple (salt, oil, basic spices). Can be assumed available.
  final bool staple;

  /// Nice to have. Never counts as missing.
  final bool optional;

  factory Ingredient.fromJson(Map<String, dynamic> j) => Ingredient(
        name: j['n'] as String,
        qty: j['q'] as String,
        staple: j['s'] == 1,
        optional: j['o'] == 1,
      );
}

class CookStep {
  const CookStep({required this.text, this.seconds});

  final String text;

  /// Suggested timer length for this step, if it involves waiting.
  final int? seconds;

  factory CookStep.fromJson(Map<String, dynamic> j) =>
      CookStep(text: j['t'] as String, seconds: j['s'] as int?);
}

class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.emoji,
    required this.wiki,
    required this.veg,
    required this.minutes,
    required this.level,
    required this.serves,
    required this.ingredients,
    required this.steps,
  });

  final String id;
  final String name;
  final String emoji;

  /// Wikipedia article title to look the photo up under, when it differs
  /// from the dish name.
  final String? wiki;
  final bool veg;
  final int minutes;
  final String level;
  final int serves;
  final List<Ingredient> ingredients;
  final List<CookStep> steps;

  factory Recipe.fromJson(Map<String, dynamic> j) => Recipe(
        id: j['id'] as String,
        name: j['name'] as String,
        emoji: j['emoji'] as String,
        wiki: j['wiki'] as String?,
        veg: j['veg'] as bool,
        minutes: j['mins'] as int,
        level: j['level'] as String,
        serves: j['serves'] as int,
        ingredients: (j['ing'] as List)
            .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        steps: (j['steps'] as List)
            .map((e) => CookStep.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );

  /// Wikipedia titles to try, in order, when looking for a photo.
  List<String> get photoTitles {
    final out = <String>[];
    void add(String? t) {
      if (t != null && t.trim().isNotEmpty && !out.contains(t)) out.add(t);
    }

    add(wiki);
    add(name);
    add('$name (food)');
    add('$name (dish)');
    return out;
  }
}

class RecipeRepository {
  static Future<List<Recipe>> load() async =>
      parse(await rootBundle.loadString('assets/recipes.json'));

  static List<Recipe> parse(String raw) => (jsonDecode(raw) as List)
      .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
      .toList(growable: false);
}

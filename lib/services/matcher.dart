import '../models.dart';

/// True when the user can cover this ingredient.
bool isCovered(Ingredient i, Set<String> have, bool assumeStaples) =>
    (i.staple && assumeStaples) || have.contains(i.name);

class RecipeMatch {
  const RecipeMatch({
    required this.recipe,
    required this.missing,
    required this.haveCount,
    required this.totalCount,
    required this.hits,
  });

  final Recipe recipe;
  final List<Ingredient> missing;

  /// Counted ingredients the user has. Staples are left out of both counts
  /// when pantry staples are assumed, so "6/8" reflects the real shopping.
  final int haveCount;
  final int totalCount;

  /// How many of the user's typed ingredients this recipe actually uses.
  final int hits;

  int get missingCount => missing.length;
  bool get isReady => missing.isEmpty;
}

/// Ranks recipes by how few ingredients are missing.
List<RecipeMatch> matchRecipes(
  List<Recipe> recipes,
  Set<String> have, {
  bool assumeStaples = true,
  bool vegOnly = false,
}) {
  final out = <RecipeMatch>[];
  for (final r in recipes) {
    if (vegOnly && !r.veg) continue;
    final needed = r.ingredients.where((i) => !i.optional).toList();
    final counted = assumeStaples ? needed.where((i) => !i.staple).toList() : needed;
    final missing = needed.where((i) => !isCovered(i, have, assumeStaples)).toList();
    final hits = counted.where((i) => have.contains(i.name)).length;
    if (hits == 0) continue;
    out.add(RecipeMatch(
      recipe: r,
      missing: missing,
      haveCount: counted.length - missing.length,
      totalCount: counted.length,
      hits: hits,
    ));
  }
  out.sort((a, b) {
    final byMissing = a.missingCount.compareTo(b.missingCount);
    if (byMissing != 0) return byMissing;
    final byHits = b.hits.compareTo(a.hits);
    if (byHits != 0) return byHits;
    return a.recipe.minutes.compareTo(b.recipe.minutes);
  });
  return out;
}

/// Maps whatever the user types (Hindi names, plurals, spellings) onto the
/// canonical ingredient names used in the recipe data.
class IngredientCatalog {
  IngredientCatalog(Iterable<Recipe> recipes)
      : known = (recipes.expand((r) => r.ingredients).map((i) => i.name).toSet().toList()
          ..sort());

  final List<String> known;

  static const Map<String, String> aliases = {
    'aloo': 'potato', 'alu': 'potato',
    'tamatar': 'tomato',
    'pyaz': 'onion', 'pyaaz': 'onion', 'pyaj': 'onion',
    'palak': 'spinach',
    'gobi': 'cauliflower', 'gobhi': 'cauliflower', 'phool gobi': 'cauliflower',
    'bhindi': 'okra', 'lady finger': 'okra', 'ladyfinger': 'okra', 'ladies finger': 'okra',
    'baingan': 'brinjal', 'eggplant': 'brinjal', 'aubergine': 'brinjal',
    'anda': 'egg', 'eggs': 'egg',
    'dahi': 'curd', 'yogurt': 'curd', 'yoghurt': 'curd', 'curds': 'curd',
    'chawal': 'rice', 'basmati rice': 'rice', 'cooked rice': 'rice',
    'murgh': 'chicken', 'chicken breast': 'chicken', 'chicken thigh': 'chicken',
    'matar': 'peas', 'green peas': 'peas', 'pea': 'peas',
    'mirch': 'green chili', 'hari mirch': 'green chili', 'chili': 'green chili',
    'chilli': 'green chili', 'chilis': 'green chili', 'chilies': 'green chili',
    'chillies': 'green chili', 'green chilli': 'green chili', 'green chilly': 'green chili',
    'green chilies': 'green chili', 'green chillies': 'green chili',
    'dhania': 'coriander leaves', 'cilantro': 'coriander leaves', 'coriander': 'coriander leaves',
    'fresh coriander': 'coriander leaves',
    'kidney beans': 'rajma',
    'chana': 'chickpeas', 'chole': 'chickpeas', 'garbanzo': 'chickpeas', 'chickpea': 'chickpeas',
    'chick peas': 'chickpeas', 'kabuli chana': 'chickpeas',
    'atta': 'wheat flour', 'flour': 'wheat flour', 'whole wheat flour': 'wheat flour',
    'rava': 'semolina', 'rawa': 'semolina', 'sooji': 'semolina', 'suji': 'semolina',
    'haldi': 'turmeric',
    'jeera': 'cumin',
    'adrak': 'ginger',
    'lehsun': 'garlic', 'lasun': 'garlic', 'garlic cloves': 'garlic',
    'nimbu': 'lemon', 'lime': 'lemon',
    'toor': 'toor dal', 'arhar': 'toor dal', 'arhar dal': 'toor dal', 'tur dal': 'toor dal',
    'pigeon peas': 'toor dal',
    'moong': 'moong dal', 'mung dal': 'moong dal', 'green gram': 'moong dal',
    'malai': 'cream',
    'makhan': 'butter',
    'cottage cheese': 'paneer',
    'aval': 'poha', 'flattened rice': 'poha',
    'peanut': 'peanuts', 'groundnut': 'peanuts', 'groundnuts': 'peanuts', 'moongphali': 'peanuts',
    'curry leaf': 'curry leaves', 'kadi patta': 'curry leaves',
    'mint': 'mint leaves', 'pudina': 'mint leaves',
    'imli': 'tamarind',
    'nariyal': 'coconut', 'coconut milk': 'coconut', 'grated coconut': 'coconut',
    'idli batter': 'dosa batter',
    'bread roll': 'pav', 'bread rolls': 'pav', 'ladi pav': 'pav',
    'chili powder': 'red chili powder', 'chilli powder': 'red chili powder',
    'red chilli powder': 'red chili powder', 'lal mirch': 'red chili powder',
    'dhania powder': 'coriander powder',
    'rai': 'mustard seeds', 'sarson': 'mustard seeds', 'mustard': 'mustard seeds',
    'cooking oil': 'oil', 'vegetable oil': 'oil', 'sunflower oil': 'oil', 'mustard oil': 'oil',
    'kali mirch': 'black pepper', 'pepper': 'black pepper',
    'shimla mirch': 'capsicum', 'bell pepper': 'capsicum', 'green capsicum': 'capsicum',
    'gram flour': 'besan', 'chickpea flour': 'besan',
    'doodh': 'milk',
    'cheeni': 'sugar',
    'namak': 'salt',
    'sambar masala': 'sambar powder',
    'bhaji masala': 'pav bhaji masala',
  };

  String canon(String raw) {
    final s = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (s.isEmpty) return s;
    final direct = _lookup(s);
    if (direct != null) return direct;
    final single = _singular(s);
    return _lookup(single) ?? s;
  }

  String? _lookup(String s) {
    final a = aliases[s];
    if (a != null) return a;
    if (known.contains(s)) return s;
    return null;
  }

  static String _singular(String s) {
    if (s.endsWith('oes')) return s.substring(0, s.length - 2);
    if (s.endsWith('ies')) return '${s.substring(0, s.length - 3)}y';
    if (s.endsWith('s') && !s.endsWith('ss')) return s.substring(0, s.length - 1);
    return s;
  }

  /// Canonical ingredient names matching what has been typed so far.
  List<String> suggestions(String query, {Set<String> exclude = const {}, int limit = 8}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final starts = <String>[];
    final contains = <String>[];

    void consider(String term, String name) {
      if (exclude.contains(name) || !known.contains(name)) return;
      if (term.startsWith(q)) {
        if (!starts.contains(name)) starts.add(name);
      } else if (term.contains(q)) {
        if (!contains.contains(name)) contains.add(name);
      }
    }

    for (final k in known) {
      consider(k, k);
    }
    for (final e in aliases.entries) {
      consider(e.key, e.value);
    }
    return [...starts, ...contains.where((c) => !starts.contains(c))].take(limit).toList();
  }
}

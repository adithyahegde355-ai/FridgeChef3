import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'services/matcher.dart';

class AppState extends ChangeNotifier {
  AppState(this.recipes) : catalog = IngredientCatalog(recipes);

  final List<Recipe> recipes;
  final IngredientCatalog catalog;

  final Set<String> ingredients = <String>{};
  final Set<String> favorites = <String>{};
  bool assumeStaples = true;
  bool vegOnly = false;

  SharedPreferences? _prefs;

  Future<void> load() async {
    final p = _prefs = await SharedPreferences.getInstance();
    ingredients
      ..clear()
      ..addAll(p.getStringList('ingredients') ?? const []);
    favorites
      ..clear()
      ..addAll(p.getStringList('favorites') ?? const []);
    assumeStaples = p.getBool('assumeStaples') ?? true;
    vegOnly = p.getBool('vegOnly') ?? false;
  }

  void _save() {
    final p = _prefs;
    if (p == null) return;
    p.setStringList('ingredients', ingredients.toList());
    p.setStringList('favorites', favorites.toList());
    p.setBool('assumeStaples', assumeStaples);
    p.setBool('vegOnly', vegOnly);
  }

  void _changed() {
    _save();
    notifyListeners();
  }

  void add(String raw) {
    final name = catalog.canon(raw);
    if (name.isEmpty) return;
    ingredients.add(name);
    _changed();
  }

  void remove(String name) {
    ingredients.remove(name);
    _changed();
  }

  void clearIngredients() {
    ingredients.clear();
    _changed();
  }

  void setAssumeStaples(bool v) {
    assumeStaples = v;
    _changed();
  }

  void setVegOnly(bool v) {
    vegOnly = v;
    _changed();
  }

  bool isFavorite(Recipe r) => favorites.contains(r.id);

  void toggleFavorite(Recipe r) {
    if (!favorites.remove(r.id)) favorites.add(r.id);
    _changed();
  }

  List<Recipe> get favoriteRecipes =>
      recipes.where((r) => favorites.contains(r.id)).toList();

  List<RecipeMatch> get matches => matchRecipes(
        recipes,
        ingredients,
        assumeStaples: assumeStaples,
        vegOnly: vegOnly,
      );

  bool has(Ingredient i) => isCovered(i, ingredients, assumeStaples);
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../util.dart';
import 'results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController? _field;

  static const _quick = [
    'onion', 'tomato', 'potato', 'rice', 'egg', 'paneer', 'chicken',
    'curd', 'spinach', 'cauliflower', 'peas', 'lemon', 'besan', 'carrot',
  ];

  void _add(AppState state, String raw) {
    if (raw.trim().isEmpty) return;
    state.add(raw);
    _field?.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final count = state.matches.length;
    final suggestions = _quick.where((q) => !state.ingredients.contains(q)).toList();

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              children: [
                Text(
                  "What's in your fridge?",
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  "Add what you have and we'll find Indian dishes you can cook.",
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 18),
                Autocomplete<String>(
                  optionsBuilder: (value) =>
                      state.catalog.suggestions(value.text, exclude: state.ingredients),
                  onSelected: (value) {
                    state.add(value);
                    WidgetsBinding.instance.addPostFrameCallback((_) => _field?.clear());
                  },
                  fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                    _field = controller;
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: 'Type an ingredient, e.g. aloo, paneer, egg',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          tooltip: 'Add',
                          icon: const Icon(Icons.add_circle),
                          onPressed: () => _add(state, controller.text),
                        ),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (text) {
                        _add(state, text);
                        focusNode.requestFocus();
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (state.ingredients.isEmpty)
                  Text(
                    'Nothing added yet. Type above or tap a suggestion below.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                  )
                else ...[
                  Row(
                    children: [
                      Text('Your ingredients', style: theme.textTheme.titleMedium),
                      const Spacer(),
                      TextButton(onPressed: state.clearIngredients, child: const Text('Clear all')),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final name in state.ingredients)
                        InputChip(
                          label: Text(titleCase(name)),
                          onDeleted: () => state.remove(name),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('I have pantry staples'),
                  subtitle: const Text('Salt, oil, sugar and basic spices'),
                  value: state.assumeStaples,
                  onChanged: state.setAssumeStaples,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Vegetarian only'),
                  value: state.vegOnly,
                  onChanged: state.setVegOnly,
                ),
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Quick add', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final name in suggestions)
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 18),
                          label: Text(titleCase(name)),
                          onPressed: () => state.add(name),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: count == 0
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const ResultsScreen()),
                        ),
                icon: const Icon(Icons.restaurant_menu),
                label: Text(
                  state.ingredients.isEmpty
                      ? 'Add an ingredient to start'
                      : count == 0
                          ? 'No recipes yet, add more'
                          : 'Show $count recipe${count == 1 ? '' : 's'}',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

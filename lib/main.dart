import 'package:flutter/material.dart';

import 'app_state.dart';
import 'models.dart';
import 'screens/favorites_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final recipes = await RecipeRepository.load();
  final state = AppState(recipes);
  await state.load();
  runApp(FridgeChefApp(state: state));
}

class FridgeChefApp extends StatelessWidget {
  const FridgeChefApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'Fridge Chef',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE8590C)),
          scaffoldBackgroundColor: const Color(0xFFFFF8F0),
        ),
        home: const _Shell(),
      ),
    );
  }
}

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final saved = AppScope.of(context).favorites.length;
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [HomeScreen(), FavoritesScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.kitchen_outlined), selectedIcon: Icon(Icons.kitchen), label: 'Cook'),
          NavigationDestination(
            icon: Badge(isLabelVisible: saved > 0, label: Text('$saved'), child: const Icon(Icons.favorite_border)),
            selectedIcon: const Icon(Icons.favorite),
            label: 'Saved',
          ),
        ],
      ),
    );
  }
}

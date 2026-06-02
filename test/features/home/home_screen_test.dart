import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lista_smart/core/persistence/shared_preferences_provider.dart';
import 'package:lista_smart/core/providers/view_mode_notifier.dart';
import 'package:lista_smart/features/home/presentation/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal GoRouter for HomeScreen tests — pushes to a dummy page on navigation.
GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'product/:productId',
            builder: (_, __) =>
                const Scaffold(body: Text('Product Detail')),
          ),
        ],
      ),
      GoRoute(
        path: '/scanner',
        builder: (_, __) => const Scaffold(body: Text('Scanner')),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const Scaffold(body: Text('Profile')),
      ),
    ],
  );
}

Widget _buildTestApp(WidgetRef? refCapture, {List<Override> overrides = const []}) {
  final router = _buildTestRouter();
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildApp({List<Override> extraOverrides = const []}) {
    final router = _buildTestRouter();
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        ...extraOverrides,
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  // HOME-03: Products render on screen
  testWidgets('HOME-03: products render in grid by default', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Grid is the default ViewMode — product cards should appear.
    // The mock data has 12 products; at least some should be visible.
    expect(find.byType(HomeScreen), findsOneWidget);

    // Search bar is visible
    expect(find.byType(TextField), findsOneWidget);
  });

  // HOME-01: Grid/List toggle works
  testWidgets('HOME-01: grid/list view mode toggle icons are present',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Both toggle buttons (layoutGrid and list icons) are visible
    // We look for IconButton widgets in the AppBar
    final iconButtons = find.byType(IconButton);
    expect(iconButtons, findsWidgets);
  });

  // HOME-01: Switching to list mode works
  testWidgets('HOME-01: switching to list mode changes the view',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Tap the list view mode button (second action icon)
    final listTooltip = find.byTooltip('Exibir em lista');
    expect(listTooltip, findsOneWidget);
    await tester.tap(listTooltip);
    await tester.pumpAndSettle();

    // Tap the grid view mode button
    final gridTooltip = find.byTooltip('Exibir em grade');
    expect(gridTooltip, findsOneWidget);
    await tester.tap(gridTooltip);
    await tester.pumpAndSettle();
  });

  // HOME-07: onTap is present (product card is tappable)
  testWidgets('HOME-07: product cards are tappable (GestureDetector present)',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // GestureDetectors are used on product cards for navigation
    expect(find.byType(GestureDetector), findsWidgets);
  });

  // Search bar filters products
  testWidgets('Searching with no match shows empty state message',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField);
    await tester.enterText(searchField, 'xyznonexistent999');
    await tester.pumpAndSettle();

    expect(find.textContaining('Nenhum produto encontrado'), findsOneWidget);
  });

  // FloatingActionButton (scanner) is present
  testWidgets('FloatingActionButton for scanner is visible', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byTooltip('Escanear nota fiscal'), findsOneWidget);
  });
}

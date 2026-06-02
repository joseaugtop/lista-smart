import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lista_smart/core/persistence/shared_preferences_provider.dart';
import 'package:lista_smart/core/providers/cart_notifier.dart';
import 'package:lista_smart/core/providers/fuel_toggle_notifier.dart';
import 'package:lista_smart/core/providers/user_notifier.dart';
import 'package:lista_smart/features/shopping_list/domain/cart_item.dart';
import 'package:lista_smart/features/shopping_list/presentation/shopping_list_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _item1 = CartItem(
  productId: 'p1',
  productName: 'Arroz Tio João',
  brand: 'Tio João',
  imageUrl: 'https://example.com/arroz.jpg',
  quantity: 2,
  unitPrice: 9.99,
);

const _item2 = CartItem(
  productId: 'p2',
  productName: 'Feijão Carioca',
  brand: 'Kicaldo',
  imageUrl: 'https://example.com/feijao.jpg',
  quantity: 1,
  unitPrice: 7.49,
);

/// Builds a ProviderContainer with a mocked SharedPreferences.
Future<ProviderContainer> _buildContainer({
  SharedPreferences? prefs,
  List<Override> extraOverrides = const [],
}) async {
  final p = prefs ?? await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(p),
      ...extraOverrides,
    ],
  );
}

/// Pumps ShoppingListScreen inside an [UncontrolledProviderScope].
Future<void> _pumpScreen(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ShoppingListScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // -------------------------------------------------------------------------
  // 1. Empty state
  // -------------------------------------------------------------------------
  testWidgets('cart vazio exibe empty state', (tester) async {
    final container = await _buildContainer();
    addTearDown(container.dispose);

    await _pumpScreen(tester, container);

    expect(find.text('Sua lista está vazia'), findsOneWidget);
    expect(find.byIcon(LucideIcons.shoppingCart), findsOneWidget);
    expect(find.text('Adicione produtos na tela Home'), findsOneWidget);
    // Footer button must NOT appear
    expect(find.text('Comparar Supermercados'), findsNothing);
    // Trash icon must NOT appear
    expect(find.byIcon(LucideIcons.trash2), findsNothing);
  });

  // -------------------------------------------------------------------------
  // 2. Non-empty state renders cards and footer
  // -------------------------------------------------------------------------
  testWidgets('cart com 2 itens renderiza cards e footer', (tester) async {
    final container = await _buildContainer();
    addTearDown(container.dispose);

    container.read(cartProvider.notifier).addItem(_item1);
    container.read(cartProvider.notifier).addItem(_item2);

    await _pumpScreen(tester, container);

    expect(find.text('Arroz Tio João'), findsOneWidget);
    expect(find.text('Feijão Carioca'), findsOneWidget);
    expect(find.byIcon(LucideIcons.plus), findsWidgets);
    expect(find.byIcon(LucideIcons.trash2), findsOneWidget);
    expect(find.text('Comparar Supermercados'), findsOneWidget);
  });

  // -------------------------------------------------------------------------
  // 3. Tap + increments quantity
  // -------------------------------------------------------------------------
  testWidgets('tap em + dispara incrementQuantity', (tester) async {
    final container = await _buildContainer();
    addTearDown(container.dispose);

    // Start with item qty=1 (addItem creates qty=1 initially)
    final item = const CartItem(
      productId: 'p1',
      productName: 'Arroz Tio João',
      brand: 'Tio João',
      imageUrl: '',
      quantity: 1,
      unitPrice: 9.99,
    );
    container.read(cartProvider.notifier).addItem(item);

    await _pumpScreen(tester, container);

    // The quantity text should currently be '1'
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.plus).first);
    await tester.pumpAndSettle();

    // Quantity should now be 2
    expect(find.text('2'), findsOneWidget);
  });

  // -------------------------------------------------------------------------
  // 4. Tap - with qty=1 removes item (empty state appears)
  // -------------------------------------------------------------------------
  testWidgets('tap em - com qty=1 remove item', (tester) async {
    final container = await _buildContainer();
    addTearDown(container.dispose);

    const item = CartItem(
      productId: 'p1',
      productName: 'Arroz Tio João',
      brand: 'Tio João',
      imageUrl: '',
      quantity: 1,
      unitPrice: 9.99,
    );
    container.read(cartProvider.notifier).addItem(item);

    await _pumpScreen(tester, container);

    expect(find.text('Arroz Tio João'), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.minus).first);
    await tester.pumpAndSettle();

    // Cart should now be empty
    expect(find.text('Sua lista está vazia'), findsOneWidget);
  });

  // -------------------------------------------------------------------------
  // 5. Tap X removes item
  // -------------------------------------------------------------------------
  testWidgets('tap em X remove item', (tester) async {
    final container = await _buildContainer();
    addTearDown(container.dispose);

    container.read(cartProvider.notifier).addItem(_item1);

    await _pumpScreen(tester, container);

    expect(find.text('Arroz Tio João'), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.x).first);
    await tester.pumpAndSettle();

    expect(find.text('Sua lista está vazia'), findsOneWidget);
  });

  // -------------------------------------------------------------------------
  // 6. Trash2 opens AlertDialog — confirm clears cart
  // -------------------------------------------------------------------------
  testWidgets('tap em trash2 abre AlertDialog e confirma limpeza', (tester) async {
    final container = await _buildContainer();
    addTearDown(container.dispose);

    container.read(cartProvider.notifier).addItem(_item1);
    container.read(cartProvider.notifier).addItem(_item2);

    await _pumpScreen(tester, container);

    expect(find.text('Arroz Tio João'), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.trash2));
    await tester.pumpAndSettle();

    // Dialog should appear
    expect(find.text('Limpar carrinho?'), findsOneWidget);

    await tester.tap(find.text('Limpar Carrinho'));
    await tester.pumpAndSettle();

    // Cart should now be empty
    expect(find.text('Sua lista está vazia'), findsOneWidget);
  });

  // -------------------------------------------------------------------------
  // 7. Switch toggle persists in fuelToggleProvider
  // -------------------------------------------------------------------------
  testWidgets('Switch toggle persiste em fuelToggleProvider', (tester) async {
    // Initial value of fuel toggle is true (default)
    final container = await _buildContainer();
    addTearDown(container.dispose);

    container.read(cartProvider.notifier).addItem(_item1);

    await _pumpScreen(tester, container);

    // Switch starts true (on)
    expect(container.read(fuelToggleProvider), isTrue);

    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    // fuelToggleProvider should now be false
    expect(container.read(fuelToggleProvider), isFalse);
  });

  // -------------------------------------------------------------------------
  // 8. Tap 'Comparar Supermercados' navigates to /shopping-list/comparison
  // -------------------------------------------------------------------------
  testWidgets('tap Comparar Supermercados navega para /shopping-list/comparison',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Suppress image-load errors — Image.network with invalid URL
    // throws in test environment even when errorBuilder is provided.
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('NetworkImageLoadException') ||
          details.exceptionAsString().contains('HTTP request failed')) {
        return; // swallow image load failures
      }
      originalOnError?.call(details);
    };

    final router = GoRouter(
      initialLocation: '/shopping-list',
      routes: [
        GoRoute(
          path: '/shopping-list',
          builder: (_, __) => const ShoppingListScreen(),
          routes: [
            GoRoute(
              path: 'comparison',
              builder: (_, __) => const Scaffold(body: Text('comparison')),
            ),
          ],
        ),
      ],
    );

    late ProviderContainer container;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    // Get the container from the ProviderScope
    container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );

    await tester.pump();

    const navItem = CartItem(
      productId: 'nav1',
      productName: 'Produto Teste',
      brand: 'Marca',
      imageUrl: 'invalid-url-to-trigger-error-builder',
      quantity: 1,
      unitPrice: 5.0,
    );
    container.read(cartProvider.notifier).addItem(navItem);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Comparar Supermercados'), findsOneWidget);

    // Seed enough coins so the comparison button works
    container.read(userNotifierProvider.notifier).login();
    await tester.pump();

    await tester.tap(find.text('Comparar Supermercados'));
    await tester.pump(); // start loading
    await tester.pump(const Duration(milliseconds: 1700)); // wait for delay
    await tester.pumpAndSettle();

    // Restore error handler
    FlutterError.onError = originalOnError;

    expect(find.text('comparison'), findsOneWidget);
  });
}

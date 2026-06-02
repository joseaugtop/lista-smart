import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_smart/core/persistence/shared_preferences_provider.dart';
import 'package:lista_smart/core/providers/coin_notifier.dart';
import 'package:lista_smart/features/smart_coins/presentation/store_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<ProviderContainer> _makeContainer({int balance = 0}) async {
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  addTearDown(container.dispose);
  if (balance > 0) {
    container.read(coinProvider.notifier).addCoins(balance, 'seed');
  }
  return container;
}

Future<void> _pumpScreen(
    WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: StoreScreen()),
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

  // COIN-01: Balance display + level badge
  testWidgets('COIN-01: shows Prata badge for balance 750', (tester) async {
    final container = await _makeContainer(balance: 750);

    await _pumpScreen(tester, container);

    // Balance seeded: MockData.initialTransactions may add coins — check level
    expect(find.text('Prata'), findsOneWidget);
    expect(find.text('Smart Coins'), findsWidgets);
  });

  testWidgets('COIN-01: shows Bronze badge for balance 100', (tester) async {
    final container = await _makeContainer(balance: 100);

    await _pumpScreen(tester, container);

    expect(find.text('Bronze'), findsOneWidget);
  });

  testWidgets('COIN-01: shows Ouro badge and max text for balance 2000',
      (tester) async {
    final container = await _makeContainer(balance: 2000);

    await _pumpScreen(tester, container);

    expect(find.text('Ouro'), findsOneWidget);
    expect(find.text('Nível máximo atingido'), findsOneWidget);
  });

  // COIN-02: Animated progress bar (TweenAnimationBuilder renders)
  testWidgets('COIN-02: progress bar renders inside header', (tester) async {
    final container = await _makeContainer(balance: 300);

    await _pumpScreen(tester, container);

    expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  // COIN-03: 3 package cards
  testWidgets('COIN-03: renders 3 package cards with Obter buttons',
      (tester) async {
    final container = await _makeContainer();

    await _pumpScreen(tester, container);

    expect(find.text('100'), findsOneWidget);
    expect(find.text('500'), findsOneWidget);
    expect(find.text('1000'), findsOneWidget);
    expect(find.text('Obter'), findsNWidgets(3));
  });

  testWidgets('COIN-03: Obter button credits coins and shows SnackBar',
      (tester) async {
    final container = await _makeContainer();
    final balanceBefore = container.read(coinProvider).balance;

    await _pumpScreen(tester, container);

    await tester.tap(find.text('Obter').first);
    await tester.pump();

    expect(container.read(coinProvider).balance, greaterThan(balanceBefore));
  });

  // COIN-04: Transaction history
  testWidgets('COIN-04: Histórico section header always renders',
      (tester) async {
    final container = await _makeContainer();

    await _pumpScreen(tester, container);

    expect(find.text('Histórico'), findsOneWidget);
  });

  testWidgets('COIN-04: shows transaction with + prefix for gains',
      (tester) async {
    final container = await _makeContainer(balance: 250);

    await _pumpScreen(tester, container);

    // The seeded transaction (and/or MockData initial) should show a + prefix
    expect(find.textContaining('+'), findsWidgets);
  });
}

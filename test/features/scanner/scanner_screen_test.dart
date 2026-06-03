import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_smart/core/persistence/shared_preferences_provider.dart';
import 'package:lista_smart/core/providers/user_notifier.dart';
import 'package:lista_smart/features/price_registration/presentation/scanner_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<ProviderContainer> _makeContainer() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  addTearDown(container.dispose);
  // ScannerScreen needs a logged-in user for coin award
  container.read(userNotifierProvider.notifier).login();
  return container;
}

Future<void> _pumpScreen(
    WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ScannerScreen()),
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

  // PREG-01: Step 1 renders QR Code and Camera method cards
  testWidgets(
    'PREG-01: Step 1 renders QR Code and Camera method cards',
    (tester) async {
      final container = await _makeContainer();
      await _pumpScreen(tester, container);

      expect(find.text('Escanear QR Code'), findsOneWidget);
      expect(find.text('Foto do Cupom'), findsOneWidget);
    },
  );

  // PREG-02: Step 2 shows receipt fields and confirm button
  testWidgets(
    'PREG-02: Step 2 shows receipt fields and confirm button',
    (tester) async {
      final container = await _makeContainer();
      await _pumpScreen(tester, container);

      // Tap a method card to trigger the 2s loading delay then advance to Step 2
      await tester.tap(find.text('Escanear QR Code'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Bistek Supermercados'), findsOneWidget);
      expect(find.text('R\$ 87,43'), findsOneWidget);
      expect(find.text('Confirmar e Ganhar Moedas'), findsOneWidget);
    },
  );

  // PREG-03: Step 3 shows ConfettiWidget and +10 Smart Coins
  testWidgets(
    'PREG-03: Step 3 shows ConfettiWidget and +10 Smart Coins',
    (tester) async {
      final container = await _makeContainer();
      await _pumpScreen(tester, container);

      // Navigate to Step 2
      await tester.tap(find.text('Escanear QR Code'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Confirm to advance to Step 3
      await tester.tap(find.text('Confirmar e Ganhar Moedas'));
      await tester.pumpAndSettle();

      expect(find.byType(ConfettiWidget), findsOneWidget);
      expect(find.text('+10 Smart Coins'), findsOneWidget);
    },
  );
}

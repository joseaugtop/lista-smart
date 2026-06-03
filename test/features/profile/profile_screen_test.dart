import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_smart/core/constants/app_strings.dart';
import 'package:lista_smart/core/persistence/shared_preferences_provider.dart';
import 'package:lista_smart/core/providers/coin_notifier.dart';
import 'package:lista_smart/core/providers/user_notifier.dart';
import 'package:lista_smart/features/profile/presentation/profile_screen.dart';
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
  container.read(userNotifierProvider.notifier).login();
  return container;
}

Future<void> _pumpScreen(
    WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ProfileScreen()),
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

  testWidgets(
    'PROF-01: profile shows pre-filled name/email/address fields',
    (tester) async {
      final container = await _makeContainer();

      await _pumpScreen(tester, container);

      expect(find.text('José Augusto'), findsWidgets);
      expect(find.text('Nome completo'), findsOneWidget);
      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('Endereço'), findsOneWidget);
    },
  );

  testWidgets(
    'PROF-03: impact stats show derived scan count + mocked stats',
    (tester) async {
      final container = await _makeContainer();

      // Seed 3 scan-receipt transactions
      container
          .read(coinProvider.notifier)
          .addCoins(10, AppStrings.scanReceiptDescription);
      container
          .read(coinProvider.notifier)
          .addCoins(10, AppStrings.scanReceiptDescription);
      container
          .read(coinProvider.notifier)
          .addCoins(10, AppStrings.scanReceiptDescription);

      await _pumpScreen(tester, container);

      // The derived scan count should be 3
      expect(find.text('3'), findsOneWidget);
      // Mocked stats
      expect(find.text('47'), findsOneWidget);
      expect(find.textContaining('342'), findsOneWidget);
    },
  );
}

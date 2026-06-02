import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_smart/core/persistence/shared_preferences_provider.dart';
import 'package:lista_smart/core/providers/cart_notifier.dart';
import 'package:lista_smart/core/providers/comparison_results_provider.dart';
import 'package:lista_smart/features/shopping_list/domain/cart_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _leite = CartItem(
  productId: 'p01',
  productName: 'Leite Integral',
  brand: 'Tirol',
  imageUrl: '',
  quantity: 1,
  unitPrice: 5.49,
);

void main() {
  group('comparisonResultsProvider', () {
    Future<ProviderContainer> makeContainer({
      Map<String, Object>? prefsInitial,
    }) async {
      SharedPreferences.setMockInitialValues(prefsInitial ?? {});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      return container;
    }

    // COMP-01: 4 supermarkets always returned
    test('COMP-01: returns results for all 4 supermarkets', () async {
      final container = await makeContainer();
      final results = container.read(comparisonResultsProvider);
      expect(results.length, equals(4));
      final names = results.map((r) => r.supermarket).toSet();
      expect(names, containsAll(['Bistek', 'Giassi', 'Angeloni', 'Atacadão']));
    });

    // COMP-02: results ordered ascending by totalCost
    test('COMP-02: results are sorted ascending by totalCost', () async {
      final container = await makeContainer();
      container.read(cartProvider.notifier).addItem(_leite);
      final results = container.read(comparisonResultsProvider);
      for (int i = 0; i < results.length - 1; i++) {
        expect(
          results[i].totalCost,
          lessThanOrEqualTo(results[i + 1].totalCost),
          reason:
              '${results[i].supermarket}(${results[i].totalCost}) should be <= ${results[i + 1].supermarket}(${results[i + 1].totalCost})',
        );
      }
    });

    // Fuel ON: fuelCost > 0 for Bistek
    test('fuel toggle ON includes fuel cost in total', () async {
      final container = await makeContainer();
      container.read(cartProvider.notifier).addItem(_leite);
      final results = container.read(comparisonResultsProvider);
      final bistek = results.firstWhere((r) => r.supermarket == 'Bistek');
      expect(bistek.fuelCost, greaterThan(0));
    });

    // Fuel OFF: fuelCost == 0
    test('fuel toggle OFF sets fuelCost to 0', () async {
      // Persist fuel toggle as false
      final container = await makeContainer(
        prefsInitial: {'lista_smart_fuel_toggle': false},
      );
      container.read(cartProvider.notifier).addItem(_leite);
      final results = container.read(comparisonResultsProvider);
      for (final r in results) {
        expect(r.fuelCost, equals(0.0),
            reason: '${r.supermarket} should have 0 fuel cost when toggle is OFF');
      }
    });

    // Exact fuelCost for Bistek: (2.3 * 2 / 12.0) * 6.50 ≈ 2.4917
    test('exact fuelCost for Bistek at 2.3 km distance', () async {
      final container = await makeContainer();
      container.read(cartProvider.notifier).addItem(_leite);
      final results = container.read(comparisonResultsProvider);
      final bistek = results.firstWhere((r) => r.supermarket == 'Bistek');
      // (2.3 * 2 / 12.0) * 6.50 = 2.491666...
      const expected = (2.3 * 2 / 12.0) * 6.50;
      expect(bistek.fuelCost, closeTo(expected, 0.001));
      expect(bistek.distanceKm, equals(2.3));
    });

    test('empty cart: productsCost is 0 for all supermarkets', () async {
      final container = await makeContainer();
      final results = container.read(comparisonResultsProvider);
      for (final r in results) {
        expect(r.productsCost, equals(0.0));
      }
    });

    test('productsCost uses prices map, not item.unitPrice, when price available',
        () async {
      final container = await makeContainer();
      container.read(cartProvider.notifier).addItem(_leite);
      final results = container.read(comparisonResultsProvider);
      // p01 Bistek price from MockData.prices is 5.29 (not 5.49 unitPrice)
      final bistek = results.firstWhere((r) => r.supermarket == 'Bistek');
      expect(bistek.productsCost, closeTo(5.29, 0.001));
    });
  });
}

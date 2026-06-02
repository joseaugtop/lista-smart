import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_smart/core/persistence/shared_preferences_provider.dart';
import 'package:lista_smart/core/providers/filtered_products_provider.dart';
import 'package:lista_smart/core/providers/search_query_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('filteredProductsProvider', () {
    Future<ProviderContainer> makeContainer() async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      addTearDown(container.dispose);
      return container;
    }

    test('empty query returns all 12 products', () async {
      final container = await makeContainer();
      final products = container.read(filteredProductsProvider);
      expect(products.length, equals(12));
    });

    test("query 'leite' returns only matching products", () async {
      final container = await makeContainer();
      container.read(searchQueryProvider.notifier).update('leite');
      final products = container.read(filteredProductsProvider);
      expect(products, isNotEmpty);
      for (final p in products) {
        final matches = p.name.toLowerCase().contains('leite') ||
            p.brand.toLowerCase().contains('leite') ||
            p.category.toLowerCase().contains('leite');
        expect(matches, isTrue, reason: '${p.name} should match "leite"');
      }
    });

    test('unknown query returns empty list', () async {
      final container = await makeContainer();
      container.read(searchQueryProvider.notifier).update('xyznonexistent');
      final products = container.read(filteredProductsProvider);
      expect(products, isEmpty);
    });

    test('search is case-insensitive', () async {
      final container = await makeContainer();
      container.read(searchQueryProvider.notifier).update('LEITE');
      final upperResults = container.read(filteredProductsProvider);
      container.read(searchQueryProvider.notifier).update('leite');
      final lowerResults = container.read(filteredProductsProvider);
      expect(upperResults.length, equals(lowerResults.length));
    });

    test("query 'Laticínios' matches by category", () async {
      final container = await makeContainer();
      container.read(searchQueryProvider.notifier).update('laticínios');
      final products = container.read(filteredProductsProvider);
      expect(products.length, greaterThanOrEqualTo(3));
    });

    test("query 'Tirol' matches by brand", () async {
      final container = await makeContainer();
      container.read(searchQueryProvider.notifier).update('tirol');
      final products = container.read(filteredProductsProvider);
      expect(products, isNotEmpty);
      expect(
          products.any((p) => p.brand.toLowerCase().contains('tirol')), isTrue);
    });

    test('clearing query returns all products again', () async {
      final container = await makeContainer();
      container.read(searchQueryProvider.notifier).update('leite');
      expect(container.read(filteredProductsProvider).length, lessThan(12));
      container.read(searchQueryProvider.notifier).clear();
      expect(container.read(filteredProductsProvider).length, equals(12));
    });
  });
}

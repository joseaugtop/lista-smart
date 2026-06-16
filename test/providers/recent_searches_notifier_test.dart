import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_smart/core/persistence/shared_preferences_provider.dart';
import 'package:lista_smart/core/providers/recent_searches_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('RecentSearchesNotifier', () {
    Future<(ProviderContainer, SharedPreferences)> makeContainer({
      SharedPreferences? reuse,
    }) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = reuse ?? await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      return (container, prefs);
    }

    test('build() returns [] when no search history is persisted', () async {
      final (container, _) = await makeContainer();
      expect(container.read(recentSearchesProvider), isEmpty);
    });

    test('addSearch() adds search at front, trims, and deduplicates', () async {
      final (container, _) = await makeContainer();
      final notifier = container.read(recentSearchesProvider.notifier);

      notifier.addSearch('  Arroz  ');
      expect(container.read(recentSearchesProvider), equals(['Arroz']));

      notifier.addSearch('Feijão');
      expect(container.read(recentSearchesProvider), equals(['Feijão', 'Arroz']));

      // Add Arroz again, it should move to the front
      notifier.addSearch('Arroz');
      expect(container.read(recentSearchesProvider), equals(['Arroz', 'Feijão']));

      // Ignore empty search
      notifier.addSearch('   ');
      expect(container.read(recentSearchesProvider), equals(['Arroz', 'Feijão']));
    });

    test('addSearch() enforces maximum limit of 5 items', () async {
      final (container, _) = await makeContainer();
      final notifier = container.read(recentSearchesProvider.notifier);

      notifier.addSearch('item 1');
      notifier.addSearch('item 2');
      notifier.addSearch('item 3');
      notifier.addSearch('item 4');
      notifier.addSearch('item 5');
      notifier.addSearch('item 6');

      final list = container.read(recentSearchesProvider);
      expect(list.length, equals(5));
      expect(list, equals(['item 6', 'item 5', 'item 4', 'item 3', 'item 2']));
    });

    test('removeSearch() removes the query', () async {
      final (container, _) = await makeContainer();
      final notifier = container.read(recentSearchesProvider.notifier);

      notifier.addSearch('A');
      notifier.addSearch('B');
      notifier.removeSearch('A');

      expect(container.read(recentSearchesProvider), equals(['B']));
    });

    test('clearHistory() empties the searches list', () async {
      final (container, _) = await makeContainer();
      final notifier = container.read(recentSearchesProvider.notifier);

      notifier.addSearch('A');
      notifier.clearHistory();

      expect(container.read(recentSearchesProvider), isEmpty);
    });

    test('searches survive restart (hydration from SharedPreferences)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container1 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      container1.read(recentSearchesProvider.notifier).addSearch('café');
      container1.dispose();

      final container2 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container2.dispose);

      expect(container2.read(recentSearchesProvider), equals(['café']));
    });

    test('build() returns [] when persisted JSON is corrupted', () async {
      SharedPreferences.setMockInitialValues({
        'lista_smart_recent_searches': 'not-valid-json{{{',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(recentSearchesProvider), isEmpty);
    });
  });
}

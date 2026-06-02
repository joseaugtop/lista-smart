import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_smart/core/persistence/shared_preferences_provider.dart';
import 'package:lista_smart/core/providers/favorites_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('FavoritesNotifier', () {
    test('build() returns [] when no favorites persisted', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(favoritesProvider), isEmpty);
    });

    test('toggle() adds absent id; toggle() again removes it', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      container.read(favoritesProvider.notifier).toggle('p01');
      expect(container.read(favoritesProvider), contains('p01'));

      container.read(favoritesProvider.notifier).toggle('p01');
      expect(container.read(favoritesProvider), isNot(contains('p01')));
    });

    test('isFavorite() reflects current state', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(favoritesProvider.notifier).isFavorite('p01'), isFalse);
      container.read(favoritesProvider.notifier).toggle('p01');
      expect(container.read(favoritesProvider.notifier).isFavorite('p01'), isTrue);
    });

    test('favorites survive restart (hydration via getStringList)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container1 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      container1.read(favoritesProvider.notifier).toggle('p01');
      container1.dispose();

      final container2 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container2.dispose);

      expect(container2.read(favoritesProvider), contains('p01'));
    });
  });
}

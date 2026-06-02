import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_smart/core/persistence/shared_preferences_provider.dart';
import 'package:lista_smart/core/providers/fuel_toggle_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('FuelToggleNotifier', () {
    Future<ProviderContainer> makeContainer({Map<String, Object>? initial}) async {
      SharedPreferences.setMockInitialValues(initial ?? {});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('build() defaults to true when no persisted value', () async {
      final container = await makeContainer();
      expect(container.read(fuelToggleProvider), isTrue);
    });

    test('build() restores persisted false value', () async {
      final container = await makeContainer(
        initial: {'lista_smart_fuel_toggle': false},
      );
      expect(container.read(fuelToggleProvider), isFalse);
    });

    test('toggle() switches from true to false', () async {
      final container = await makeContainer();
      expect(container.read(fuelToggleProvider), isTrue);
      container.read(fuelToggleProvider.notifier).toggle();
      expect(container.read(fuelToggleProvider), isFalse);
    });

    test('toggle() switches from false to true', () async {
      final container = await makeContainer(
        initial: {'lista_smart_fuel_toggle': false},
      );
      container.read(fuelToggleProvider.notifier).toggle();
      expect(container.read(fuelToggleProvider), isTrue);
    });

    test('toggle() persists the value', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      container.read(fuelToggleProvider.notifier).toggle();
      expect(prefs.getBool('lista_smart_fuel_toggle'), isFalse);
    });
  });
}

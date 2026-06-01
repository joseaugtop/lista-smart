import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_smart/core/persistence/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('sharedPreferencesProvider', () {
    test('throws UnimplementedError when accessed without override', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(sharedPreferencesProvider),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('returns injected instance when overridden via ProviderScope', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      // Should NOT throw — override is in place
      final result = container.read(sharedPreferencesProvider);
      expect(result, isA<SharedPreferences>());
    });
  });
}

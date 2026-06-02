import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_smart/core/persistence/shared_preferences_provider.dart';
import 'package:lista_smart/core/providers/user_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('RouterNotifier (via userNotifierProvider state)', () {
    // Note: GoRouterState is not trivially instantiable in unit tests.
    // We test the auth state that governs redirect decisions directly.
    // The redirect logic: user==null → /login, user!=null && on /login → /home, else null.

    test('user is null when no session (redirect would go to /login)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final user = container.read(userNotifierProvider);
      expect(user, isNull,
          reason: 'No session → user null → redirect would return /login');
    });

    test('user is non-null after login (redirect from /login would go to /home)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      container.read(userNotifierProvider.notifier).login();

      final user = container.read(userNotifierProvider);
      expect(user, isNotNull,
          reason: 'After login → user non-null → redirect from /login would return /home');
    });

    test('user returns to null after logout (redirect would go to /login again)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      container.read(userNotifierProvider.notifier).login();
      container.read(userNotifierProvider.notifier).logout();

      final user = container.read(userNotifierProvider);
      expect(user, isNull,
          reason: 'After logout → user null → redirect would return /login');
    });
  });
}

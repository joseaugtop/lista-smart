import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_smart/core/data/mock_data.dart';
import 'package:lista_smart/core/persistence/shared_preferences_provider.dart';
import 'package:lista_smart/core/providers/user_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('UserNotifier', () {
    test('build() returns null when no session persisted', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(userNotifierProvider), isNull);
    });

    test('login() sets state to MockData.user', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      container.read(userNotifierProvider.notifier).login();

      final user = container.read(userNotifierProvider);
      expect(user, isNotNull);
      expect(user!.id, equals('jose_augusto_001'));
      expect(user.name, equals('José Augusto'));
      expect(user.coinBalance, equals(750));
    });

    test('login() persists user to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      container.read(userNotifierProvider.notifier).login();

      expect(prefs.getString('lista_smart_user'), isNotNull);
    });

    test('session survives restart (hydration from SharedPreferences)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container1 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      container1.read(userNotifierProvider.notifier).login();
      container1.dispose();

      final container2 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container2.dispose);

      final user = container2.read(userNotifierProvider);
      expect(user, isNotNull);
      expect(user!.id, equals(MockData.user.id));
    });

    test('logout() clears state and removes key from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      container.read(userNotifierProvider.notifier).login();
      container.read(userNotifierProvider.notifier).logout();

      expect(container.read(userNotifierProvider), isNull);
      expect(prefs.getString('lista_smart_user'), isNull);
    });

    test('build() returns null when persisted JSON is corrupted', () async {
      SharedPreferences.setMockInitialValues({
        'lista_smart_user': 'not-valid-json{{{',
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(userNotifierProvider), isNull);
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_smart/core/data/mock_data.dart';
import 'package:lista_smart/core/persistence/shared_preferences_provider.dart';
import 'package:lista_smart/core/providers/coin_notifier.dart';
import 'package:lista_smart/core/providers/user_notifier.dart';
import 'package:lista_smart/features/smart_coins/domain/coin_transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CoinTransaction.fromJson', () {
    test('parses valid ISO 8601 createdAt', () {
      final json = {
        'id': 'tx1',
        'description': 'Test',
        'amount': 10,
        'createdAt': '2026-06-01T12:00:00.000Z',
      };
      final tx = CoinTransaction.fromJson(json);
      expect(tx.createdAt, equals(DateTime.parse('2026-06-01T12:00:00.000Z')));
    });

    test('does not throw on invalid createdAt — returns epoch fallback (WR-02)', () {
      final json = {
        'id': 'tx1',
        'description': 'Test',
        'amount': 10,
        'createdAt': 'not-a-date',
      };
      expect(() => CoinTransaction.fromJson(json), returnsNormally);
      final tx = CoinTransaction.fromJson(json);
      expect(tx.createdAt, equals(DateTime.fromMillisecondsSinceEpoch(0)));
    });
  });

  group('CoinNotifier', () {
    test('build() returns balance 750 from user.coinBalance when no persistence', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      // Login first so userNotifierProvider has user with coinBalance=750
      container.read(userNotifierProvider.notifier).login();

      final state = container.read(coinProvider);
      expect(state.balance, equals(750));
      expect(state.transactions.length, equals(MockData.initialTransactions.length));
      expect(state.transactions.first.id, equals(MockData.initialTransactions.first.id));
    });

    test('addCoins() increments balance and inserts tx at start', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      container.read(userNotifierProvider.notifier).login();
      container.read(coinProvider.notifier).addCoins(10, 'Nota fiscal');

      final state = container.read(coinProvider);
      expect(state.balance, equals(760));
      expect(state.transactions.first.amount, equals(10));
      expect(state.transactions.first.description, equals('Nota fiscal'));
    });

    test('coin state survives restart (hydration from SharedPreferences)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container1 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      container1.read(userNotifierProvider.notifier).login();
      container1.read(coinProvider.notifier).addCoins(50, 'Nota');
      container1.dispose();

      final container2 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container2.dispose);

      final state = container2.read(coinProvider);
      expect(state.balance, equals(800)); // 750 + 50
      expect(state.transactions.first.amount, equals(50));
    });

    test('build() falls back to MockData.initialTransactions when tx JSON corrupted', () async {
      SharedPreferences.setMockInitialValues({
        'lista_smart_coins_tx': 'bad-json{',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(() => container.read(coinProvider), returnsNormally);
      final state = container.read(coinProvider);
      expect(state.transactions.length, equals(MockData.initialTransactions.length));
      expect(state.transactions.first.id, equals(MockData.initialTransactions.first.id));
    });
  });

  group('spendCoins', () {
    test('spendCoins() decrements balance and records negative transaction', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      addTearDown(container.dispose);

      // seed balance via addCoins
      container.read(coinProvider.notifier).addCoins(200, 'seed');
      final balanceBefore = container.read(coinProvider).balance;

      container.read(coinProvider.notifier).spendCoins(50, 'test spend');

      final state = container.read(coinProvider);
      expect(state.balance, equals(balanceBefore - 50));
      expect(state.transactions.first.amount, equals(-50));
      expect(state.transactions.first.description, equals('test spend'));
    });

    test('spendCoins() is no-op when balance insufficient', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      addTearDown(container.dispose);

      final balanceBefore = container.read(coinProvider).balance;
      container.read(coinProvider.notifier).spendCoins(999999, 'too much');

      expect(container.read(coinProvider).balance, equals(balanceBefore));
    });
  });
}

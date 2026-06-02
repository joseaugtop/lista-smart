import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_smart/core/persistence/shared_preferences_provider.dart';
import 'package:lista_smart/core/providers/cart_notifier.dart';
import 'package:lista_smart/features/shopping_list/domain/cart_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _testItem = CartItem(
  productId: 'p01',
  productName: 'Leite Integral',
  brand: 'Tirol',
  imageUrl: '',
  quantity: 1,
  unitPrice: 5.49,
);

const _testItem2 = CartItem(
  productId: 'p02',
  productName: 'Queijo',
  brand: 'Tirolez',
  imageUrl: '',
  quantity: 1,
  unitPrice: 38.90,
);

void main() {
  group('CartNotifier', () {
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

    test('build() returns [] when no cart persisted', () async {
      final (container, _) = await makeContainer();
      expect(container.read(cartProvider), isEmpty);
    });

    test('addItem() adds new product; addItem() with same productId increments quantity', () async {
      final (container, _) = await makeContainer();

      container.read(cartProvider.notifier).addItem(_testItem);
      expect(container.read(cartProvider).length, 1);
      expect(container.read(cartProvider).first.quantity, 1);

      // Same productId → increment
      container.read(cartProvider.notifier).addItem(_testItem);
      expect(container.read(cartProvider).length, 1);
      expect(container.read(cartProvider).first.quantity, 2);
    });

    test('removeItem() removes the matching product', () async {
      final (container, _) = await makeContainer();

      container.read(cartProvider.notifier).addItem(_testItem);
      container.read(cartProvider.notifier).addItem(_testItem2);
      container.read(cartProvider.notifier).removeItem('p01');

      final cart = container.read(cartProvider);
      expect(cart.length, 1);
      expect(cart.first.productId, equals('p02'));
    });

    test('clear() empties the cart', () async {
      final (container, _) = await makeContainer();

      container.read(cartProvider.notifier).addItem(_testItem);
      container.read(cartProvider.notifier).clear();

      expect(container.read(cartProvider), isEmpty);
    });

    test('cart survives restart (hydration from SharedPreferences)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container1 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      container1.read(cartProvider.notifier).addItem(_testItem);
      container1.dispose();

      final container2 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container2.dispose);

      final cart = container2.read(cartProvider);
      expect(cart.length, 1);
      expect(cart.first.productId, equals('p01'));
    });

    test('build() returns [] when persisted JSON is corrupted', () async {
      SharedPreferences.setMockInitialValues({
        'lista_smart_cart': 'not-valid-json{{{',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(cartProvider), isEmpty);
    });
  });
}

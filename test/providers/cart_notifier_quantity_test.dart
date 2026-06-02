import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_smart/core/persistence/shared_preferences_provider.dart';
import 'package:lista_smart/core/providers/cart_notifier.dart';
import 'package:lista_smart/features/shopping_list/domain/cart_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _item = CartItem(
  productId: 'p01',
  productName: 'Leite Integral',
  brand: 'Tirol',
  imageUrl: '',
  quantity: 1,
  unitPrice: 5.49,
);

void main() {
  group('CartNotifier — incrementQuantity / decrementQuantity', () {
    Future<ProviderContainer> makeContainer() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('incrementQuantity() increases quantity by 1', () async {
      final container = await makeContainer();
      container.read(cartProvider.notifier).addItem(_item);
      container.read(cartProvider.notifier).incrementQuantity('p01');
      expect(container.read(cartProvider).first.quantity, equals(2));
    });

    test('incrementQuantity() on non-existent item is a no-op', () async {
      final container = await makeContainer();
      container.read(cartProvider.notifier).incrementQuantity('p99');
      expect(container.read(cartProvider), isEmpty);
    });

    test('decrementQuantity() decreases quantity by 1', () async {
      final container = await makeContainer();
      container.read(cartProvider.notifier).addItem(_item);
      container.read(cartProvider.notifier).incrementQuantity('p01');
      // quantity is now 2
      container.read(cartProvider.notifier).decrementQuantity('p01');
      expect(container.read(cartProvider).first.quantity, equals(1));
    });

    test('decrementQuantity() removes item when quantity reaches 0', () async {
      final container = await makeContainer();
      container.read(cartProvider.notifier).addItem(_item);
      // quantity is 1 — decrement should remove
      container.read(cartProvider.notifier).decrementQuantity('p01');
      expect(container.read(cartProvider), isEmpty);
    });

    test('decrementQuantity() on non-existent item is a no-op', () async {
      final container = await makeContainer();
      container.read(cartProvider.notifier).decrementQuantity('p99');
      expect(container.read(cartProvider), isEmpty);
    });
  });
}

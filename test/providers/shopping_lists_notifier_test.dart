import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_smart/core/persistence/shared_preferences_provider.dart';
import 'package:lista_smart/core/providers/cart_notifier.dart';
import 'package:lista_smart/core/providers/shopping_lists_notifier.dart';
import 'package:lista_smart/features/shopping_list/domain/cart_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ShoppingListsNotifier', () {
    test('build() returns empty list when no data is persisted', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(shoppingListsProvider), isEmpty);
    });

    test('createList(), renameList(), deleteList() manage state correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      // Create
      container.read(shoppingListsProvider.notifier).createList('Churrasco');
      var lists = container.read(shoppingListsProvider);
      expect(lists, hasLength(1));
      expect(lists.first.name, equals('Churrasco'));
      final listId = lists.first.id;

      // Rename
      container.read(shoppingListsProvider.notifier).renameList(listId, 'Churrasco Fim de Ano');
      lists = container.read(shoppingListsProvider);
      expect(lists.first.name, equals('Churrasco Fim de Ano'));

      // Delete
      container.read(shoppingListsProvider.notifier).deleteList(listId);
      lists = container.read(shoppingListsProvider);
      expect(lists, isEmpty);
    });

    test('addItemToList(), removeItemFromList(), updateItemQuantityInList() manage items inside a list', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      container.read(shoppingListsProvider.notifier).createList('Supermercado');
      final listId = container.read(shoppingListsProvider).first.id;

      const item = CartItem(
        productId: 'p1',
        productName: 'Leite',
        brand: 'Leco',
        imageUrl: '',
        quantity: 2,
        unitPrice: 5.5,
      );

      // Add item
      container.read(shoppingListsProvider.notifier).addItemToList(listId, item);
      var lists = container.read(shoppingListsProvider);
      expect(lists.first.items, hasLength(1));
      expect(lists.first.items.first.productId, equals('p1'));
      expect(lists.first.items.first.quantity, equals(2));

      // Add duplicate item (should increment quantity)
      container.read(shoppingListsProvider.notifier).addItemToList(listId, item.copyWith(quantity: 3));
      lists = container.read(shoppingListsProvider);
      expect(lists.first.items, hasLength(1));
      expect(lists.first.items.first.quantity, equals(5));

      // Update quantity (change by -2)
      container.read(shoppingListsProvider.notifier).updateItemQuantityInList(listId, 'p1', -2);
      lists = container.read(shoppingListsProvider);
      expect(lists.first.items.first.quantity, equals(3));

      // Remove item
      container.read(shoppingListsProvider.notifier).removeItemFromList(listId, 'p1');
      lists = container.read(shoppingListsProvider);
      expect(lists.first.items, isEmpty);
    });

    test('loadListToCart() correctly replaces cart items', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      // Put something in cart first
      container.read(cartProvider.notifier).addItem(const CartItem(
            productId: 'p0',
            productName: 'Pão',
            brand: 'Panco',
            imageUrl: '',
            quantity: 1,
            unitPrice: 8.0,
          ));

      // Create a list with products
      container.read(shoppingListsProvider.notifier).createList('Lista Teste', [
        const CartItem(
          productId: 'p1',
          productName: 'Arroz',
          brand: 'Prato Fino',
          imageUrl: '',
          quantity: 2,
          unitPrice: 25.0,
        ),
      ]);
      final listId = container.read(shoppingListsProvider).first.id;

      // Load list to cart
      container.read(shoppingListsProvider.notifier).loadListToCart(listId);

      // Cart should be replaced
      final cartItems = container.read(cartProvider);
      expect(cartItems, hasLength(1));
      expect(cartItems.first.productId, equals('p1'));
      expect(cartItems.first.quantity, equals(2));
    });
  });
}

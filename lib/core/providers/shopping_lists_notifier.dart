import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/shared_preferences_provider.dart';
import '../../features/shopping_list/domain/cart_item.dart';
import '../../features/shopping_list/domain/shopping_list.dart';
import 'cart_notifier.dart';

class ShoppingListsNotifier extends Notifier<List<ShoppingList>> {
  static const _key = 'lista_smart_shopping_lists';

  @override
  List<ShoppingList> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => ShoppingList.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  ShoppingList? createList(String name, [List<CartItem>? items]) {
    if (name.trim().isEmpty) return null;
    final newList = ShoppingList(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      items: items ?? [],
    );
    state = [...state, newList];
    _persist();
    return newList;
  }

  void renameList(String listId, String newName) {
    if (newName.trim().isEmpty) return;
    state = state.map((list) {
      if (list.id == listId) {
        return list.copyWith(name: newName.trim());
      }
      return list;
    }).toList();
    _persist();
  }

  void deleteList(String listId) {
    state = state.where((list) => list.id != listId).toList();
    _persist();
  }

  void addItemToList(String listId, CartItem item) {
    state = state.map((list) {
      if (list.id == listId) {
        final items = List<CartItem>.from(list.items);
        final idx = items.indexWhere((e) => e.productId == item.productId);
        if (idx >= 0) {
          items[idx] = items[idx].copyWith(quantity: items[idx].quantity + item.quantity);
        } else {
          items.add(item);
        }
        return list.copyWith(items: items);
      }
      return list;
    }).toList();
    _persist();
  }

  void removeItemFromList(String listId, String productId) {
    state = state.map((list) {
      if (list.id == listId) {
        final items = list.items.where((e) => e.productId != productId).toList();
        return list.copyWith(items: items);
      }
      return list;
    }).toList();
    _persist();
  }

  void updateItemQuantityInList(String listId, String productId, int change) {
    state = state.map((list) {
      if (list.id == listId) {
        var items = List<CartItem>.from(list.items);
        final idx = items.indexWhere((e) => e.productId == productId);
        if (idx >= 0) {
          final newQty = items[idx].quantity + change;
          if (newQty <= 0) {
            items.removeAt(idx);
          } else {
            items[idx] = items[idx].copyWith(quantity: newQty);
          }
        }
        return list.copyWith(items: items);
      }
      return list;
    }).toList();
    _persist();
  }

  void loadListToCart(String listId) {
    final list = state.firstWhere((e) => e.id == listId, orElse: () => throw Exception('List not found'));
    ref.read(cartProvider.notifier).setItems(list.items.map((e) => e.copyWith()).toList());
  }

  void saveCartAsList(String name) {
    final cartItems = ref.read(cartProvider);
    createList(name, cartItems.map((e) => e.copyWith()).toList());
  }

  void _persist() {
    ref.read(sharedPreferencesProvider)
        .setString(_key, jsonEncode(state.map((e) => e.toJson()).toList()));
  }
}

final shoppingListsProvider =
    NotifierProvider<ShoppingListsNotifier, List<ShoppingList>>(ShoppingListsNotifier.new);

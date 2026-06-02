import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/shared_preferences_provider.dart';
import '../../features/shopping_list/domain/cart_item.dart';

class CartNotifier extends Notifier<List<CartItem>> {
  static const _key = 'lista_smart_cart';

  @override
  List<CartItem> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  void addItem(CartItem item) {
    final idx = state.indexWhere((e) => e.productId == item.productId);
    if (idx >= 0) {
      state = [
        ...state.sublist(0, idx),
        state[idx].copyWith(quantity: state[idx].quantity + 1),
        ...state.sublist(idx + 1),
      ];
    } else {
      state = [...state, item];
    }
    _persist();
  }

  void removeItem(String productId) {
    state = state.where((e) => e.productId != productId).toList();
    _persist();
  }

  void clear() {
    state = [];
    _persist();
  }

  void incrementQuantity(String productId) {
    final idx = state.indexWhere((item) => item.productId == productId);
    if (idx < 0) return;
    state = [
      ...state.sublist(0, idx),
      state[idx].copyWith(quantity: state[idx].quantity + 1),
      ...state.sublist(idx + 1),
    ];
    _persist();
  }

  void decrementQuantity(String productId) {
    final idx = state.indexWhere((item) => item.productId == productId);
    if (idx < 0) return;
    if (state[idx].quantity <= 1) {
      removeItem(productId);
      return;
    }
    state = [
      ...state.sublist(0, idx),
      state[idx].copyWith(quantity: state[idx].quantity - 1),
      ...state.sublist(idx + 1),
    ];
    _persist();
  }

  void _persist() {
    ref.read(sharedPreferencesProvider)
        .setString(_key, jsonEncode(state.map((e) => e.toJson()).toList()));
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

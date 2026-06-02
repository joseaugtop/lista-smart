import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/shared_preferences_provider.dart';

class FavoritesNotifier extends Notifier<List<String>> {
  static const _key = 'lista_smart_favorites';

  @override
  List<String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getStringList(_key) ?? [];
  }

  void toggle(String productId) {
    if (state.contains(productId)) {
      state = state.where((id) => id != productId).toList();
    } else {
      state = [...state, productId];
    }
    ref.read(sharedPreferencesProvider).setStringList(_key, state);
  }

  bool isFavorite(String productId) => state.contains(productId);
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, List<String>>(FavoritesNotifier.new);

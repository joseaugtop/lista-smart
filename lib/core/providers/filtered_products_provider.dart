import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/domain/product.dart';
import 'favorites_notifier.dart';
import 'products_provider.dart';
import 'search_query_notifier.dart';
import 'show_favorites_only_notifier.dart';

final filteredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(productsProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final showFavoritesOnly = ref.watch(showFavoritesOnlyProvider);
  final favorites = ref.watch(favoritesProvider);

  var result = products;

  if (showFavoritesOnly) {
    result = result.where((p) => favorites.contains(p.id)).toList();
  }

  if (query.isEmpty) return result;

  return result
      .where((p) =>
          p.name.toLowerCase().contains(query) ||
          p.brand.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query))
      .toList();
});

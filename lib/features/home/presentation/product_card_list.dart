import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/providers/favorites_notifier.dart';
import '../../../features/profile/domain/product.dart';
import '../../../routing/app_routes.dart';

class ProductCardList extends ConsumerWidget {
  const ProductCardList({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(
      favoritesProvider.select((favs) => favs.contains(product.id)),
    );
    final priceFormatted = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    ).format(product.averagePrice);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.productDetailPath(product.id)),
      child: Container(
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(
            color: context.appColors.surfaceElevated,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(AppSizes.spacingS),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
              child: SizedBox(
                width: 64,
                height: 64,
                child: product.imageUrl.isNotEmpty
                    ? Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _PlaceholderIcon(),
                      )
                    : _PlaceholderIcon(),
              ),
            ),
            const SizedBox(width: AppSizes.spacingS),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      color: context.appColors.textMain,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.brand,
                    style: TextStyle(
                      color: context.appColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    priceFormatted,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Favorite toggle
            GestureDetector(
              onTap: () =>
                  ref.read(favoritesProvider.notifier).toggle(product.id),
              child: Container(
                width: 36,
                height: 36,
                decoration: isFavorite
                    ? BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                alignment: Alignment.center,
                child: Icon(
                  LucideIcons.star,
                  color: isFavorite
                      ? AppColors.primary
                      : context.appColors.textSecondary,
                  size: 20,
                  semanticLabel: isFavorite
                      ? 'Remover dos favoritos'
                      : 'Adicionar aos favoritos',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appColors.surfaceElevated,
      child: Center(
        child: Icon(
          LucideIcons.packageOpen,
          color: context.appColors.textSecondary,
          size: 28,
        ),
      ),
    );
  }
}

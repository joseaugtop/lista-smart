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

class ProductCardGrid extends ConsumerWidget {
  const ProductCardGrid({required this.product, super.key});

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
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          border: Border.all(
            color: context.appColors.surfaceElevated,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image area
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.radiusL),
                ),
                child: ColoredBox(
                  color: context.appColors.surfaceElevated,
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => _PlaceholderIcon(),
                        )
                      : _PlaceholderIcon(),
                ),
              ),
            ),
            // Info area
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.spacingS),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        color: context.appColors.textMain,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.brand,
                      style: TextStyle(
                        color: context.appColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            priceFormatted,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => ref
                              .read(favoritesProvider.notifier)
                              .toggle(product.id),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: isFavorite
                                ? BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  )
                                : null,
                            alignment: Alignment.center,
                            child: Icon(
                              LucideIcons.star,
                              color: isFavorite
                                  ? AppColors.primary
                                  : context.appColors.textSecondary,
                              size: 16,
                              semanticLabel: isFavorite
                                  ? 'Remover dos favoritos'
                                  : 'Adicionar aos favoritos',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
          size: 40,
        ),
      ),
    );
  }
}

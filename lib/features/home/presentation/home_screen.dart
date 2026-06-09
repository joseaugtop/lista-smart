import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/providers/filtered_products_provider.dart';
import '../../../core/providers/search_query_notifier.dart';
import '../../../core/providers/show_favorites_only_notifier.dart';
import '../../../core/providers/user_notifier.dart';
import '../../../core/providers/view_mode_notifier.dart';
import '../../../routing/app_routes.dart';
import 'product_card_grid.dart';
import 'product_card_list.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts[0].length >= 2) return parts[0].substring(0, 2).toUpperCase();
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = ref.watch(filteredProductsProvider);
    final viewMode = ref.watch(viewModeProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final showFavOnly = ref.watch(showFavoritesOnlyProvider);
    final user = ref.watch(userNotifierProvider);
    final initials = _initials(user?.name ?? 'JA');

    return Scaffold(
      backgroundColor: context.appColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: context.appColors.background,
            leading: GestureDetector(
              onTap: () => context.push(AppRoutes.profile),
              child: Container(
                margin: const EdgeInsets.all(AppSizes.spacingS),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: TextStyle(
                    color: context.appColors.background,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            title: const Text('Home'),
            actions: [
              IconButton(
                icon: Icon(
                  LucideIcons.star,
                  color: showFavOnly
                      ? AppColors.primary
                      : context.appColors.textSecondary,
                ),
                tooltip: showFavOnly
                    ? 'Mostrar todos os produtos'
                    : 'Mostrar apenas favoritos',
                onPressed: () =>
                    ref.read(showFavoritesOnlyProvider.notifier).toggle(),
              ),
              IconButton(
                icon: Icon(
                  LucideIcons.layoutGrid,
                  color: viewMode == ViewMode.grid
                      ? AppColors.primary
                      : context.appColors.textSecondary,
                ),
                tooltip: 'Exibir em grade',
                onPressed: () =>
                    ref.read(viewModeProvider.notifier).setGrid(),
              ),
              IconButton(
                icon: Icon(
                  LucideIcons.list,
                  color: viewMode == ViewMode.list
                      ? AppColors.primary
                      : context.appColors.textSecondary,
                ),
                tooltip: 'Exibir em lista',
                onPressed: () =>
                    ref.read(viewModeProvider.notifier).setList(),
              ),
            ],
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickySearchBarDelegate(
              child: ColoredBox(
                color: context.appColors.background,
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.spacingS),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: context.appColors.textMain),
                    onChanged: (v) =>
                        ref.read(searchQueryProvider.notifier).update(v),
                    decoration: InputDecoration(
                      hintText: 'Buscar produtos...',
                      hintStyle:
                          TextStyle(color: context.appColors.textSecondary),
                      prefixIcon: Icon(
                        LucideIcons.search,
                        color: context.appColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: context.appColors.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusM),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusM),
                        borderSide:
                            const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (filteredProducts.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      showFavOnly ? LucideIcons.star : LucideIcons.search,
                      size: 48,
                      color: context.appColors.textSecondary,
                    ),
                    const SizedBox(height: AppSizes.spacingM),
                    Text(
                      showFavOnly
                          ? 'Nenhum favorito ainda'
                          : 'Nenhum produto encontrado para "$searchQuery"',
                      style:
                          TextStyle(color: context.appColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    if (showFavOnly) ...[
                      const SizedBox(height: AppSizes.spacingS),
                      Text(
                        'Toque na estrela em um produto para favoritá-lo',
                        style: TextStyle(
                          color: context.appColors.textSecondary,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            )
          else if (viewMode == ViewMode.grid)
            SliverPadding(
              padding: const EdgeInsets.all(AppSizes.spacingS),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSizes.spacingS,
                  crossAxisSpacing: AppSizes.spacingS,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      ProductCardGrid(product: filteredProducts[index]),
                  childCount: filteredProducts.length,
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacingM,
                    vertical: AppSizes.spacingS / 2,
                  ),
                  child: ProductCardList(product: filteredProducts[index]),
                ),
                childCount: filteredProducts.length,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(AppRoutes.scanner),
        backgroundColor: AppColors.primary,
        foregroundColor: context.appColors.background,
        tooltip: 'Escanear nota fiscal',
        child: const Icon(LucideIcons.scanLine),
      ),
    );
  }
}

class _StickySearchBarDelegate extends SliverPersistentHeaderDelegate {
  const _StickySearchBarDelegate({required this.child});
  final Widget child;

  @override
  double get minExtent => 64;

  @override
  double get maxExtent => 64;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) =>
      child;

  @override
  bool shouldRebuild(_StickySearchBarDelegate old) => old.child != child;
}

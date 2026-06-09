import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/providers/cart_notifier.dart';
import '../../../core/providers/coin_notifier.dart';
import '../../../core/providers/fuel_toggle_notifier.dart';
import '../../../routing/app_routes.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$', decimalDigits: 2);

const _comparisonCoinCost = 50;

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  bool _loadingComparison = false;

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.surface,
        title: Text('Limpar carrinho?',
            style: TextStyle(color: context.appColors.textMain)),
        content: Text('Todos os itens serão removidos.',
            style: TextStyle(color: context.appColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Manter Itens'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: context.appColors.textMain,
            ),
            child: const Text('Limpar Carrinho'),
          ),
        ],
      ),
    );
    if (confirmed == true) ref.read(cartProvider.notifier).clear();
  }

  Future<void> _compareWithLoading() async {
    final coinBalance = ref.read(coinProvider).balance;

    if (coinBalance < _comparisonCoinCost) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saldo insuficiente de Smart Coins'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _loadingComparison = true);
    // Deduct coins and simulate loading
    ref.read(coinProvider.notifier).spendCoins(_comparisonCoinCost, 'Comparação de supermercados');
    await Future<void>.delayed(const Duration(milliseconds: 1600));

    if (!mounted) return;
    setState(() => _loadingComparison = false);
    context.push(AppRoutes.comparisonResult);
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final fuelToggle = ref.watch(fuelToggleProvider);
    final coinBalance = ref.watch(coinProvider).balance;
    final theme = Theme.of(context).textTheme;

    if (cart.isEmpty) {
      return Scaffold(
        backgroundColor: context.appColors.background,
        appBar: AppBar(
          backgroundColor: context.appColors.background,
          title: Text('Minha Lista',
              style: TextStyle(color: context.appColors.textMain)),
        ),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.shoppingCart,
                    size: 64, color: context.appColors.textSecondary),
                const SizedBox(height: AppSizes.spacingM),
                Text('Sua lista está vazia',
                    style: theme.headlineSmall
                        ?.copyWith(color: context.appColors.textMain)),
                const SizedBox(height: AppSizes.spacingS),
                Text(
                  'Adicione produtos na tela Home',
                  style: theme.bodyMedium
                      ?.copyWith(color: context.appColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final total =
        cart.fold<double>(0.0, (sum, i) => sum + i.unitPrice * i.quantity);
    final hasEnoughCoins = coinBalance >= _comparisonCoinCost;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: context.appColors.background,
          appBar: AppBar(
            backgroundColor: context.appColors.background,
            title: Text('Minha Lista',
                style: TextStyle(color: context.appColors.textMain)),
            actions: [
              // Coin balance chip
              Container(
                margin: const EdgeInsets.only(right: AppSizes.spacingXS),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacingS, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.coins,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '$coinBalance',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(LucideIcons.trash2,
                    color: context.appColors.textMain),
                tooltip: 'Limpar carrinho',
                onPressed: _confirmClear,
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSizes.spacingM),
                    itemCount: cart.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSizes.spacingS),
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: context.appColors.surface.withValues(alpha: 0.7),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusL),
                          border: Border.all(
                            color: context.appColors.glassBorder,
                            width: 1.0,
                          ),
                        ),
                        padding: const EdgeInsets.all(AppSizes.spacingM),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusS),
                              child: Image.network(
                                item.imageUrl,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  LucideIcons.packageOpen,
                                  size: 64,
                                  color: context.appColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSizes.spacingM),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: theme.titleMedium
                                        ?.copyWith(color: context.appColors.textMain),
                                  ),
                                  Text(
                                    item.brand,
                                    style: theme.bodySmall?.copyWith(
                                        color: context.appColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: IconButton(
                                    icon: Icon(LucideIcons.minus,
                                        color: context.appColors.textMain),
                                    onPressed: () => ref
                                        .read(cartProvider.notifier)
                                        .decrementQuantity(item.productId),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                                Text('${item.quantity}',
                                    style: theme.bodyMedium?.copyWith(
                                        color: context.appColors.textMain)),
                                SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: IconButton(
                                    icon: Icon(LucideIcons.plus,
                                        color: context.appColors.textMain),
                                    onPressed: () => ref
                                        .read(cartProvider.notifier)
                                        .incrementQuantity(item.productId),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                                SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: IconButton(
                                    icon: Icon(LucideIcons.x,
                                        color: context.appColors.textSecondary),
                                    onPressed: () => ref
                                        .read(cartProvider.notifier)
                                        .removeItem(item.productId),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: context.appColors.surface,
                    border: Border(
                      top: BorderSide(
                          color: context.appColors.glassBorder),
                    ),
                  ),
                  padding: const EdgeInsets.all(AppSizes.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Considerar deslocamento',
                                  style: theme.bodyMedium
                                      ?.copyWith(color: context.appColors.textMain),
                                ),
                                Text(
                                  'Fiat Uno · 12 km/L · R\$ 6,50/L',
                                  style: theme.bodySmall?.copyWith(
                                      color: context.appColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            activeColor: AppColors.primary,
                            value: fuelToggle,
                            onChanged: (_) => ref
                                .read(fuelToggleProvider.notifier)
                                .toggle(),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.spacingS),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total estimado',
                              style: theme.bodySmall?.copyWith(
                                  color: context.appColors.textSecondary)),
                          Text(
                            _brl.format(total),
                            style: theme.titleMedium?.copyWith(
                              color: context.appColors.textMain,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.spacingM),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _loadingComparison
                              ? null
                              : _compareWithLoading,
                          style: FilledButton.styleFrom(
                            backgroundColor: hasEnoughCoins
                                ? AppColors.primary
                                : context.appColors.surfaceElevated,
                            foregroundColor: hasEnoughCoins
                                ? context.appColors.background
                                : context.appColors.textSecondary,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.spacingM),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusL),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Comparar Supermercados'),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.coins,
                                    size: 13,
                                    color: hasEnoughCoins
                                        ? context.appColors.background
                                        : context.appColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$_comparisonCoinCost Smart Coins',
                                    style: const TextStyle(fontSize: 11),
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
              ],
            ),
          ),
        ),
        // Loading overlay
        if (_loadingComparison)
          Container(
            color: Colors.black.withValues(alpha: 0.6),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(AppSizes.spacingL),
                decoration: BoxDecoration(
                  color: context.appColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusL),
                  border: Border.all(
                      color: context.appColors.glassBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                        color: AppColors.primary),
                    const SizedBox(height: AppSizes.spacingM),
                    Text(
                      'Comparando preços...',
                      style: TextStyle(color: context.appColors.textMain),
                    ),
                    const SizedBox(height: AppSizes.spacingS),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.coins,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '$_comparisonCoinCost Smart Coins debitados',
                          style: TextStyle(
                            color: context.appColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/providers/cart_notifier.dart';
import '../../../core/providers/fuel_toggle_notifier.dart';
import '../../../core/providers/user_notifier.dart';
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
        backgroundColor: AppColors.surface,
        title: const Text('Limpar carrinho?',
            style: TextStyle(color: AppColors.textMain)),
        content: const Text('Todos os itens serão removidos.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Manter Itens'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textMain,
            ),
            child: const Text('Limpar Carrinho'),
          ),
        ],
      ),
    );
    if (confirmed == true) ref.read(cartProvider.notifier).clear();
  }

  Future<void> _compareWithLoading() async {
    final user = ref.read(userNotifierProvider);
    final balance = user?.coinBalance ?? 0;

    if (balance < _comparisonCoinCost) {
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
    ref.read(userNotifierProvider.notifier).spendCoins(_comparisonCoinCost);
    await Future<void>.delayed(const Duration(milliseconds: 1600));

    if (!mounted) return;
    setState(() => _loadingComparison = false);
    context.push(AppRoutes.comparisonResult);
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final fuelToggle = ref.watch(fuelToggleProvider);
    final user = ref.watch(userNotifierProvider);
    final theme = Theme.of(context).textTheme;

    if (cart.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: const Text('Minha Lista',
              style: TextStyle(color: AppColors.textMain)),
        ),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.shoppingCart,
                    size: 64, color: AppColors.textSecondary),
                const SizedBox(height: AppSizes.spacingM),
                Text('Sua lista está vazia',
                    style: theme.headlineSmall
                        ?.copyWith(color: AppColors.textMain)),
                const SizedBox(height: AppSizes.spacingS),
                Text(
                  'Adicione produtos na tela Home',
                  style: theme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final total =
        cart.fold<double>(0.0, (sum, i) => sum + i.unitPrice * i.quantity);
    final coinBalance = user?.coinBalance ?? 0;
    final hasEnoughCoins = coinBalance >= _comparisonCoinCost;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            title: const Text('Minha Lista',
                style: TextStyle(color: AppColors.textMain)),
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
                icon: const Icon(LucideIcons.trash2,
                    color: AppColors.textMain),
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
                          color: AppColors.surface.withValues(alpha: 0.7),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusL),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
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
                                errorBuilder: (_, __, ___) => const Icon(
                                  LucideIcons.packageOpen,
                                  size: 64,
                                  color: AppColors.textSecondary,
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
                                        ?.copyWith(color: AppColors.textMain),
                                  ),
                                  Text(
                                    item.brand,
                                    style: theme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary),
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
                                    icon: const Icon(LucideIcons.minus,
                                        color: AppColors.textMain),
                                    onPressed: () => ref
                                        .read(cartProvider.notifier)
                                        .decrementQuantity(item.productId),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                                Text('${item.quantity}',
                                    style: theme.bodyMedium?.copyWith(
                                        color: AppColors.textMain)),
                                SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: IconButton(
                                    icon: const Icon(LucideIcons.plus,
                                        color: AppColors.textMain),
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
                                    icon: const Icon(LucideIcons.x,
                                        color: AppColors.textSecondary),
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
                    color: AppColors.surface,
                    border: Border(
                      top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1)),
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
                                      ?.copyWith(color: AppColors.textMain),
                                ),
                                Text(
                                  'Fiat Uno · 12 km/L · R\$ 6,50/L',
                                  style: theme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary),
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
                                  color: AppColors.textSecondary)),
                          Text(
                            _brl.format(total),
                            style: theme.titleMedium?.copyWith(
                              color: AppColors.textMain,
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
                                : AppColors.surfaceElevated,
                            foregroundColor: hasEnoughCoins
                                ? AppColors.background
                                : AppColors.textSecondary,
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
                                        ? AppColors.background
                                        : AppColors.textSecondary,
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
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusL),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                        color: AppColors.primary),
                    const SizedBox(height: AppSizes.spacingM),
                    Text(
                      'Comparando preços...',
                      style: TextStyle(color: AppColors.textMain),
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
                          style: const TextStyle(
                            color: AppColors.textSecondary,
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

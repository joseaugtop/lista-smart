import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/providers/cart_notifier.dart';
import '../../../core/providers/coin_notifier.dart';
import '../../../core/providers/fuel_toggle_notifier.dart';
import '../../../core/providers/shopping_lists_notifier.dart';
import '../../../routing/app_routes.dart';
import '../domain/shopping_list.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$', decimalDigits: 2);
const _comparisonCoinCost = 50;

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  String? _selectedListId;

  Future<void> _shareList(ShoppingList list) async {
    final buffer = StringBuffer();
    buffer.writeln('*Lista de Compras: ${list.name}*');
    for (final item in list.items) {
      buffer.writeln('- ${item.quantity}x ${item.productName} (${item.brand})');
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lista copiada para a área de transferência!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _renameListDialog(ShoppingList list) async {
    final textController = TextEditingController(text: list.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.surface,
        title: Text('Renomear Lista', style: TextStyle(color: context.appColors.textMain)),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: TextStyle(color: context.appColors.textMain),
          decoration: InputDecoration(
            hintText: 'Nome da lista',
            hintStyle: TextStyle(color: context.appColors.textSecondary),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, textController.text),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: context.appColors.background,
            ),
            child: const Text('Renomear'),
          ),
        ],
      ),
    );

    if (newName != null && newName.trim().isNotEmpty) {
      ref.read(shoppingListsProvider.notifier).renameList(list.id, newName.trim());
    }
  }

  Future<void> _confirmDeleteList(ShoppingList list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.surface,
        title: Text('Excluir lista?', style: TextStyle(color: context.appColors.textMain)),
        content: Text('A lista "${list.name}" será excluída permanentemente.', style: TextStyle(color: context.appColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: context.appColors.textMain,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(shoppingListsProvider.notifier).deleteList(list.id);
      setState(() {
        _selectedListId = null;
      });
    }
  }

  Widget _buildListDetailScreen(BuildContext context, String listId) {
    final lists = ref.watch(shoppingListsProvider);
    final list = lists.firstWhere((e) => e.id == listId, orElse: () => const ShoppingList(id: '', name: '', items: []));

    if (list.id.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedListId = null;
        });
      });
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context).textTheme;
    final total = list.items.fold<double>(0.0, (sum, i) => sum + i.unitPrice * i.quantity);

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: context.appColors.textMain),
          onPressed: () {
            setState(() {
              _selectedListId = null;
            });
          },
        ),
        title: Text(list.name, style: TextStyle(color: context.appColors.textMain)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.shoppingCart, color: AppColors.primary),
            tooltip: 'Carregar no Carrinho',
            onPressed: () {
              ref.read(shoppingListsProvider.notifier).loadListToCart(list.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Itens da lista "${list.name}" carregados no carrinho!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(LucideIcons.share2, color: context.appColors.textMain),
            tooltip: 'Compartilhar',
            onPressed: () => _shareList(list),
          ),
          IconButton(
            icon: Icon(LucideIcons.edit3, color: context.appColors.textMain),
            tooltip: 'Renomear',
            onPressed: () => _renameListDialog(list),
          ),
          IconButton(
            icon: Icon(LucideIcons.trash2, color: context.appColors.textMain),
            tooltip: 'Excluir',
            onPressed: () => _confirmDeleteList(list),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: list.items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.clipboardList, size: 64, color: context.appColors.textSecondary),
                          const SizedBox(height: AppSizes.spacingM),
                          Text('Sua lista está vazia',
                              style: theme.headlineSmall?.copyWith(color: context.appColors.textMain)),
                          const SizedBox(height: AppSizes.spacingS),
                          Text('Adicione produtos pelas telas de detalhes',
                              style: theme.bodyMedium?.copyWith(color: context.appColors.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSizes.spacingM),
                      itemCount: list.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.spacingS),
                      itemBuilder: (context, index) {
                        final item = list.items[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: context.appColors.surface.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(AppSizes.radiusL),
                            border: Border.all(
                              color: context.appColors.glassBorder,
                              width: 1.0,
                            ),
                          ),
                          padding: const EdgeInsets.all(AppSizes.spacingM),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppSizes.radiusS),
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
                                      style: theme.titleMedium?.copyWith(color: context.appColors.textMain),
                                    ),
                                    Text(
                                      item.brand,
                                      style: theme.bodySmall?.copyWith(color: context.appColors.textSecondary),
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
                                      icon: Icon(LucideIcons.minus, color: context.appColors.textMain),
                                      onPressed: () => ref
                                          .read(shoppingListsProvider.notifier)
                                          .updateItemQuantityInList(list.id, item.productId, -1),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                  Text('${item.quantity}',
                                      style: theme.bodyMedium?.copyWith(color: context.appColors.textMain)),
                                  SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: IconButton(
                                      icon: Icon(LucideIcons.plus, color: context.appColors.textMain),
                                      onPressed: () => ref
                                          .read(shoppingListsProvider.notifier)
                                          .updateItemQuantityInList(list.id, item.productId, 1),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: IconButton(
                                      icon: Icon(LucideIcons.x, color: context.appColors.textSecondary),
                                      onPressed: () => ref
                                          .read(shoppingListsProvider.notifier)
                                          .removeItemFromList(list.id, item.productId),
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
                  top: BorderSide(color: context.appColors.glassBorder),
                ),
              ),
              padding: const EdgeInsets.all(AppSizes.spacingM),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total estimado', style: theme.bodySmall?.copyWith(color: context.appColors.textSecondary)),
                  Text(
                    _brl.format(total),
                    style: theme.titleMedium?.copyWith(
                      color: context.appColors.textMain,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedListId != null) {
      return _buildListDetailScreen(context, _selectedListId!);
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.appColors.background,
        appBar: AppBar(
          backgroundColor: context.appColors.background,
          title: Text('Lista de Compras',
              style: TextStyle(color: context.appColors.textMain)),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: context.appColors.textSecondary,
            tabs: const [
              Tab(text: 'Meu Carrinho'),
              Tab(text: 'Minhas Listas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const _ActiveCartTab(),
            _CustomListsTab(
              onSelectList: (id) {
                setState(() {
                  _selectedListId = id;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveCartTab extends ConsumerStatefulWidget {
  const _ActiveCartTab();

  @override
  ConsumerState<_ActiveCartTab> createState() => _ActiveCartTabState();
}

class _ActiveCartTabState extends ConsumerState<_ActiveCartTab> {
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

  Future<void> _saveCartAsListDialog() async {
    final textController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.surface,
        title: Text('Salvar Carrinho como Lista', style: TextStyle(color: context.appColors.textMain)),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: TextStyle(color: context.appColors.textMain),
          decoration: InputDecoration(
            hintText: 'Nome da lista (ex: Compras do mês)',
            hintStyle: TextStyle(color: context.appColors.textSecondary),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, textController.text),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: context.appColors.background,
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (name != null && name.trim().isNotEmpty) {
      ref.read(shoppingListsProvider.notifier).saveCartAsList(name.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Carrinho salvo como a lista "$name"!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
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
      return Center(
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
      );
    }

    final total = cart.fold<double>(0.0, (sum, i) => sum + i.unitPrice * i.quantity);
    final hasEnoughCoins = coinBalance >= _comparisonCoinCost;

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingM, vertical: AppSizes.spacingS),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    icon: const Icon(LucideIcons.save, size: 16, color: AppColors.primary),
                    label: const Text('Salvar como Lista', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    onPressed: _saveCartAsListDialog,
                  ),
                  TextButton.icon(
                    icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
                    label: const Text('Limpar', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                    onPressed: _confirmClear,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingM),
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

class _CustomListsTab extends ConsumerStatefulWidget {
  final Function(String) onSelectList;
  const _CustomListsTab({required this.onSelectList});

  @override
  ConsumerState<_CustomListsTab> createState() => _CustomListsTabState();
}

class _CustomListsTabState extends ConsumerState<_CustomListsTab> {
  Future<void> _createNewListDialog() async {
    final textController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.surface,
        title: Text('Criar Nova Lista', style: TextStyle(color: context.appColors.textMain)),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: TextStyle(color: context.appColors.textMain),
          decoration: InputDecoration(
            hintText: 'Nome da lista (ex: Churrasco)',
            hintStyle: TextStyle(color: context.appColors.textSecondary),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, textController.text),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: context.appColors.background,
            ),
            child: const Text('Criar'),
          ),
        ],
      ),
    );

    if (name != null && name.trim().isNotEmpty) {
      ref.read(shoppingListsProvider.notifier).createList(name.trim());
    }
  }

  Future<void> _shareList(ShoppingList list) async {
    final buffer = StringBuffer();
    buffer.writeln('*Lista de Compras: ${list.name}*');
    for (final item in list.items) {
      buffer.writeln('- ${item.quantity}x ${item.productName} (${item.brand})');
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lista copiada para a área de transferência!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _renameListDialog(ShoppingList list) async {
    final textController = TextEditingController(text: list.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.surface,
        title: Text('Renomear Lista', style: TextStyle(color: context.appColors.textMain)),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: TextStyle(color: context.appColors.textMain),
          decoration: InputDecoration(
            hintText: 'Nome da lista',
            hintStyle: TextStyle(color: context.appColors.textSecondary),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, textController.text),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: context.appColors.background,
            ),
            child: const Text('Renomear'),
          ),
        ],
      ),
    );

    if (newName != null && newName.trim().isNotEmpty) {
      ref.read(shoppingListsProvider.notifier).renameList(list.id, newName.trim());
    }
  }

  Future<void> _confirmDeleteList(ShoppingList list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appColors.surface,
        title: Text('Excluir lista?', style: TextStyle(color: context.appColors.textMain)),
        content: Text('A lista "${list.name}" será excluída permanentemente.', style: TextStyle(color: context.appColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: context.appColors.textMain,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(shoppingListsProvider.notifier).deleteList(list.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lists = ref.watch(shoppingListsProvider);
    final theme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: context.appColors.background,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.spacingM),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Listas Salvas',
                  style: theme.titleMedium?.copyWith(
                    color: context.appColors.textMain,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(LucideIcons.plus, size: 16, color: AppColors.primary),
                  label: const Text('Nova Lista', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  onPressed: _createNewListDialog,
                ),
              ],
            ),
          ),
          Expanded(
            child: lists.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.clipboardList, size: 64, color: context.appColors.textSecondary),
                        const SizedBox(height: AppSizes.spacingM),
                        Text('Nenhuma lista personalizada',
                            style: theme.headlineSmall?.copyWith(color: context.appColors.textMain)),
                        const SizedBox(height: AppSizes.spacingS),
                        ElevatedButton(
                          onPressed: _createNewListDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: context.appColors.background,
                          ),
                          child: const Text('Criar Primeira Lista'),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingM),
                    itemCount: lists.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSizes.spacingS),
                    itemBuilder: (context, index) {
                      final list = lists[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: context.appColors.surface.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(AppSizes.radiusL),
                          border: Border.all(
                            color: context.appColors.glassBorder,
                            width: 1.0,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingM, vertical: 8),
                          onTap: () => widget.onSelectList(list.id),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                            foregroundColor: AppColors.primary,
                            child: const Icon(LucideIcons.list),
                          ),
                          title: Text(
                            list.name,
                            style: theme.titleMedium?.copyWith(
                              color: context.appColors.textMain,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${list.items.length} ${list.items.length == 1 ? 'item' : 'itens'}',
                            style: theme.bodySmall?.copyWith(color: context.appColors.textSecondary),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.shoppingCart, color: AppColors.primary),
                                tooltip: 'Carregar no Carrinho',
                                onPressed: () {
                                  ref.read(shoppingListsProvider.notifier).loadListToCart(list.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Carrinho carregado com a lista "${list.name}"!'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(LucideIcons.share2, color: context.appColors.textSecondary),
                                tooltip: 'Compartilhar',
                                onPressed: () => _shareList(list),
                              ),
                              IconButton(
                                icon: Icon(LucideIcons.edit2, color: context.appColors.textSecondary),
                                tooltip: 'Renomear',
                                onPressed: () => _renameListDialog(list),
                              ),
                              IconButton(
                                icon: Icon(LucideIcons.trash2, color: AppColors.error),
                                tooltip: 'Excluir',
                                onPressed: () => _confirmDeleteList(list),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

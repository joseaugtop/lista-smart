import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/providers/cart_notifier.dart';
import '../../../core/providers/prices_provider.dart';
import '../../../core/providers/products_provider.dart';
import '../../../features/profile/domain/product.dart';
import '../../../features/shopping_list/domain/cart_item.dart';
import '../../../core/providers/shopping_lists_notifier.dart';
import 'nutritional_info_bottom_sheet.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final pricesMap = ref.watch(pricesProvider);

    final Product? product = products.where((p) => p.id == productId).firstOrNull;

    if (product == null) {
      return Scaffold(
        backgroundColor: context.appColors.background,
        appBar: AppBar(title: const Text('Produto')),
        body: Center(
          child: Text(
            'Produto não encontrado.',
            style: TextStyle(color: context.appColors.textSecondary),
          ),
        ),
      );
    }

    final productPrices = pricesMap[productId] ?? {};
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    // Find lowest price supermarket
    String? lowestSupermarket;
    double? lowestPrice;
    for (final entry in productPrices.entries) {
      if (lowestPrice == null || entry.value < lowestPrice) {
        lowestPrice = entry.value;
        lowestSupermarket = entry.key;
      }
    }

    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: context.appColors.background,
        title: Text(product.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product image — tappable, full width, no crop
            GestureDetector(
              onTap: product.imageUrl.isNotEmpty
                  ? () => _showImageModal(context, product.imageUrl)
                  : null,
              child: ColoredBox(
                color: context.appColors.surfaceElevated,
                child: SizedBox(
                  width: double.infinity,
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => _PlaceholderImage(),
                        )
                      : _PlaceholderImage(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Product name & brand
                  Text(
              product.name,
              style: TextStyle(
                color: context.appColors.textMain,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.spacingXS),
            Text(
              product.brand,
              style: TextStyle(color: context.appColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: AppSizes.spacingM),

            // Metadata rows
            if (product.department.isNotEmpty)
              _MetadataRow(label: 'Departamento', value: product.department),
            _MetadataRow(label: 'Categoria', value: product.category),
            if (product.subcategory.isNotEmpty)
              _MetadataRow(label: 'Subcategoria', value: product.subcategory),
            if (product.ean.isNotEmpty)
              _MetadataRow(label: 'EAN', value: product.ean),

            const SizedBox(height: AppSizes.spacingM),

            // Price table
            if (productPrices.isNotEmpty) ...[
              Text(
                'Preços por supermercado',
                style: TextStyle(
                  color: context.appColors.textMain,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: AppSizes.spacingS),
              ...productPrices.entries.map((entry) {
                final isLowest = entry.key == lowestSupermarket;
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSizes.spacingXS),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacingM,
                    vertical: AppSizes.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: isLowest
                        ? AppColors.primary.withValues(alpha: 0.10)
                        : context.appColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    border: Border.all(
                      color: isLowest
                          ? AppColors.primary
                          : context.appColors.surfaceElevated,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          color: isLowest
                              ? AppColors.primary
                              : context.appColors.textMain,
                          fontWeight: isLowest
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      Row(
                        children: [
                          if (isLowest)
                            Container(
                              margin: const EdgeInsets.only(right: AppSizes.spacingS),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Menor',
                                style: TextStyle(
                                  color: context.appColors.background,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Text(
                            currencyFormat.format(entry.value),
                            style: TextStyle(
                              color: isLowest
                                  ? AppColors.primary
                                  : context.appColors.textMain,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              // Average price summary card
              if (productPrices.length > 1) ...[
                const SizedBox(height: AppSizes.spacingXS),
                () {
                  final avg = productPrices.values.reduce((a, b) => a + b) /
                      productPrices.length;
                  final spread = (productPrices.values.reduce(
                              (a, b) => a > b ? a : b) -
                          productPrices.values.reduce(
                              (a, b) => a < b ? a : b));
                  return Container(
                    padding: const EdgeInsets.all(AppSizes.spacingM),
                    decoration: BoxDecoration(
                      color: context.appColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.trendingDown,
                            size: 16, color: context.appColors.textSecondary),
                        const SizedBox(width: AppSizes.spacingS),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Preço médio',
                                style: TextStyle(
                                  color: context.appColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                currencyFormat.format(avg),
                                style: TextStyle(
                                  color: context.appColors.textMain,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Variação',
                              style: TextStyle(
                                color: context.appColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              currencyFormat.format(spread),
                              style: TextStyle(
                                color: context.appColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }(),
              ],
              const SizedBox(height: AppSizes.spacingM),
            ],

            // Add to cart button
            FilledButton(
              onPressed: () {
                ref.read(cartProvider.notifier).addItem(
                      CartItem(
                        productId: product.id,
                        productName: product.name,
                        brand: product.brand,
                        imageUrl: product.imageUrl,
                        quantity: 1,
                        unitPrice: lowestPrice ?? product.averagePrice,
                      ),
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} adicionado ao carrinho'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: context.appColors.background,
                padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingM),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusL),
                ),
              ),
              child: const Text('Adicionar ao Carrinho'),
            ),

            const SizedBox(height: AppSizes.spacingS),

            // Add to List button
            OutlinedButton(
              onPressed: () => _showAddToListBottomSheet(context, ref, product, lowestPrice),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingM),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusL),
                ),
              ),
              child: const Text('Adicionar à Lista...'),
            ),

            const SizedBox(height: AppSizes.spacingS),

            // Nutritional info button
            OutlinedButton(
              onPressed: product.nutritionalInfo == null
                  ? null
                  : () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => NutritionalInfoBottomSheet(
                          info: product.nutritionalInfo!,
                        ),
                      );
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: context.appColors.textMain,
                side: BorderSide(color: context.appColors.surfaceElevated),
                padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingM),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusL),
                ),
              ),
              child: const Text('Ver Tabela Nutricional'),
            ),

                  const SizedBox(height: AppSizes.spacingL),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageModal(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (_, __, ___) => _ImageFullScreen(imageUrl: imageUrl),
      ),
    );
  }
}

class _ImageFullScreen extends StatelessWidget {
  const _ImageFullScreen({required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blur layer — only covers background, not siblings above it
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // Tap outside image → close
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
          // Image + X button — Stack sized to image bounds
          Center(
            child: GestureDetector(
              onTap: () {},
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  Image.network(
                    imageUrl,
                    width: MediaQuery.of(context).size.width,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      LucideIcons.packageOpen,
                      size: 64,
                      color: Colors.white54,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.spacingM),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(AppSizes.spacingS),
                        child: const Icon(
                          LucideIcons.x,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appColors.surfaceElevated,
      child: Center(
        child: Icon(
          LucideIcons.packageOpen,
          color: context.appColors.textSecondary,
          size: 64,
        ),
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacingXS),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: context.appColors.textSecondary, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: context.appColors.textMain, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

void _showAddToListBottomSheet(
  BuildContext context,
  WidgetRef ref,
  Product product,
  double? lowestPrice,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.appColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusL)),
    ),
    builder: (context) {
      return _AddToListBottomSheetBody(
        product: product,
        lowestPrice: lowestPrice,
      );
    },
  );
}

class _AddToListBottomSheetBody extends ConsumerWidget {
  const _AddToListBottomSheetBody({
    required this.product,
    required this.lowestPrice,
  });

  final Product product;
  final double? lowestPrice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(shoppingListsProvider);
    final theme = Theme.of(context).textTheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.spacingM),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Adicionar à Lista',
                  style: theme.titleMedium?.copyWith(
                    color: context.appColors.textMain,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.plus, color: AppColors.primary),
                  tooltip: 'Nova Lista',
                  onPressed: () async {
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
                            child: const Text('Criar e Adicionar'),
                          ),
                        ],
                      ),
                    );

                    if (name != null && name.trim().isNotEmpty) {
                      final notifier = ref.read(shoppingListsProvider.notifier);
                      final newList = notifier.createList(name.trim());
                      if (newList != null) {
                        notifier.addItemToList(
                          newList.id,
                          CartItem(
                            productId: product.id,
                            productName: product.name,
                            brand: product.brand,
                            imageUrl: product.imageUrl,
                            quantity: 1,
                            unitPrice: lowestPrice ?? product.averagePrice,
                          ),
                        );
                        if (context.mounted) {
                          Navigator.pop(context); // Close bottom sheet
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.name} adicionado à lista "${newList.name}"!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          if (lists.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingXL),
              child: Center(
                child: Text(
                  'Nenhuma lista criada ainda.',
                  style: TextStyle(color: context.appColors.textSecondary),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: lists.length,
                itemBuilder: (context, index) {
                  final list = lists[index];
                  return ListTile(
                    leading: const Icon(LucideIcons.list),
                    title: Text(
                      list.name,
                      style: TextStyle(color: context.appColors.textMain),
                    ),
                    subtitle: Text(
                      '${list.items.length} ${list.items.length == 1 ? 'item' : 'itens'}',
                      style: TextStyle(color: context.appColors.textSecondary),
                    ),
                    onTap: () {
                      ref.read(shoppingListsProvider.notifier).addItemToList(
                            list.id,
                            CartItem(
                              productId: product.id,
                              productName: product.name,
                              brand: product.brand,
                              imageUrl: product.imageUrl,
                              quantity: 1,
                              unitPrice: lowestPrice ?? product.averagePrice,
                            ),
                          );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} adicionado à lista "${list.name}"!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}


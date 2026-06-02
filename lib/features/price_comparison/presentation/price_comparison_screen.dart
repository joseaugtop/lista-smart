import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/providers/comparison_results_provider.dart';
import '../../../core/providers/fuel_toggle_notifier.dart';

final _brl = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: r'R$',
  decimalDigits: 2,
);

class PriceComparisonScreen extends ConsumerWidget {
  const PriceComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(comparisonResultsProvider);
    final fuelToggle = ref.watch(fuelToggleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'Comparação de Preços',
          style: TextStyle(color: AppColors.textMain),
        ),
        iconTheme: const IconThemeData(color: AppColors.textMain),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.spacingM),
        itemCount: results.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSizes.spacingS),
        itemBuilder: (context, index) {
          final isWinner = index == 0;
          final result = results[index];

          final card = Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
              border: Border.all(
                color: isWinner
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.1),
                width: isWinner ? 2.0 : 1.0,
              ),
            ),
            padding: const EdgeInsets.all(AppSizes.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Text(
                      result.supermarket,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textMain,
                          ),
                    ),
                    const Spacer(),
                    if (isWinner)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.spacingS,
                          vertical: AppSizes.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppSizes.radiusS),
                        ),
                        child: Text(
                          'Melhor opção',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.background,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSizes.spacingS),
                // Products row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Produtos',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    Text(
                      _brl.format(result.productsCost),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMain,
                          ),
                    ),
                  ],
                ),
                // Fuel row (conditional)
                if (fuelToggle) ...[
                  const SizedBox(height: AppSizes.spacingXS),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Combustível (ida e volta)',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          Text(
                            '${result.distanceKm.toStringAsFixed(1)} km',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      Text(
                        _brl.format(result.fuelCost),
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textMain,
                                ),
                      ),
                    ],
                  ),
                ],
                Divider(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                // Total row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    Text(
                      _brl.format(result.totalCost),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isWinner
                                ? AppColors.primary
                                : AppColors.textMain,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          );

          if (isWinner) {
            return Semantics(
              label:
                  'Melhor opção: ${result.supermarket}, total ${_brl.format(result.totalCost)}',
              child: card,
            );
          }
          return card;
        },
      ),
    );
  }
}

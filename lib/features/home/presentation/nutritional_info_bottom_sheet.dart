import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../features/profile/domain/nutritional_info.dart';

class NutritionalInfoBottomSheet extends StatelessWidget {
  const NutritionalInfoBottomSheet({required this.info, super.key});

  final NutritionalInfo info;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.85,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusXL),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(top: AppSizes.spacingM),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSizes.spacingL),
                  children: [
                    Text(
                      'Informações Nutricionais',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textMain,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppSizes.spacingXS),
                    Text(
                      'Porção: ${info.servingSize}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSizes.spacingM),
                    _NutrientRow(label: 'Calorias', value: '${info.calories.toStringAsFixed(0)} kcal'),
                    _NutrientRow(label: 'Proteínas', value: '${info.protein.toStringAsFixed(1)} g'),
                    _NutrientRow(label: 'Carboidratos', value: '${info.carbs.toStringAsFixed(1)} g'),
                    _NutrientRow(label: 'Gorduras', value: '${info.fat.toStringAsFixed(1)} g'),
                    _NutrientRow(label: 'Fibras', value: '${info.fiber.toStringAsFixed(1)} g'),
                    _NutrientRow(label: 'Sódio', value: '${info.sodium.toStringAsFixed(0)} mg'),
                  ],
                ),
              ),
              // Fixed close button at bottom
              Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.spacingL,
                  AppSizes.spacingS,
                  AppSizes.spacingL,
                  AppSizes.spacingL,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.spacingM),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusL),
                      ),
                    ),
                    child: const Text('Fechar Tabela'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NutrientRow extends StatelessWidget {
  const _NutrientRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textMain,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

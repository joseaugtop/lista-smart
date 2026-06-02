import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/providers/coin_notifier.dart';

const _bronzeColor = Color(0xFFCD7F32);
const _prataColor = Color(0xFFC0C0C0);
const _ouroColor = Color(0xFFFFD700);

Color _levelColor(CoinLevel level) => switch (level) {
      CoinLevel.bronze => _bronzeColor,
      CoinLevel.prata => _prataColor,
      CoinLevel.ouro => _ouroColor,
    };

String _levelName(CoinLevel level) => switch (level) {
      CoinLevel.bronze => 'Bronze',
      CoinLevel.prata => 'Prata',
      CoinLevel.ouro => 'Ouro',
    };

int _nextLevelThreshold(CoinLevel level) => switch (level) {
      CoinLevel.bronze => 500,
      CoinLevel.prata => 1500,
      CoinLevel.ouro => 1500,
    };

class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(coinProvider);
    final level = coinLevelOf(state.balance);
    final levelColor = _levelColor(level);
    final progress = coinLevelProgress(state.balance);
    final recent = state.transactions.take(10).toList();
    final theme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Smart Coins',
            style: TextStyle(color: AppColors.textMain)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- HEADER ---
            Container(
              padding: const EdgeInsets.all(AppSizes.spacingL),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balance row
                  Row(
                    children: [
                      const Icon(LucideIcons.coins,
                          size: 32, color: AppColors.primary),
                      const SizedBox(width: AppSizes.spacingS),
                      Text(
                        '${state.balance}',
                        style: theme.headlineLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: AppSizes.spacingXS),
                      Text(
                        'Smart Coins',
                        style: theme.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacingM),
                  // Level row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.spacingS,
                            vertical: AppSizes.spacingXS),
                        decoration: BoxDecoration(
                          color: levelColor.withValues(alpha: 0.20),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusS),
                        ),
                        child: Text(
                          _levelName(level),
                          style: TextStyle(
                              color: levelColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ),
                      const Spacer(),
                      if (level == CoinLevel.ouro)
                        Text(
                          'Nível máximo atingido',
                          style: theme.bodySmall
                              ?.copyWith(color: AppColors.primary),
                        )
                      else
                        Text(
                          'Próx. nível: ${_nextLevelThreshold(level)} moedas',
                          style: theme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacingS),
                  // Animated progress bar
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: progress),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    builder: (_, value, __) => ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusS),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceElevated,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.spacingL),

            // --- PACKAGES ---
            Text(
              'Pacotes',
              style: theme.titleMedium?.copyWith(
                  color: AppColors.textMain, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.spacingS),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSizes.spacingS,
              crossAxisSpacing: AppSizes.spacingS,
              childAspectRatio: 0.72,
              children: const [
                _PackageCard(coins: 100, bonus: 0),
                _PackageCard(coins: 500, bonus: 50),
                _PackageCard(coins: 1000, bonus: 200),
              ],
            ),
            const SizedBox(height: AppSizes.spacingL),

            // --- HISTORY ---
            Text(
              'Histórico',
              style: theme.titleMedium?.copyWith(
                  color: AppColors.textMain, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.spacingS),
            if (recent.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.spacingL),
                  child: Text(
                    'Nenhuma transação ainda',
                    style: theme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recent.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSizes.spacingXS),
                itemBuilder: (context, index) {
                  final tx = recent[index];
                  final isGain = tx.amount > 0;
                  final color =
                      isGain ? AppColors.success : AppColors.error;
                  final amountText =
                      isGain ? '+${tx.amount}' : '${tx.amount}';
                  return Container(
                    padding: const EdgeInsets.all(AppSizes.spacingM),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusM),
                    ),
                    child: Row(
                      children: [
                        Icon(
                            isGain ? LucideIcons.plus : LucideIcons.minus,
                            size: 20,
                            color: color),
                        const SizedBox(width: AppSizes.spacingS),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.description,
                                style: theme.bodyMedium
                                    ?.copyWith(color: AppColors.textMain),
                              ),
                              Text(
                                DateFormat('dd/MM/yyyy')
                                    .format(tx.createdAt),
                                style: theme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          amountText,
                          style: theme.titleSmall?.copyWith(
                              color: color, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: AppSizes.spacingL),
          ],
        ),
      ),
    );
  }
}

class _PackageCard extends ConsumerWidget {
  const _PackageCard({required this.coins, required this.bonus});

  final int coins;
  final int bonus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingS),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.coins, color: AppColors.primary, size: 28),
          const SizedBox(height: AppSizes.spacingXS),
          Text(
            '$coins',
            style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
          if (bonus > 0) ...[
            const SizedBox(height: 2),
            Text(
              '+$bonus bônus',
              style: const TextStyle(color: AppColors.success, fontSize: 10),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                ref
                    .read(coinProvider.notifier)
                    .addCoins(coins + bonus, 'Pacote $coins moedas');
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('+${coins + bonus} moedas adicionadas!'),
                  backgroundColor: AppColors.success,
                ));
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(
                    vertical: AppSizes.spacingXS),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Obter', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/data/mock_data.dart';
import '../../../core/providers/coin_notifier.dart';
import '../../../routing/app_routes.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$', decimalDigits: 2);

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  late final PageController _pageController;
  late final ConfettiController _confettiController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _loading = false);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _confirmReceipt() {
    ref
        .read(coinProvider.notifier)
        .addCoins(10, AppStrings.scanReceiptDescription);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _returnHome() {
    _pageController.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final page = _pageController.page?.round() ?? 0;
        if (page > 0) {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          context.pop();
        }
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: AppColors.background,
            body: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Step1Widget(onNext: _startScan),
                _Step2Widget(onConfirm: _confirmReceipt),
                _Step3Widget(
                  controller: _confettiController,
                  onRepeat: _returnHome,
                  onHome: () => context.go(AppRoutes.home),
                ),
              ],
            ),
          ),
          if (_loading)
            Semantics(
              label: 'Processando, aguarde...',
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1 — Method selection
// ---------------------------------------------------------------------------

class _Step1Widget extends StatelessWidget {
  const _Step1Widget({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingM),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.fileSearch,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSizes.spacingS),
            Text(
              'Escanear Nota Fiscal',
              style: theme.headlineMedium?.copyWith(
                color: AppColors.textMain,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacingXS),
            Text(
              'Escolha como deseja registrar sua compra',
              style: theme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacingXL),
            _MethodCard(
              icon: LucideIcons.qrCode,
              title: 'Escanear QR Code',
              subtitle: 'Aponte para o código da nota',
              onTap: onNext,
            ),
            const SizedBox(height: AppSizes.spacingM),
            _MethodCard(
              icon: LucideIcons.camera,
              title: 'Foto do Cupom',
              subtitle: 'Tire uma foto do cupom fiscal',
              onTap: onNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingM),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: AppColors.primary),
            const SizedBox(width: AppSizes.spacingM),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.titleMedium?.copyWith(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style:
                      theme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2 — Confirm mock receipt
// ---------------------------------------------------------------------------

class _Step2Widget extends StatelessWidget {
  const _Step2Widget({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Etapa 2 de 3',
              style: theme.bodySmall?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacingL),
            const _ReceiptCard(),
            const SizedBox(height: AppSizes.spacingL),
            ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: AppSizes.spacingM),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.coins, size: 18),
                  const SizedBox(width: AppSizes.spacingS),
                  Text(
                    'Confirmar e Ganhar Moedas',
                    style: theme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
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
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard();

  // 4 products from MockData: Leite Integral, Banana Prata, Pão de Forma, Feijão Carioca
  static final _lineItems = [
    (MockData.products[0].name, MockData.products[0].averagePrice), // Leite Integral
    (MockData.products[3].name, MockData.products[3].averagePrice), // Banana Prata
    (MockData.products[9].name, MockData.products[9].averagePrice), // Pão de Forma
    (MockData.products[11].name, MockData.products[11].averagePrice), // Feijão Carioca
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final today = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy').format(today);
    final divider = Divider(
      color: Colors.white.withValues(alpha: 0.1),
      height: AppSizes.spacingL,
    );

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingL),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.store, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSizes.spacingS),
              Text(
                'Bistek Supermercados',
                style: theme.titleMedium?.copyWith(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingXS),
          Text(
            dateStr,
            style: theme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          divider,
          ..._lineItems.map(
            (item) => Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: AppSizes.spacingXS),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.$1,
                    style:
                        theme.bodyMedium?.copyWith(color: AppColors.textMain),
                  ),
                  Text(
                    _brl.format(item.$2),
                    style: theme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          divider,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: theme.titleMedium?.copyWith(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _brl.format(87.43),
                style: theme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.coins, size: 14, color: AppColors.primary),
              const SizedBox(width: AppSizes.spacingXS),
              Text(
                '+10 moedas ao confirmar',
                style: theme.bodySmall?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3 — Confetti celebration
// ---------------------------------------------------------------------------

class _Step3Widget extends StatefulWidget {
  const _Step3Widget({
    required this.controller,
    required this.onRepeat,
    required this.onHome,
  });

  final ConfettiController controller;
  final VoidCallback onRepeat;
  final VoidCallback onHome;

  @override
  State<_Step3Widget> createState() => _Step3WidgetState();
}

class _Step3WidgetState extends State<_Step3Widget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.play();
    });
  }

  // NOTE: do NOT dispose the controller here — it's owned by _ScannerScreenState
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingM),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (_, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: const Icon(
                    LucideIcons.coins,
                    size: 80,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingL),
                Text(
                  '+10 Smart Coins',
                  style: theme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.spacingS),
                Text(
                  'Nota fiscal cadastrada com sucesso!',
                  style: theme.titleMedium?.copyWith(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.spacingXS),
                Text(
                  'Obrigado por contribuir com dados de preços.',
                  style:
                      theme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.spacingXL),
                OutlinedButton(
                  onPressed: widget.onRepeat,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Escanear Outra Nota',
                    style: theme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.spacingS),
                TextButton(
                  onPressed: widget.onHome,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: const Text('Voltar para início'),
                ),
              ],
            ),
          ),
        ),
        Semantics(
          excludeSemantics: true,
          child: ConfettiWidget(
            confettiController: widget.controller,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 20,
            gravity: 0.3,
            colors: const [
              AppColors.primary,
              Color(0xFFF97316),
              Color(0xFFEC4899),
              Color(0xFFEAB308),
            ],
          ),
        ),
      ],
    );
  }
}

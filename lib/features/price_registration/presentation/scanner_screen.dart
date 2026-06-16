import 'dart:math';
import 'dart:convert';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
import 'barcode_scanner_page.dart';
import 'nfce_webview_page.dart';

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
  String? _scannedCode;
  List<Map<String, dynamic>>? _scannedProducts;
  String? _scannedStoreName;

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

  bool _processScrapedJson(String jsonStr) {
    try {
      final data = jsonDecode(jsonStr);
      if (data != null && data['products'] != null) {
        final List rawList = data['products'] as List;
        setState(() {
          _scannedProducts = rawList.map((e) => e as Map<String, dynamic>).toList();
          _scannedStoreName = data['store'] as String?;
        });
        return true;
      }
    } catch (e) {
      debugPrint("Erro ao decodificar JSON do scrape: $e");
    }
    return false;
  }

  Future<void> _scanQrCode() async {
    // 1. Abre o scanner de câmera para ler o QR Code
    final String? qrResult = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerPage(),
      ),
    );

    if (qrResult == null) return;

    setState(() {
      _scannedCode = qrResult;
    });

    // 2. Abre a WebView interna para burlar Cloudflare/Captcha
    if (!mounted) return;
    final String? htmlResult = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => NfceWebviewPage(url: qrResult),
      ),
    );

    if (htmlResult == null) return;

    setState(() {
      _loading = true;
    });

    // 3. Processa o JSON extraído localmente
    final bool success = _processScrapedJson(htmlResult);

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falha ao processar os dados da nota. Tente novamente.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _takePhotoAndScan() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (image == null) return;

    setState(() => _loading = true);

    final scannerController = MobileScannerController();
    
    try {
      final BarcodeCapture? capture = await scannerController.analyzeImage(image.path);
      
      if (capture != null && capture.barcodes.isNotEmpty && capture.barcodes.first.rawValue != null) {
        final String qrResult = capture.barcodes.first.rawValue!;
        
        setState(() {
          _scannedCode = qrResult;
          _loading = false;
        });

        // Abre a WebView interna para burlar Cloudflare/Captcha
        if (!mounted) return;
        final String? htmlResult = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) => NfceWebviewPage(url: qrResult),
          ),
        );

        if (htmlResult == null) return;

        setState(() => _loading = true);

        // Processa o JSON extraído localmente
        final bool success = _processScrapedJson(htmlResult);

        if (!mounted) return;
        setState(() => _loading = false);

        if (success) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Falha ao processar os dados da nota. Tente novamente.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } else {
        if (!mounted) return;
        setState(() => _loading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhum QR Code legível foi encontrado na foto. Tente alinhar o cupom ou use a câmera de scan direto.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao analisar a imagem: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      scannerController.dispose();
    }
  }

  void _confirmReceipt() {
    ref
        .read(coinProvider.notifier)
        .addCoins(10, AppStrings.scanReceiptDescription);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    // Play confetti after page transition completes so it fires when visible.
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _confettiController.play();
    });
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
            backgroundColor: context.appColors.background,
            body: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Step1Widget(
                  onScanQrCode: _scanQrCode,
                  onTakePhoto: _takePhotoAndScan,
                ),
                _Step2Widget(
                  onConfirm: _confirmReceipt,
                  scannedCode: _scannedCode,
                  products: _scannedProducts,
                  storeName: _scannedStoreName,
                ),
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
  const _Step1Widget({
    required this.onScanQrCode,
    required this.onTakePhoto,
  });

  final VoidCallback onScanQrCode;
  final VoidCallback onTakePhoto;

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
                color: context.appColors.textMain,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacingXS),
            Text(
              'Escolha como deseja registrar sua compra',
              style: theme.bodyMedium?.copyWith(color: context.appColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacingXL),
            _MethodCard(
              icon: LucideIcons.qrCode,
              title: 'Escanear QR Code',
              subtitle: 'Aponte para o código da nota',
              onTap: onScanQrCode,
            ),
            const SizedBox(height: AppSizes.spacingM),
            _MethodCard(
              icon: LucideIcons.camera,
              title: 'Foto do Cupom',
              subtitle: 'Tire uma foto do cupom fiscal',
              onTap: onTakePhoto,
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
          color: context.appColors.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
          border: Border.all(
            color: context.appColors.glassBorder,
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
                    color: context.appColors.textMain,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style:
                      theme.bodySmall?.copyWith(color: context.appColors.textSecondary),
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
  const _Step2Widget({
    required this.onConfirm,
    this.scannedCode,
    this.products,
    this.storeName,
  });

  final VoidCallback onConfirm;
  final String? scannedCode;
  final List<Map<String, dynamic>>? products;
  final String? storeName;

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
              style: theme.bodySmall?.copyWith(color: context.appColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacingL),
            _ReceiptCard(products: products, storeName: storeName),
            const SizedBox(height: AppSizes.spacingL),
            ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: const Color(0xFF09090B), // Alto contraste: texto escuro no botão de cor primária lima neon
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
  const _ReceiptCard({this.products, this.storeName});

  final List<Map<String, dynamic>>? products;
  final String? storeName;

  // 4 products from MockData: Leite Integral, Banana Prata, Pão de Forma, Feijão Carioca
  static final _fallbackItems = [
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
      color: context.appColors.glassBorder,
      height: AppSizes.spacingL,
    );

    // Calcula total e itens com base nos dados reais ou fallback
    final List<(String, double)> lineItems = [];
    double totalValue = 0.0;

    if (products != null && products!.isNotEmpty) {
      for (final p in products!) {
        final String name = p['name'] ?? 'Produto';
        final double price = (p['price'] as num?)?.toDouble() ?? 0.0;
        lineItems.add((name, price));
        totalValue += price;
      }
    } else {
      for (final item in _fallbackItems) {
        lineItems.add(item);
        totalValue += item.$2;
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingL),
      decoration: BoxDecoration(
        color: context.appColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        border: Border.all(
          color: context.appColors.glassBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.store, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSizes.spacingS),
              Expanded(
                child: Text(
                  storeName ?? 'Bistek Supermercados',
                  style: theme.titleMedium?.copyWith(
                    color: context.appColors.textMain,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingXS),
          Text(
            dateStr,
            style: theme.bodySmall?.copyWith(color: context.appColors.textSecondary),
          ),
          divider,
          ...lineItems.map(
            (item) => Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: AppSizes.spacingXS),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.$1,
                      style:
                          theme.bodyMedium?.copyWith(color: context.appColors.textMain),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSizes.spacingS),
                  Text(
                    _brl.format(item.$2),
                    style: theme.bodyMedium
                        ?.copyWith(color: context.appColors.textSecondary),
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
                  color: context.appColors.textMain,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _brl.format(totalValue).replaceAll(' ', ' '),
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
  // NOTE: do NOT dispose the controller here — it's owned by _ScannerScreenState
  // NOTE: play() is called from _ScannerScreenState._confirmReceipt() after page transition
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
                    color: context.appColors.textMain,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.spacingXS),
                Text(
                  'Obrigado por contribuir com dados de preços.',
                  style:
                      theme.bodyMedium?.copyWith(color: context.appColors.textSecondary),
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
                    foregroundColor: context.appColors.textSecondary,
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
            blastDirectionality: BlastDirectionality.directional,
            blastDirection: pi / 2,
            numberOfParticles: 30,
            gravity: 0.5,
            emissionFrequency: 0.05,
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

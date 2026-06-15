import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode], // Apenas QR Code para nota fiscal
    detectionSpeed: DetectionSpeed.normal,
  );

  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    // Define a janela de escaneamento centralizada (260x260 pixels)
    final double scanWindowSize = min(size.width * 0.65, 280.0);
    final scanWindow = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanWindowSize,
      height: scanWindowSize,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. O leitor de câmera do MobileScanner
          MobileScanner(
            controller: _controller,
            scanWindow: scanWindow,
            onDetect: (capture) {
              if (_hasScanned) return;
              
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                setState(() {
                  _hasScanned = true;
                });
                
                final String qrData = barcodes.first.rawValue!;
                
                // Feedback de sucesso (Vibração leve)
                _controller.stop();
                
                // Retorna o QR Code lido para a tela anterior
                Navigator.pop(context, qrData);
              }
            },
          ),

          // 2. Custom Painter do Overlay escuro com o furo centralizado
          Positioned.fill(
            child: CustomPaint(
              painter: ScannerOverlayPainter(scanWindow: scanWindow),
            ),
          ),

          // 3. Linha laser de scan animada
          ScanningLaserLine(scanWindow: scanWindow),

          // 4. Elementos de UI (Título, Botão Fechar, Botão Lanterna)
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Bar com Botão Fechar e Lanterna
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacingS,
                    vertical: AppSizes.spacingS,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: Colors.white, size: 24),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.5),
                          padding: const EdgeInsets.all(AppSizes.spacingS),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'Escanear Nota',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      ValueListenableBuilder<MobileScannerState>(
                        valueListenable: _controller,
                        builder: (context, state, child) {
                          // Só exibe a lanterna se a câmera estiver pronta/iniciada
                          if (!state.isInitialized) {
                            return const SizedBox(width: 48, height: 48);
                          }
                          
                          final isFlashOn = state.torchState == TorchState.on;
                          
                          return IconButton(
                            icon: Icon(
                              isFlashOn ? LucideIcons.flashlightOff : LucideIcons.flashlight,
                              color: Colors.white,
                              size: 24,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withOpacity(0.5),
                              padding: const EdgeInsets.all(AppSizes.spacingS),
                            ),
                            onPressed: () => _controller.toggleTorch(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Texto explicativo abaixo do scanner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingXL),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.spacingM,
                          vertical: AppSizes.spacingS,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(AppSizes.radiusL),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Text(
                          'Aponte a câmera para o QR Code da sua Nota Fiscal',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacingXL),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final double borderRadius;
  
  ScannerOverlayPainter({required this.scanWindow, this.borderRadius = 16.0});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.65)
      ..style = PaintingStyle.fill;

    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final cutOutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(scanWindow, Radius.circular(borderRadius)));

    // Subtrai o cutout do background
    final overlayPath = Path.combine(PathOperation.difference, backgroundPath, cutOutPath);
    canvas.drawPath(overlayPath, backgroundPaint);

    // Desenha as bordas da mira (cantos com estilo L neon)
    final borderPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    final borderPath = Path();
    final r = borderRadius;
    final l = 22.0; // tamanho do traço do canto

    // Canto superior esquerdo
    borderPath.moveTo(scanWindow.left, scanWindow.top + l);
    borderPath.lineTo(scanWindow.left, scanWindow.top + r);
    borderPath.arcToPoint(
      Offset(scanWindow.left + r, scanWindow.top),
      radius: Radius.circular(r),
    );
    borderPath.lineTo(scanWindow.left + l, scanWindow.top);

    // Canto superior direito
    borderPath.moveTo(scanWindow.right - l, scanWindow.top);
    borderPath.lineTo(scanWindow.right - r, scanWindow.top);
    borderPath.arcToPoint(
      Offset(scanWindow.right, scanWindow.top + r),
      radius: Radius.circular(r),
    );
    borderPath.lineTo(scanWindow.right, scanWindow.top + l);

    // Canto inferior direito
    borderPath.moveTo(scanWindow.right, scanWindow.bottom - l);
    borderPath.lineTo(scanWindow.right, scanWindow.bottom - r);
    borderPath.arcToPoint(
      Offset(scanWindow.right - r, scanWindow.bottom),
      radius: Radius.circular(r),
    );
    borderPath.lineTo(scanWindow.right - l, scanWindow.bottom);

    // Canto inferior esquerdo
    borderPath.moveTo(scanWindow.left + l, scanWindow.bottom);
    borderPath.lineTo(scanWindow.left + r, scanWindow.bottom);
    borderPath.arcToPoint(
      Offset(scanWindow.left, scanWindow.bottom - r),
      radius: Radius.circular(r),
    );
    borderPath.lineTo(scanWindow.left, scanWindow.bottom - l);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ScanningLaserLine extends StatefulWidget {
  final Rect scanWindow;
  const ScanningLaserLine({super.key, required this.scanWindow});

  @override
  State<ScanningLaserLine> createState() => _ScanningLaserLineState();
}

class _ScanningLaserLineState extends State<ScanningLaserLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final topPosition = widget.scanWindow.top + (widget.scanWindow.height * _animation.value);
        return Positioned(
          top: topPosition,
          left: widget.scanWindow.left + 12,
          width: widget.scanWindow.width - 24,
          child: Container(
            height: 2.0,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.8),
                  blurRadius: 5.0,
                  spreadRadius: 1.5,
                ),
              ],
              color: AppColors.primary,
            ),
          ),
        );
      },
    );
  }
}

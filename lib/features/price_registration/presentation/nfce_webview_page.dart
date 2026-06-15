import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/constants/app_colors.dart';

class NfceWebviewPage extends StatefulWidget {
  final String url;
  const NfceWebviewPage({super.key, required this.url});

  @override
  State<NfceWebviewPage> createState() => _NfceWebviewPageState();
}

class _NfceWebviewPageState extends State<NfceWebviewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasExtracted = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        // Utiliza um User Agent de navegador móvel real para evitar bloqueios extras do Cloudflare
        'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36'
      )
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
            });
            
            debugPrint("[WEBVIEW] Página carregada: $url");
            
            // Santa Catarina usa 'NFCe_Detalhes.aspx' (ou 'ConsultaPublicaNFCe.aspx' em outros layouts) para os itens
            final lowercaseUrl = url.toLowerCase();
            if ((lowercaseUrl.contains('consultapublicanfce.aspx') || lowercaseUrl.contains('nfce_detalhes.aspx')) && !_hasExtracted) {
              _startPolling();
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("[WEBVIEW] Erro no carregamento: ${error.description}");
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _startPolling() {
    if (_pollingTimer != null) return;
    
    debugPrint("[WEBVIEW] Iniciando polling periódico para detecção de produtos...");
    int attempts = 0;
    
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      attempts++;
      if (attempts > 20) {
        debugPrint("[WEBVIEW] Timeout de polling atingido (20s). Parando.");
        timer.cancel();
        _pollingTimer = null;
        return;
      }
      
      if (_hasExtracted) {
        timer.cancel();
        _pollingTimer = null;
        return;
      }
      
      try {
        final Object result = await _controller.runJavaScriptReturningResult(
          'document.documentElement.outerHTML'
        );
        
        String html = result.toString();
        if (html.startsWith('"') && html.endsWith('"')) {
          try {
            html = jsonDecode(html) as String;
          } catch (e) {
            html = html.substring(1, html.length - 1)
                .replaceAll(r'\"', '"')
                .replaceAll(r'\n', '\n')
                .replaceAll(r'\r', '\r')
                .replaceAll(r'\t', '\t');
          }
        }
        
        // Verifica se a tabela de resultados (produtos) ou dados da nota estão presentes
        if (html.contains('tabResult') || html.contains('txtRazaoSocial') || html.contains('totalNota')) {
          debugPrint("[WEBVIEW] Tabela de produtos detectada com sucesso na tentativa $attempts!");
          _hasExtracted = true;
          timer.cancel();
          _pollingTimer = null;
          
          if (mounted) {
            Navigator.pop(context, html);
          }
        } else {
          debugPrint("[WEBVIEW] Tabela 'tabResult' ainda não encontrada na tentativa $attempts. Aguardando...");
        }
      } catch (e) {
        debugPrint("[WEBVIEW] Erro no polling de verificação: $e");
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Validação SEFAZ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner informativo superior
            Container(
              width: double.infinity,
              color: AppColors.primary.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Resolva o captcha/verificação se solicitado, e clique em "Validar" para obter os dados.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary.withValues(alpha: 0.9),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: WebViewWidget(controller: _controller),
            ),
          ],
        ),
      ),
    );
  }
}

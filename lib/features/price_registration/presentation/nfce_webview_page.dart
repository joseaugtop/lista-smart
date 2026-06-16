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

  static const String _scrapeScript = r'''
(function() {
  var rows = document.querySelectorAll('tr');
  var products = [];
  
  for (var i = 0; i < rows.length; i++) {
    var row = rows[i];
    var cells = row.querySelectorAll('td, th');
    if (cells.length === 0) continue;
    
    var cellTexts = [];
    for (var j = 0; j < cells.length; j++) {
      cellTexts.push(cells[j].textContent.trim());
    }
    
    if (cellTexts.length === 0) continue;
    
    var firstCellLower = cellTexts[0].toLowerCase();
    
    // Pula cabeçalhos comuns (apenas se não for uma linha de produto com padrão de código)
    if (firstCellLower.indexOf('(código:') === -1) {
      var skipHeader = false;
      var headers = ['descrição', 'descriçao', 'produto', 'item'];
      for (var k = 0; k < headers.length; k++) {
        if (firstCellLower.indexOf(headers[k]) !== -1) {
          skipHeader = true;
          break;
        }
      }
      if (skipHeader) continue;
    }
    
    // Pula linhas de rodapé/totais
    var skipFooter = false;
    var footers = ['valor total', 'desconto', 'troco', 'pagamento', 'tributos', 'impostos'];
    for (var k = 0; k < footers.length; k++) {
      if (firstCellLower.indexOf(footers[k]) !== -1) {
        skipFooter = true;
        break;
      }
    }
    if (skipFooter) continue;
    
    var name = "";
    var qty = 1.0;
    var unit = "UN";
    var price = 0.0;
    
    // CASO 1: Formato simplificado / mobile de 2 colunas (ex: Santa Catarina tabResult)
    if (cells.length === 2) {
      var col1 = cells[0].textContent;
      var col2 = cells[1].textContent;
      
      var col1Clean = col1.replace(/\s+/g, ' ').trim();
      var col2Clean = col2.replace(/\s+/g, ' ').trim();
      
      var nameMatch = col1Clean.match(/^(.*?)\(Código:/i);
      var qtyMatch = col1Clean.match(/Qtde\.:\s*([\d,.]+)/i);
      var unitMatch = col1Clean.match(/UN:\s*([A-Za-z0-9]+?)(?=Vl\.?\s*Unit)/i);
      var unitValMatch = col1Clean.match(/Vl\. Unit\.:\s*([\d,.]+)/i);
      
      var totalMatch = col2Clean.match(/Vl\. Total\s*([\d,.]+)/i);
      
      if (nameMatch) {
        name = nameMatch[1].trim();
        
        if (qtyMatch) {
          var qtyStr = qtyMatch[1].replace(/\./g, '').replace(',', '.');
          var parsedQty = parseFloat(qtyStr);
          if (!isNaN(parsedQty)) qty = parsedQty;
        }
        
        if (unitMatch) {
          unit = unitMatch[1].trim();
        }
        
        if (totalMatch) {
          var priceStr = totalMatch[1].replace(/\./g, '').replace(',', '.');
          var parsedPrice = parseFloat(priceStr);
          if (!isNaN(parsedPrice)) price = parsedPrice;
        } else if (unitValMatch) {
          var uvalStr = unitValMatch[1].replace(/\./g, '').replace(',', '.');
          var parsedUval = parseFloat(uvalStr);
          if (!isNaN(parsedUval)) price = parsedUval * qty;
        }
      }
    }
    // CASO 2: Formato clássico de 4 ou mais colunas (GridView)
    else if (cells.length >= 5) {
      var isItemNumber = /^\d+$/.test(cellTexts[0]);
      if (isItemNumber && cellTexts[1].length > 2) {
        name = cellTexts[1];
        
        try {
          var qtyStr = cellTexts[2].replace(/\./g, '').replace(',', '.');
          var qtyMatch = qtyStr.match(/\d+\.?\d*/);
          if (qtyMatch) {
            qty = parseFloat(qtyMatch[0]);
          }
        } catch(e) {
          qty = 1.0;
        }
        
        unit = cellTexts[3] && cellTexts[3].length > 0 ? cellTexts[3] : "UN";
        
        try {
          var priceStr = cellTexts[cellTexts.length - 1].replace(/R\$/i, '').replace(/\s/g, '').replace(/\./g, '').replace(',', '.');
          var priceMatch = priceStr.match(/\d+\.?\d*/);
          if (priceMatch) {
            price = parseFloat(priceMatch[0]);
          }
        } catch(e) {
          price = 0.0;
        }
      } else {
        // Fallback
        for (var k = 0; k < cellTexts.length; k++) {
          var t = cellTexts[k];
          if (t.length > 5 && !name) {
            var containsForbidden = false;
            var keywords = ['cnpj', 'inscrição', 'rua', 'avenida', 'bairro', 'santa catarina'];
            for (var m = 0; m < keywords.length; m++) {
              if (t.toLowerCase().indexOf(keywords[m]) !== -1) {
                containsForbidden = true;
                break;
              }
            }
            if (!containsForbidden) {
              name = t;
            }
          }
        }
        
        var nums = [];
        for (var k = 0; k < cellTexts.length; k++) {
          var clean = cellTexts[k].replace(/R\$/i, '').replace(/\s/g, '').replace(/\./g, '').replace(',', '.');
          var valMatch = clean.match(/^\d+\.?\d*$/);
          if (valMatch) {
            var parsedVal = parseFloat(valMatch[0]);
            if (!isNaN(parsedVal)) nums.push(parsedVal);
          }
        }
        
        if (nums.length > 0) {
          qty = nums.length > 1 ? nums[0] : 1.0;
          price = nums[nums.length - 1];
        }
      }
    }
    
    if (name && price > 0) {
      name = name.replace(/\s+/g, ' ').trim();
      var containsForbiddenName = false;
      var nameKeywords = ['tributos', 'impostos', 'consumidor', 'chave de acesso', 'protocolo', 'via consumidor'];
      for (var k = 0; k < nameKeywords.length; k++) {
        if (name.toLowerCase().indexOf(nameKeywords[k]) !== -1) {
          containsForbiddenName = true;
          break;
        }
      }
      if (!containsForbiddenName) {
        products.push({
          name: name,
          qty: qty,
          unit: unit,
          price: price
        });
      }
    }
  }
  
  var storeName = "Estabelecimento Não Identificado";
  var storeElement = document.getElementById('txtRazaoSocial') || 
                      document.querySelector('.txtTopo') || 
                      document.querySelector('.header');
  if (storeElement) {
    storeName = storeElement.textContent.trim();
  }
  
  return JSON.stringify({
    status: "success",
    store: storeName,
    products: products
  });
})()
''';

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
            try {
              final Object scrapeResult = await _controller.runJavaScriptReturningResult(_scrapeScript);
              String jsonStr = scrapeResult.toString();
              if (jsonStr.startsWith('"') && jsonStr.endsWith('"')) {
                try {
                  jsonStr = jsonDecode(jsonStr) as String;
                } catch (e) {
                  jsonStr = jsonStr.substring(1, jsonStr.length - 1)
                      .replaceAll(r'\"', '"')
                      .replaceAll(r'\n', '\n')
                      .replaceAll(r'\r', '\r')
                      .replaceAll(r'\t', '\t');
                }
              }
              if (mounted) {
                Navigator.pop(context, jsonStr);
              }
            } catch (e) {
              debugPrint("[WEBVIEW] Erro ao executar scraping local: $e");
              if (mounted) {
                Navigator.pop(context);
              }
            }
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

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_smart/core/persistence/shared_preferences_provider.dart';
import 'package:lista_smart/core/providers/user_notifier.dart';
import 'package:lista_smart/features/price_registration/presentation/scanner_screen.dart';
import 'package:lista_smart/features/price_registration/presentation/barcode_scanner_page.dart';
import 'package:lista_smart/features/price_registration/presentation/nfce_webview_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<ProviderContainer> _makeContainer() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  addTearDown(container.dispose);
  // ScannerScreen needs a logged-in user for coin award
  container.read(userNotifierProvider.notifier).login();
  return container;
}

Future<void> _pumpScreen(
    WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ScannerScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    WebViewPlatform.instance = FakeWebViewPlatform();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // PREG-01: Step 1 renders QR Code and Camera method cards
  testWidgets(
    'PREG-01: Step 1 renders QR Code and Camera method cards',
    (tester) async {
      final container = await _makeContainer();
      await _pumpScreen(tester, container);

      expect(find.text('Escanear QR Code'), findsOneWidget);
      expect(find.text('Foto do Cupom'), findsOneWidget);
    },
  );

  // PREG-02: Step 2 shows receipt fields and confirm button
  testWidgets(
    'PREG-02: Step 2 shows receipt fields and confirm button',
    (tester) async {
      final container = await _makeContainer();
      await _pumpScreen(tester, container);

      // Tap a method card to trigger the 2s loading delay then advance to Step 2
      await tester.tap(find.text('Escanear QR Code'));
      await tester.pump(); // Start transition to BarcodeScannerPage
      await tester.pump(const Duration(milliseconds: 500)); // Wait for BarcodeScannerPage to build

      // Simulates barcode scanning completion by popping BarcodeScannerPage with a mock URL
      final barcodeScannerState = tester.state(find.byType(BarcodeScannerPage));
      Navigator.pop(barcodeScannerState.context, 'https://exemplo.com/consultapublicanfce.aspx?chNFe=123');
      await tester.pump(); // Start transition back and immediately push NfceWebviewPage
      await tester.pump(const Duration(milliseconds: 500)); // Wait for NfceWebviewPage to build

      // Simulates webview scraping completion by popping NfceWebviewPage with JSON payload
      final webviewState = tester.state(find.byType(NfceWebviewPage));
      Navigator.pop(webviewState.context, '{"status":"success","store":"Bistek Supermercados","products":[{"name":"Produto Teste","price":87.43,"qty":1.0,"unit":"UN"}]}');
      await tester.pumpAndSettle(); // Completes transition and page transitions to Step 2

      expect(find.text('Bistek Supermercados'), findsOneWidget);
      expect(find.text('R\$ 87,43'), findsOneWidget);
      expect(find.text('Confirmar e Ganhar Moedas'), findsOneWidget);
    },
  );

  // PREG-03: Step 3 shows ConfettiWidget and +10 Smart Coins
  testWidgets(
    'PREG-03: Step 3 shows ConfettiWidget and +10 Smart Coins',
    (tester) async {
      final container = await _makeContainer();
      await _pumpScreen(tester, container);

      // Navigate to Step 2
      await tester.tap(find.text('Escanear QR Code'));
      await tester.pump(); // Start transition to BarcodeScannerPage
      await tester.pump(const Duration(milliseconds: 500)); // Wait for BarcodeScannerPage to build

      // Simulates barcode scanning completion by popping BarcodeScannerPage with a mock URL
      final barcodeScannerState = tester.state(find.byType(BarcodeScannerPage));
      Navigator.pop(barcodeScannerState.context, 'https://exemplo.com/consultapublicanfce.aspx?chNFe=123');
      await tester.pump(); // Start transition back and immediately push NfceWebviewPage
      await tester.pump(const Duration(milliseconds: 500)); // Wait for NfceWebviewPage to build

      // Simulates webview scraping completion by popping NfceWebviewPage with JSON payload
      final webviewState = tester.state(find.byType(NfceWebviewPage));
      Navigator.pop(webviewState.context, '{"status":"success","store":"Bistek Supermercados","products":[{"name":"Produto Teste","price":87.43,"qty":1.0,"unit":"UN"}]}');
      await tester.pumpAndSettle(); // Completes transition and page transitions to Step 2

      // Confirm to advance to Step 3
      await tester.tap(find.text('Confirmar e Ganhar Moedas'));
      await tester.pumpAndSettle();

      expect(find.byType(ConfettiWidget), findsOneWidget);
      expect(find.text('+10 Smart Coins'), findsOneWidget);
    },
  );
}

// ---------------------------------------------------------------------------
// Fake WebView Implementation for testing
// ---------------------------------------------------------------------------

class FakeWebViewPlatform extends WebViewPlatform {
  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return FakeWebViewController(params);
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return FakeWebViewWidget(params);
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return FakeNavigationDelegate(params);
  }

  @override
  PlatformWebViewCookieManager createPlatformCookieManager(
    PlatformWebViewCookieManagerCreationParams params,
  ) {
    return FakeCookieManager(params);
  }
}

class FakeWebViewController extends PlatformWebViewController {
  FakeWebViewController(super.params) : super.implementation();

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setBackgroundColor(Color color) async {}

  @override
  Future<void> setUserAgent(String? userAgent) async {}

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {}

  @override
  Future<void> loadRequest(LoadRequestParams params) async {}
}

class FakeWebViewWidget extends PlatformWebViewWidget {
  FakeWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class FakeNavigationDelegate extends PlatformNavigationDelegate {
  FakeNavigationDelegate(super.params) : super.implementation();

  @override
  Future<void> setOnPageStarted(
    void Function(String url) onPageStarted,
  ) async {}

  @override
  Future<void> setOnPageFinished(
    void Function(String url) onPageFinished,
  ) async {}

  @override
  Future<void> setOnWebResourceError(
    void Function(WebResourceError error) onWebResourceError,
  ) async {}
}

class FakeCookieManager extends PlatformWebViewCookieManager {
  FakeCookieManager(super.params) : super.implementation();
}

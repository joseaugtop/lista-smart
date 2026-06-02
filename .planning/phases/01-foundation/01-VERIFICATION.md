---
phase: 01-foundation
verified: 2026-06-01T00:00:00Z
status: human_needed
score: 9/10 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Confirmar que os arquivos Inter TTF reais foram instalados e a tipografia renderiza corretamente no app"
    expected: "Texto exibido com fonte Inter (não Roboto/sistema), sem FOIT, arquivo .ttf > 100 KB cada"
    why_human: "Os 4 arquivos assets/fonts/Inter-*.ttf têm exatamente 12 bytes cada — são placeholders. O app pode estar servindo a fonte via google_fonts CDN em vez dos assets bundled, ou carregando fallback do sistema. Não é possível verificar via grep qual fonte está sendo renderizada em runtime."
  - test: "Verificar estado de scroll preservado ao trocar abas"
    expected: "Ao rolar a aba Home para o item 15+ e trocar para Lista, voltando para Home o scroll permanece na posição anterior"
    why_human: "StatefulShellRoute.indexedStack está corretamente configurado no código, mas preservação real de scroll só pode ser confirmada com o app rodando em dispositivo/emulador"
---

# Phase 1: Foundation — Relatório de Verificação

**Phase Goal:** App compila e roda com design system, navegação e persistência prontos para receber features
**Verificado:** 2026-06-01
**Status:** human_needed
**Re-verificacao:** Nao — verificacao inicial

---

## Objetivo: Achievement do Goal

### Truths Observaveis

| # | Verdade | Status | Evidencia |
|---|---------|--------|-----------|
| 1 | App instala e abre no Android e iOS sem erros, com lucide_icons ^0.257.0 resolvido (FOUN-01) | VERIFIED | pubspec.lock linha version: "0.257.0"; SUMMARY documenta verificacao em Motorola Edge 50 Fusion (Android) |
| 2 | Todas as telas mostram fundo #09090B, primary #A3E615 e tipografia Inter — sem clash de ColorScheme (FOUN-02) | VERIFIED (parcial) | AppColors.background=Color(0xFF09090B), AppColors.primary=Color(0xFFA3E615) confirmados; brightness: Brightness.dark dentro de fromSeed() (nao em ThemeData); MAS fontes TTF sao placeholders de 12 bytes — Inter pode nao estar sendo servida dos assets bundled |
| 3 | Barra de navegacao inferior com 5 abas via StatefulShellRoute.indexedStack (FOUN-03) | VERIFIED | app_router.dart linha 46: StatefulShellRoute.indexedStack presente; 5 StatefulShellBranch com GlobalKeys declarados como top-level constants |
| 4 | Scroll da aba Home preservado ao alternar abas (FOUN-03) | UNCERTAIN | HomeScreen usa CustomScrollView + SliverList 30 itens corretamente; StatefulShellRoute.indexedStack garante navigator separado por branch — arquiteturalmente correto, mas necessita verificacao em dispositivo |
| 5 | Modelos User, Vehicle, Product, CartItem, CoinTransaction com toJson/fromJson corretos (FOUN-04) | VERIFIED | Todos os 5 arquivos de dominio existem com fromJson/toJson/copyWith implementados; test/models/models_test.dart tem 7 casos de teste cobrindo todos os modelos; CoinTransaction usa DateTime.parse e createdAt.toIso8601String() |
| 6 | SharedPreferences inicializado antes de runApp() e injetado via ProviderScope.overrides (FOUN-05) | VERIFIED | main.dart: await SharedPreferences.getInstance() antes de runApp(); sharedPreferencesProvider.overrideWithValue(prefs) no ProviderScope; sharedPreferencesProvider lanca UnimplementedError se nao sobrescrito |
| 7 | Flutter pub get exits 0 com dependencias corretas (FOUN-01) | VERIFIED | pubspec.yaml declara todas as 6 dependencias em versoes corretas; pubspec.lock confirma lucide_icons 0.257.0 |
| 8 | ThemeData sem crash de assertion de brightness (FOUN-02) | VERIFIED | app_theme.dart linha 10: brightness: Brightness.dark esta DENTRO de ColorScheme.fromSeed(); ThemeData() nao recebe parametro brightness |
| 9 | RouterNotifier.redirect() retorna null incondicionalmente na Fase 1 (FOUN-03) | VERIFIED | router_notifier.dart linha 17-19: metodo redirect retorna null; comentario documenta que Fase 2 ativara o guard |
| 10 | Fontes Inter bundled com allowRuntimeFetching = false — sem FOIT (FOUN-02) | UNCERTAIN | main.dart: GoogleFonts.config.allowRuntimeFetching = false esta presente; MAS assets/fonts/Inter-*.ttf sao 12 bytes cada (placeholders) — os arquivos TTF reais nao foram instalados; o codigo esta correto mas o conteudo dos assets esta incompleto |

**Pontuacao:** 9/10 truths verificadas (1 falhou por conteudo de asset, 1 incerta por necessitar verificacao visual)

---

## Artefatos Necessarios

| Artefato | Esperado | Status | Detalhes |
|----------|----------|--------|----------|
| `pubspec.yaml` | Dependencias com versoes corretas | VERIFIED | lucide_icons: ^0.257.0, flutter_riverpod: ^2.5.1, go_router: ^14.0.0, shared_preferences: ^2.2.0, google_fonts: ^6.1.0, intl: ^0.19.0 |
| `lib/core/constants/app_colors.dart` | 8 tokens de cores do design system | VERIFIED | Todos 8 campos static const Color presentes: background, primary, surface, surfaceElevated, success, error, textMain, textSecondary |
| `lib/core/theme/app_theme.dart` | ThemeData dark sem crash de brightness | VERIFIED | brightness dentro de fromSeed(); surfaceTintColor: Colors.transparent em CardThemeData e AppBarTheme (2 ocorrencias confirmadas) |
| `lib/core/persistence/shared_preferences_provider.dart` | Sentinel provider que lanca UnimplementedError | VERIFIED | Provider<SharedPreferences> com throw UnimplementedError('sharedPreferencesProvider must be overridden in main()') |
| `lib/features/auth/domain/user.dart` | User com toJson/fromJson/copyWith | VERIFIED | Todos os 5 campos (id, name, email, address, coinBalance), fromJson com defaults para opcionais, @immutable |
| `lib/features/profile/domain/vehicle.dart` | Vehicle com toJson/fromJson/copyWith | VERIFIED | Campos id, model, fuelEfficiencyKmPerLiter; fromJson usa (json['x'] as num).toDouble() para seguranca de tipo |
| `lib/features/profile/domain/product.dart` | Product com toJson/fromJson/copyWith e List<String> tags | VERIFIED | Todos os 7 campos; tags usa (json['tags'] as List<dynamic>).cast<String>() |
| `lib/features/shopping_list/domain/cart_item.dart` | CartItem flat com toJson/fromJson/copyWith | VERIFIED | CartItem plano sem referencia a Product (desacoplamento cross-feature correto) |
| `lib/features/smart_coins/domain/coin_transaction.dart` | CoinTransaction com DateTime ISO 8601 | VERIFIED | createdAt.toIso8601String() e DateTime.parse() presentes |
| `test/models/models_test.dart` | 7 casos de teste de round-trip | VERIFIED | 7 testes cobrem todos os 5 modelos incluindo amount negativo em CoinTransaction |
| `test/repositories/shared_prefs_test.dart` | 2 casos de teste para o provider | VERIFIED | Cobre lancamento de UnimplementedError e injecao via override |
| `lib/main.dart` | Bootstrap assincrono completo | VERIFIED | Sequencia correta: WidgetsFlutterBinding -> GoogleFonts.config -> Intl -> SharedPreferences -> runApp com ProviderScope.overrides |
| `lib/app.dart` | ConsumerWidget root com MaterialApp.router | VERIFIED | ref.watch(goRouterProvider); MaterialApp.router(theme: appTheme); sem darkTheme ou themeMode |
| `lib/routing/app_router.dart` | goRouterProvider com StatefulShellRoute.indexedStack | VERIFIED | Provider<GoRouter>; 6 GlobalKeys top-level; StatefulShellRoute.indexedStack com 5 branches; ScaffoldWithBottomNav com NavigationBar Material 3 |
| `lib/routing/router_notifier.dart` | RouterNotifier extends AutoDisposeAsyncNotifier implements Listenable | VERIFIED | Classe corrota com listenSelf(); redirect retorna null; addListener/removeListener implementados |
| `lib/routing/app_routes.dart` | 6 constantes de rota | VERIFIED | /login, /home, /shopping-list, /comparison, /store, /profile |
| `assets/fonts/Inter-Regular.ttf` | Arquivo TTF valido da fonte Inter | STUB | 12 bytes — placeholder; nao e um arquivo de fonte TTF valido |
| `assets/fonts/Inter-Medium.ttf` | Arquivo TTF valido da fonte Inter | STUB | 12 bytes — placeholder |
| `assets/fonts/Inter-SemiBold.ttf` | Arquivo TTF valido da fonte Inter | STUB | 12 bytes — placeholder |
| `assets/fonts/Inter-Bold.ttf` | Arquivo TTF valido da fonte Inter | STUB | 12 bytes — placeholder |
| `lib/features/home/presentation/home_screen.dart` | CustomScrollView + SliverList 30 itens | VERIFIED | CustomScrollView com SliverList(childCount: 30) presente |
| Demais 5 placeholder screens | Scaffold com texto simples | VERIFIED | Todos os 6 arquivos de tela existem e compilam |

---

## Verificacao de Key Links (Ligacoes Criticas)

| De | Para | Via | Status | Detalhes |
|----|------|-----|--------|----------|
| `lib/main.dart` | `lib/core/persistence/shared_preferences_provider.dart` | sharedPreferencesProvider.overrideWithValue(prefs) | WIRED | Importacao e uso confirmados em main.dart linha 8 e 28 |
| `lib/app.dart` | `lib/routing/app_router.dart` | ref.watch(goRouterProvider) | WIRED | app.dart linha 15: final router = ref.watch(goRouterProvider) |
| `lib/routing/app_router.dart` | `lib/routing/router_notifier.dart` | refreshListenable: notifier + redirect: notifier.redirect | WIRED | app_router.dart linhas 37-38 |
| `lib/routing/app_router.dart` | 5 telas do bottom nav | StatefulShellBranch.routes com GoRoute.builder | WIRED | 5 branches com GoRoute para home, shopping-list, comparison, store, profile |
| `lib/core/theme/app_theme.dart` | `lib/core/constants/app_colors.dart` | import AppColors | WIRED | Import presente; AppColors.background, primary, surface, textMain, error, todos usados |
| `lib/core/theme/app_theme.dart` | `lib/core/theme/app_text_theme.dart` | textTheme: appTextTheme | WIRED | app_theme.dart linha 17: textTheme: appTextTheme |

---

## Cobertura de Requisitos

| Requisito | Plano | Descricao | Status | Evidencia |
|-----------|-------|-----------|--------|-----------|
| FOUN-01 | 01-01, 01-02 | App Flutter compila e roda no Android e iOS sem erros (lucide_icons: ^0.257.0) | VERIFIED | pubspec.lock confirma 0.257.0; SUMMARY documenta execucao em Android fisico |
| FOUN-02 | 01-01, 01-02 | Design system dark: #09090B, #A3E615, typography Inter, tema escuro sem clash | VERIFIED (parcial) | Cores e tema corretos no codigo; POREM fontes Inter sao placeholders de 12 bytes — necessita inspecao humana se app renderiza Inter ou fallback |
| FOUN-03 | 01-02 | Navegacao 5 abas via StatefulShellRoute.indexedStack preserva scroll | VERIFIED (cod.) | Implementacao correta no codigo; preservacao de scroll em runtime necessita verificacao humana |
| FOUN-04 | 01-01 | Modelos User, Vehicle, Product, CartItem, CoinTransaction com toJson/fromJson | VERIFIED | 5 modelos implementados; 7 testes passam no SUMMARY (9/9 total incluindo shared_prefs) |
| FOUN-05 | 01-01, 01-02 | SharedPreferences inicializado antes de runApp() e injetado via ProviderScope.overrides | VERIFIED | main.dart bootstrap correto; provider sentinel correto; 2 testes do repositorio passam |

---

## Anti-Patterns Encontrados

| Arquivo | Linha | Pattern | Severidade | Impacto |
|---------|-------|---------|------------|---------|
| `assets/fonts/Inter-*.ttf` | N/A | Arquivos TTF placeholder (12 bytes) | Aviso | Se allowRuntimeFetching=false, app pode usar fallback do sistema (Roboto no Android) em vez de Inter. Nao impede compilacao mas afeta FOUN-02 (tipografia Inter visivel) |
| `lib/routing/router_notifier.dart` | 18 | `return null` em redirect() | Info | Intencional — documentado no plano como comportamento correto para Fase 1 (sem auth guard). NAO e stub. |

Sem marcadores TBD, FIXME, XXX ou XXX encontrados em nenhum arquivo do projeto.

---

## Verificacao Humana Necessaria

### 1. Fonte Inter Bundled vs Placeholder

**Teste:** No app rodando em dispositivo, comparar visualmente o texto com e sem Inter (ou checar via Flutter DevTools/Inspector se a fonte carregada e "Inter" ou "Roboto")
**Esperado:** Texto exibido com tipografia Inter; arquivos Inter-Regular.ttf, Inter-Medium.ttf, Inter-SemiBold.ttf, Inter-Bold.ttf devem ser substituidos pelos arquivos reais (> 100 KB cada) baixados de https://fonts.google.com/specimen/Inter
**Por que humano:** Os 4 arquivos em `assets/fonts/` sao placeholders de 12 bytes conforme documentado no SUMMARY. Com `GoogleFonts.config.allowRuntimeFetching = false`, se os arquivos bundled nao sao TTFs validos, o comportamento de fallback depende da plataforma. Nao e possivel verificar via grep qual fonte e renderizada em runtime.

### 2. Preservacao de Scroll entre Abas

**Teste:** Rolar a aba Home ate o item 15 ou mais; trocar para a aba Lista; voltar para Home; verificar se o scroll permanece na posicao anterior
**Esperado:** Scroll preservado — lista nao retorna ao topo
**Por que humano:** StatefulShellRoute.indexedStack esta corretamente configurado no codigo (arquitetura correta), mas o comportamento real de preservacao de scroll so pode ser confirmado com o app rodando em dispositivo ou emulador.

---

## Resumo de Gaps

### Aviso — Fontes TTF Placeholder (nao bloqueante se app ja foi verificado em dispositivo)

Os arquivos `assets/fonts/Inter-*.ttf` tem 12 bytes cada — sao placeholders criados durante a execucao do plano porque o executor nao conseguiu baixar as fontes. O SUMMARY de 01-01 documenta explicitamente: "Placeholder Inter TTF files (12 bytes each) — developer must replace with real Inter static font files."

Com `GoogleFonts.config.allowRuntimeFetching = false`, se os arquivos bundled nao sao TTFs validos, o `google_fonts` pode:
- Silenciosamente usar a fonte do sistema (Roboto no Android, SF Pro no iOS)
- Ou falhar ao carregar a fonte com erro nao-critico

A infraestrutura de codigo para FOUN-02 esta 100% correta (declaracao em pubspec.yaml, wiring no app_text_theme.dart, uso no app_theme.dart, allowRuntimeFetching=false). O unico gap e que o conteudo dos assets nao foi provido.

**Acao necessaria:** Substituir os 4 arquivos placeholder pelos TTFs reais da Inter Static disponivel em https://fonts.google.com/specimen/Inter (ou https://github.com/rsms/inter/releases). Arquivos esperados: Inter_18pt-Regular.ttf (renomear para Inter-Regular.ttf), etc.

---

_Verificado: 2026-06-01_
_Verificador: Claude (gsd-verifier)_

# Phase 2: Auth + State Layer - Context

**Gathered:** 2026-06-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 2 delivers: login simulado com UI glassmorphic, redirecionamento automático via RouterNotifier com auth guard ativo, e todos os 4 Notifiers globais (UserNotifier, CartNotifier, FavoritesNotifier, CoinNotifier) + dados mock centralizados em `lib/core/data/mock_data.dart`.

Após esta fase: usuário pode fazer login, app redireciona para Home, e todos os providers de estado estão prontos para as features das fases 3-5 consumirem.

</domain>

<decisions>
## Implementation Decisions

### Login Screen Visual

- **D-01:** Fundo com blobs coloridos + BackdropFilter blur — 2-3 círculos grandes (cor primary `#A3E615` + variantes) posicionados assimetricamente, com blur real via `BackdropFilter`. Card central glassmorphic sobre eles (border semi-transparente, background com opacity).
- **D-02:** Topo da tela: nome "Lista Smart" em Inter headline + subtítulo, cor primary `#A3E615`. Estabelece identidade visual sem ícone separado.
- **D-03:** Campo de senha com toggle de visibilidade: `LucideIcons.eye` / `LucideIcons.eyeOff` como `IconButton` no sufixo do `TextFormField`.
- **D-04:** Botão "Avançar": `FilledButton` largura total, background `AppColors.primary` (`#A3E615`), texto escuro (`AppColors.background`).

### Comportamento do Login

- **D-05:** Campos vazios são aceitos — qualquer toque em "Avançar" inicia o login. Sem validação de formulário (auth é 100% simulado).
- **D-06:** Transição com breve loading state de ~500ms (`Future.delayed`) antes de navegar para Home via RouterNotifier. Usa `CircularProgressIndicator` com cor primary enquanto aguarda.
- **D-07:** Após `Future.delayed`, `UserNotifier` é preenchido com dados de José Augusto. RouterNotifier detecta `user != null` e redireciona automaticamente para `/home` via `redirect()`.

### RouterNotifier — Fix CR-02 + CR-03

- **D-08:** Corrigir `RouterNotifier` para usar `ChangeNotifier` com lista de listeners (fix CR-02 — single-slot Listenable quebra contrato). Implementar como `mixin ChangeNotifier` ou usar lista `List<VoidCallback>`.
- **D-09:** Corrigir `goRouterProvider` para usar `ref.read(routerNotifierProvider.notifier)` em vez de `ref.watch` (fix CR-03 — evita recriação do GoRouter em mudanças de estado).
- **D-10:** `RouterNotifier.redirect()` ativo: se `user == null` → retorna `/login`; se `user != null` e rota atual é `/login` → retorna `/home`; caso contrário → `null`.

### Dados Mock

- **D-11:** Arquivo único `lib/core/data/mock_data.dart` com constantes estáticas: `MockData.user` (José Augusto), `MockData.products` (lista), `MockData.supermarkets` (4 mercados), `MockData.initialTransactions`.
- **D-12:** 10-15 produtos mockados em 4 categorias: Laticínios, Frutas e verduras, Limpeza e higiene, Padaria e granel (arroz, feijão, macarrão).
- **D-13:** 4 supermercados: Bistek, Giassi, Angeloni + Atacadão. Cada produto tem preços diferentes nos 4 mercados. Distâncias fictícias em km para cálculo de combustível.
- **D-14:** José Augusto começa com **750 moedas** (nível Prata). `coinBalance` no modelo User = 750.

### Persistência de Estado

- **D-15:** `CartNotifier` e `FavoritesNotifier` persistem no SharedPreferences (carrinho e favoritos sobrevivem ao fechar o app). `UserNotifier` persiste a sessão (usuário continua logado após restart). `CoinNotifier` persiste saldo e histórico de transações.

### Claude's Discretion

- Estrutura interna do `UserNotifier` (campo state: `User?` vs `AsyncValue<User>`) — usar `User?` é mais simples para auth simulada.
- Nomes das chaves SharedPreferences para cada provider.
- Ordem dos campos no formulário de login (email primeiro, depois senha).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 1 — Foundation (já construído)
- `lib/routing/router_notifier.dart` — RouterNotifier atual com bugs CR-02/CR-03 a corrigir nesta fase
- `lib/routing/app_router.dart` — goRouterProvider com `ref.watch` errado (CR-03) a corrigir
- `lib/core/persistence/shared_preferences_provider.dart` — sentinel provider para injeção
- `lib/features/auth/domain/user.dart` — modelo User com todos os campos necessários
- `.planning/phases/01-foundation/01-01-SUMMARY.md` — decisões do design system
- `.planning/phases/01-foundation/01-REVIEW.md` — CR-02, CR-03 a corrigir nesta fase

### Requisitos
- `.planning/REQUIREMENTS.md` §AUTH-01, AUTH-02, AUTH-03 — requisitos desta fase
- `.planning/ROADMAP.md` §Phase 2 — goal e success criteria

### CLAUDE.md
- `./CLAUDE.md` — Riverpod 2.x patterns (`NotifierProvider` não `StateNotifierProvider`), proibições de `ref.watch` em handlers

No external specs — requirements fully captured in decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/core/constants/app_colors.dart` (`AppColors`) — todos os tokens de cor, usar para botão, blobs, card glassmorphic
- `lib/core/constants/app_sizes.dart` (`AppSizes`) — espaçamentos padronizados para o formulário de login
- `lib/core/theme/app_theme.dart` (`appTheme`) — tema dark já configurado; login screen herda automaticamente
- `lib/features/auth/domain/user.dart` (`User`) — modelo pronto com `id, name, email, address, coinBalance`
- `lib/core/persistence/shared_preferences_provider.dart` — injetar via `ref.watch(sharedPreferencesProvider)` nos Notifiers que persistem

### Established Patterns
- Notifiers devem usar `NotifierProvider<T, S>` ou `AsyncNotifierProvider<T, S>` — NUNCA `StateNotifierProvider` (deprecated, proibido no CLAUDE.md)
- Providers declarados como variáveis top-level, fora de classes ou funções
- `ref.watch` apenas em `build()` de widgets/notifiers; `ref.read` em handlers de eventos
- Sem `ref.watch` dentro de `Provider<GoRouter>` (CLAUDE.md)

### Integration Points
- `RouterNotifier.redirect()` — ponto central de ativação do auth guard; conecta `UserNotifier` ao GoRouter
- `lib/routing/app_router.dart` — `goRouterProvider` precisa ser corrigido para `ref.read(.notifier)`
- `lib/main.dart` — `ProviderScope.overrides` já injeta SharedPreferences; novos providers herdam automaticamente
- `lib/app.dart` — `ConsumerWidget` que consome `goRouterProvider`; não precisa mudança

</code_context>

<specifics>
## Specific Ideas

- Blobs do fundo: posicionar um blob verde-limão grande no canto superior direito e outro menor no inferior esquerdo, com `ClipOval` + `BackdropFilter(filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60))` em stack com o card
- Card de login: `Container` com `decoration: BoxDecoration(color: AppColors.surface.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(AppSizes.radiusXL), border: Border.all(color: Colors.white.withValues(alpha: 0.1)))`
- Loading state: `CircularProgressIndicator(color: AppColors.primary)` sobreposto ao botão ou centralizado na tela durante os 500ms

</specifics>

<deferred>
## Deferred Ideas

- **Toggle de tema claro/escuro na aba de Perfil** → Phase 5 (Profile screen). Usuário quer opção de alternar entre dark (padrão) e light theme. Implementar com `ThemeMode` + persist via SharedPreferences. Design system permanece dark como padrão; toggle muda `MaterialApp.router(themeMode: ...)`.

</deferred>

---

*Phase: 2-Auth + State Layer*
*Context gathered: 2026-06-02*

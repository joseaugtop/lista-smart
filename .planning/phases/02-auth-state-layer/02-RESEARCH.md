# Phase 02: Auth + State Layer - Research

**Researched:** 2026-06-01
**Domain:** Flutter Riverpod state management, GoRouter auth guard, glassmorphic UI, SharedPreferences persistence
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Login Screen Visual**
- D-01: Fundo com blobs coloridos + BackdropFilter blur — 2-3 círculos grandes (cor primary `#A3E615` + variantes) posicionados assimetricamente, com blur real via `BackdropFilter`. Card central glassmorphic sobre eles (border semi-transparente, background com opacity).
- D-02: Topo da tela: nome "Lista Smart" em Inter headline + subtítulo, cor primary `#A3E615`. Estabelece identidade visual sem ícone separado.
- D-03: Campo de senha com toggle de visibilidade: `LucideIcons.eye` / `LucideIcons.eyeOff` como `IconButton` no sufixo do `TextFormField`.
- D-04: Botão "Avançar": `FilledButton` largura total, background `AppColors.primary` (`#A3E615`), texto escuro (`AppColors.background`).

**Comportamento do Login**
- D-05: Campos vazios são aceitos — qualquer toque em "Avançar" inicia o login. Sem validação de formulário.
- D-06: Transição com breve loading state de ~500ms (`Future.delayed`) antes de navegar para Home via RouterNotifier. Usa `CircularProgressIndicator` com cor primary enquanto aguarda.
- D-07: Após `Future.delayed`, `UserNotifier` é preenchido com dados de José Augusto. RouterNotifier detecta `user != null` e redireciona automaticamente para `/home` via `redirect()`.

**RouterNotifier — Fix CR-02 + CR-03**
- D-08: Corrigir `RouterNotifier` para usar `ChangeNotifier` com lista de listeners (fix CR-02).
- D-09: Corrigir `goRouterProvider` para usar `ref.read(routerNotifierProvider.notifier)` em vez de `ref.watch` (fix CR-03).
- D-10: `RouterNotifier.redirect()` ativo: se `user == null` → retorna `/login`; se `user != null` e rota atual é `/login` → retorna `/home`; caso contrário → `null`.

**Dados Mock**
- D-11: Arquivo único `lib/core/data/mock_data.dart` com constantes estáticas: `MockData.user`, `MockData.products`, `MockData.supermarkets`, `MockData.initialTransactions`.
- D-12: 10-15 produtos mockados em 4 categorias: Laticínios, Frutas e verduras, Limpeza e higiene, Padaria e granel.
- D-13: 4 supermercados: Bistek, Giassi, Angeloni + Atacadão. Cada produto tem preços diferentes nos 4 mercados. Distâncias fictícias em km.
- D-14: José Augusto começa com 750 moedas (nível Prata). `coinBalance` no modelo User = 750.

**Persistência de Estado**
- D-15: `CartNotifier` e `FavoritesNotifier` persistem no SharedPreferences. `UserNotifier` persiste a sessão. `CoinNotifier` persiste saldo e histórico de transações.

### Claude's Discretion

- Estrutura interna do `UserNotifier` (campo state: `User?` vs `AsyncValue<User>`) — usar `User?` é mais simples para auth simulada.
- Nomes das chaves SharedPreferences para cada provider.
- Ordem dos campos no formulário de login (email primeiro, depois senha).

### Deferred Ideas (OUT OF SCOPE)

- Toggle de tema claro/escuro na aba de Perfil → Phase 5.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AUTH-01 | Usuário vê tela de login com campos email/senha estilizados (ícones Lucide, círculos desfocados de fundo) | LoginScreen glassmorphic com BackdropFilter, TextFormField com LucideIcons.mail e LucideIcons.lock confirmados em lucide_icons 0.257.0 |
| AUTH-02 | Ao pressionar "Avançar", estado global de user é preenchido instantaneamente com dados de José Augusto e app navega para Home | UserNotifier.login() via NotifierProvider, Future.delayed 500ms, RouterNotifier.redirect() detecta user != null |
| AUTH-03 | RouterNotifier redireciona para /login automaticamente se user for null | RouterNotifier com ChangeNotifier mixin, redirect() ativo, ref.read(.notifier) em goRouterProvider |
</phase_requirements>

---

## Summary

Esta fase tem dois eixos de trabalho distintos: (1) corrigir bugs de infraestrutura de roteamento (CR-02, CR-03) que já existem no código da Fase 1, e (2) implementar funcionalidade nova (LoginScreen glassmorphic, 4 Notifiers globais, dados mock, persistência). Os bugs CR-02 e CR-03 são críticos e devem ser corrigidos **antes** de implementar o auth guard, pois o guard depende de um `Listenable` funcional.

A arquitetura de auth simulada é simples: `UserNotifier` (state `User?`) expõe `login()` e `logout()`; `RouterNotifier` observa o `userNotifierProvider` via `ref.watch` e chama `notifyListeners()` quando o estado muda; `goRouterProvider` usa `ref.read(.notifier)` uma única vez na construção para evitar recriação do `GoRouter`. O fluxo completo — toque em "Avançar" → loading 500ms → UserNotifier.login() → RouterNotifier.redirect() → `/home` — já está totalmente determinado pelas decisões do CONTEXT.md.

A persistência via SharedPreferences usa o padrão de leitura no `build()` do Notifier e escrita no método de mutação. As 4 chaves de SharedPreferences são domínio de discretion do Claude: `lista_smart_user`, `lista_smart_cart`, `lista_smart_favorites`, `lista_smart_coins`.

**Primary recommendation:** Fix CR-02 primeiro (RouterNotifier com ChangeNotifier), depois CR-03 (ref.read em goRouterProvider), depois wire UserNotifier no RouterNotifier.redirect(), e só então implementar a LoginScreen UI.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Auth state (User?) | Provider/Notifier (Riverpod) | SharedPreferences | UserNotifier é o único source-of-truth; UI e Router lêem dele |
| Route guard / redirect | RouterNotifier (Riverpod + GoRouter) | — | redirect() é o ponto de integração entre auth state e navegação |
| Login UI glassmorphic | Widget (Flutter) | — | LoginScreen é presentation layer; nenhuma lógica de negócio |
| Persistência da sessão | SharedPreferences | UserNotifier | SharedPreferences persiste; Notifier hidrata no build() |
| Dados mock | lib/core/data/mock_data.dart | — | Constantes estáticas sem camada extra; todas as features consomem |
| Carrinho e favoritos | CartNotifier / FavoritesNotifier (Riverpod) | SharedPreferences | Notifiers expõem estado; UI lê via ref.watch |
| Saldo de moedas | CoinNotifier (Riverpod) | SharedPreferences | CoinState encapsula balance + transactions |

---

## Standard Stack

### Core (já no pubspec.yaml — nenhuma adição necessária)

| Library | Version resolvida | Purpose | Status |
|---------|------------------|---------|--------|
| flutter_riverpod | 2.6.1 (^2.5.1) | State management — NotifierProvider, Provider | Já instalado, Fase 1 |
| go_router | 14.8.1 (^14.0.0) | Declarative routing + redirect guard | Já instalado, Fase 1 |
| shared_preferences | 2.5.5 (^2.2.0) | Persistência local de sessão, carrinho, moedas | Já instalado, Fase 1 |
| lucide_icons | 0.257.0 (^0.257.0) | Ícones de UI — mail, lock, eye, eyeOff | Já instalado, Fase 1 |
| google_fonts | 6.3.3 (^6.1.0) | Tipografia Inter | Já instalado, Fase 1 |
| intl | 0.19.0 (^0.19.0) | Formatação BRL | Já instalado, Fase 1 |

**Nota CR-01:** `intl` já está declarado explicitamente no `pubspec.yaml` (verificado). CR-01 está tecnicamente resolvido — o arquivo foi atualizado na Fase 1 conforme o CLAUDE.md recomendava. Não há ação pendente para CR-01.

### Nenhum pacote novo nesta fase

Esta fase não instala nenhum pacote externo novo. Todos os pacotes necessários já foram adicionados na Fase 1. [VERIFIED: pubspec.yaml — inspecionado diretamente]

---

## Package Legitimacy Audit

> Esta fase não instala pacotes novos. Todos os pacotes já foram auditados e verificados na Fase 1.

| Package | Status |
|---------|--------|
| flutter_riverpod | Aprovado (Fase 1) |
| go_router | Aprovado (Fase 1) |
| shared_preferences | Aprovado (Fase 1) |
| lucide_icons | Aprovado (Fase 1) |
| google_fonts | Aprovado (Fase 1) |
| intl | Aprovado (Fase 1) |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
Toque "Avançar"
      |
      v
LoginScreen (ConsumerStatefulWidget)
  - _isLoading = true → rebuild (CircularProgressIndicator)
  - Future.delayed(500ms)
      |
      v
ref.read(userNotifierProvider.notifier).login()
      |
      v
UserNotifier.login()
  - state = MockData.user (User com coinBalance=750)
  - SharedPreferences.setString('lista_smart_user', json)
      |
      v
UserNotifier.state changed → RouterNotifier.build() ouve via ref.watch
      |
      v
RouterNotifier.notifyListeners() [ChangeNotifier]
      |
      v
GoRouter.refreshListenable notificado
      |
      v
RouterNotifier.redirect() chamado
  - user != null + rota == '/login' → retorna '/home'
      |
      v
GoRouter.go('/home') automático
      |
      v
HomeScreen exibida (placeholder Fase 1, completa na Fase 3)
```

### Recommended Project Structure (novos arquivos desta fase)

```
lib/
├── core/
│   ├── data/
│   │   └── mock_data.dart          # MockData — constantes estáticas (NOVO)
│   └── providers/
│       ├── user_notifier.dart      # UserNotifier + userNotifierProvider (NOVO)
│       ├── cart_notifier.dart      # CartNotifier + cartProvider (NOVO)
│       ├── favorites_notifier.dart # FavoritesNotifier + favoritesProvider (NOVO)
│       └── coin_notifier.dart      # CoinNotifier + CoinState + coinProvider (NOVO)
├── features/
│   └── auth/
│       └── presentation/
│           └── login_screen.dart   # SUBSTITUIR placeholder com UI glassmorphic
└── routing/
    ├── router_notifier.dart        # CORRIGIR CR-02 (ChangeNotifier mixin)
    └── app_router.dart             # CORRIGIR CR-03 (ref.read em vez de ref.watch)
```

### Pattern 1: RouterNotifier com ChangeNotifier (fix CR-02)

**What:** Usar `with ChangeNotifier` em vez de implementar `Listenable` manualmente com slot único.
**When to use:** Sempre que um Notifier precisa ser `refreshListenable` do GoRouter.

```dart
// Source: CLAUDE.md + 01-REVIEW.md CR-02 fix
// lib/routing/router_notifier.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/user_notifier.dart';

class RouterNotifier extends AsyncNotifier<void> with ChangeNotifier {
  @override
  Future<void> build() async {
    // Observa o UserNotifier — quando user muda, GoRouter reavalia redirect()
    ref.watch(userNotifierProvider);
    // ChangeNotifier.notifyListeners() dispara o refreshListenable do GoRouter
    listenSelf((_, __) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final user = ref.read(userNotifierProvider);
    final isOnLogin = state.matchedLocation == AppRoutes.login;

    if (user == null) return AppRoutes.login;
    if (isOnLogin) return AppRoutes.home;
    return null;
  }
}

// IMPORTANTE: remover autoDispose — GoRouter precisa do notifier vivo pela
// vida inteira do app. AutoDispose pode descartar o notifier prematuramente.
final routerNotifierProvider =
    AsyncNotifierProvider<RouterNotifier, void>(RouterNotifier.new);
```

**Notas críticas:**
- `AutoDisposeAsyncNotifier` → `AsyncNotifier` (sem autoDispose). [ASSUMED — baseado em análise do CR-03: autoDispose é perigoso quando GoRouter segura referência ao notifier]
- `with ChangeNotifier` implementa `Listenable` com lista de listeners thread-safe.
- `listenSelf((_, __) => notifyListeners())` propaga mudanças de estado do Notifier para o GoRouter.
- `ref.watch(userNotifierProvider)` em `build()` faz o Notifier se reconstruir quando o usuário muda.

### Pattern 2: goRouterProvider com ref.read (fix CR-03)

**What:** Substituir `ref.watch(routerNotifierProvider.notifier)` por `ref.read` em `Provider<GoRouter>`.
**When to use:** Obrigatório — `Provider` não é reativo; `ref.watch` dentro dele causa recriação do GoRouter.

```dart
// Source: CLAUDE.md "Do not use ref.watch inside a Provider to create GoRouter"
// lib/routing/app_router.dart

final goRouterProvider = Provider<GoRouter>((ref) {
  // ref.read — obtém o notifier UMA VEZ na construção.
  // GoRouter segura a referência pelo tempo de vida do app.
  final notifier = ref.read(routerNotifierProvider.notifier);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login, // Fase 2: começa em /login, redirect leva para /home se logado
    debugLogDiagnostics: kDebugMode,  // WR-03: guarda com kDebugMode
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [ /* rotas inalteradas */ ],
  );
});
```

**Nota sobre `initialLocation`:** Mudar de `/home` para `/login`. Na Fase 1, estava em `/home` para que o placeholder navegasse direto. Na Fase 2, o auth guard está ativo — `redirect()` cuidará de levar o usuário logado para `/home` caso a sessão persista.

### Pattern 3: UserNotifier com persistência

**What:** `NotifierProvider<UserNotifier, User?>` que hidrata do SharedPreferences no `build()` e persiste em cada mutação.
**When to use:** State de autenticação simulada com sobrevivência ao restart.

```dart
// Source: CLAUDE.md — NotifierProvider pattern (não StateNotifierProvider)
// lib/core/providers/user_notifier.dart

class UserNotifier extends Notifier<User?> {
  static const _key = 'lista_smart_user';

  @override
  User? build() {
    // Hidrata sessão persistida — síncrono porque SharedPreferences já foi
    // inicializado antes do runApp() em main.dart
    final prefs = ref.watch(sharedPreferencesProvider);
    final json = prefs.getString(_key);
    if (json == null) return null;
    try {
      return User.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null; // Dados corrompidos → sessão nula (seguro)
    }
  }

  void login() {
    final user = MockData.user; // User(id: 'jose_augusto', name: 'José Augusto', ..., coinBalance: 750)
    state = user;
    _persist(user);
  }

  void logout() {
    state = null;
    ref.read(sharedPreferencesProvider).remove(_key);
  }

  void _persist(User user) {
    ref.read(sharedPreferencesProvider).setString(_key, jsonEncode(user.toJson()));
  }
}

final userNotifierProvider = NotifierProvider<UserNotifier, User?>(UserNotifier.new);
```

### Pattern 4: CartNotifier com persistência JSON

**What:** `NotifierProvider<CartNotifier, List<CartItem>>` com encode/decode JSON de lista.
**When to use:** Estado de carrinho persistido.

```dart
// lib/core/providers/cart_notifier.dart

class CartNotifier extends Notifier<List<CartItem>> {
  static const _key = 'lista_smart_cart';

  @override
  List<CartItem> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  void addItem(CartItem item) {
    // Verifica se já existe — incrementa quantidade
    final idx = state.indexWhere((e) => e.productId == item.productId);
    if (idx >= 0) {
      state = [
        ...state.sublist(0, idx),
        state[idx].copyWith(quantity: state[idx].quantity + 1),
        ...state.sublist(idx + 1),
      ];
    } else {
      state = [...state, item];
    }
    _persist();
  }

  void removeItem(String productId) {
    state = state.where((e) => e.productId != productId).toList();
    _persist();
  }

  void clear() {
    state = [];
    _persist();
  }

  void _persist() {
    final json = jsonEncode(state.map((e) => e.toJson()).toList());
    ref.read(sharedPreferencesProvider).setString(_key, json);
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);
```

### Pattern 5: FavoritesNotifier (List<String> de productIds)

**What:** `NotifierProvider<FavoritesNotifier, List<String>>` — lista de IDs de produtos favoritos.
**When to use:** Toggle de favorito nas telas de produto (Fase 3).

```dart
// lib/core/providers/favorites_notifier.dart

class FavoritesNotifier extends Notifier<List<String>> {
  static const _key = 'lista_smart_favorites';

  @override
  List<String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getStringList(_key);
    return raw ?? [];
  }

  void toggle(String productId) {
    if (state.contains(productId)) {
      state = state.where((id) => id != productId).toList();
    } else {
      state = [...state, productId];
    }
    ref.read(sharedPreferencesProvider).setStringList(_key, state);
  }

  bool isFavorite(String productId) => state.contains(productId);
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, List<String>>(FavoritesNotifier.new);
```

**Nota:** Para `FavoritesNotifier`, `SharedPreferences.getStringList`/`setStringList` é mais eficiente do que JSON encode/decode de lista simples. [ASSUMED — sem verificação formal, mas é prática standard para `List<String>` no SharedPreferences]

### Pattern 6: CoinState + CoinNotifier

**What:** Estado composto (balance + transactions) encapsulado em `CoinState`. `NotifierProvider<CoinNotifier, CoinState>`.
**When to use:** Quando o state é complexo demais para um tipo primitivo.

```dart
// lib/core/providers/coin_notifier.dart

@immutable
class CoinState {
  const CoinState({required this.balance, required this.transactions});
  final int balance;
  final List<CoinTransaction> transactions;

  CoinState copyWith({int? balance, List<CoinTransaction>? transactions}) =>
      CoinState(
        balance: balance ?? this.balance,
        transactions: transactions ?? this.transactions,
      );
}

class CoinNotifier extends Notifier<CoinState> {
  static const _balanceKey = 'lista_smart_coins_balance';
  static const _txKey = 'lista_smart_coins_tx';

  @override
  CoinState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final user = ref.watch(userNotifierProvider);

    // Saldo inicial: vem do User model (coinBalance=750) se não há persistência prévia
    final balance = prefs.getInt(_balanceKey) ?? user?.coinBalance ?? 0;

    final rawTx = prefs.getString(_txKey);
    List<CoinTransaction> transactions = [];
    if (rawTx != null) {
      try {
        final list = jsonDecode(rawTx) as List<dynamic>;
        transactions = list
            .map((e) => CoinTransaction.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        transactions = MockData.initialTransactions;
      }
    } else {
      transactions = MockData.initialTransactions;
    }

    return CoinState(balance: balance, transactions: transactions);
  }

  void addCoins(int amount, String description) {
    final tx = CoinTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: description,
      amount: amount,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      balance: state.balance + amount,
      transactions: [tx, ...state.transactions],
    );
    _persist();
  }

  void _persist() {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setInt(_balanceKey, state.balance);
    prefs.setString(_txKey,
        jsonEncode(state.transactions.map((t) => t.toJson()).toList()));
  }
}

final coinProvider = NotifierProvider<CoinNotifier, CoinState>(CoinNotifier.new);
```

**Nota sobre CoinNotifier.build():** `ref.watch(userNotifierProvider)` serve como fallback para o saldo inicial (750 do MockData.user). Quando há persistência, o `prefs.getInt` tem precedência. [ASSUMED — lógica derivada dos requisitos; padrão não documentado externamente]

### Pattern 7: LoginScreen como ConsumerStatefulWidget

**What:** `LoginScreen` precisa de estado local (`_isLoading`, `_isPasswordVisible`) — deve ser `StatefulWidget`. Como também usa `ref`, deve ser `ConsumerStatefulWidget`.
**When to use:** Toda tela com estado local temporário de UI + acesso a providers.

```dart
// lib/features/auth/presentation/login_screen.dart

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    // ref.read em handler de evento — NUNCA ref.watch (CLAUDE.md)
    ref.read(userNotifierProvider.notifier).login();
    // Não chamar setState após login — RouterNotifier redireciona automaticamente.
    // Se o widget ainda estiver montado (improvável), garantir que não quebre:
    if (mounted) setState(() => _isLoading = false);
  }
  // ...
}
```

### Pattern 8: MockData — constantes estáticas

```dart
// lib/core/data/mock_data.dart

import 'package:lista_smart/features/auth/domain/user.dart';
import 'package:lista_smart/features/profile/domain/product.dart';
import 'package:lista_smart/features/smart_coins/domain/coin_transaction.dart';

abstract class MockData {
  static const User user = User(
    id: 'jose_augusto_001',
    name: 'José Augusto',
    email: 'jose.rocha@zorte.com.br',
    address: 'Criciúma, SC',
    coinBalance: 750,
  );

  static const List<Product> products = [
    Product(
      id: 'p01',
      name: 'Leite Integral',
      brand: 'Tirol',
      category: 'Laticínios',
      imageUrl: '',
      averagePrice: 5.49,
      tags: ['laticínio', 'bebida'],
    ),
    // ... 9-14 produtos adicionais nas 4 categorias (D-12)
  ];

  // Supermarkets como Map simples (sem modelo próprio ainda — Fase 3 definirá)
  static const Map<String, double> supermarketDistances = {
    'Bistek': 2.3,
    'Giassi': 3.7,
    'Angeloni': 4.1,
    'Atacadão': 6.8,
  };

  static List<CoinTransaction> get initialTransactions => [
    CoinTransaction(
      id: 'tx_initial_01',
      description: 'Bônus de boas-vindas',
      amount: 500,
      createdAt: DateTime(2026, 5, 1),
    ),
    CoinTransaction(
      id: 'tx_initial_02',
      description: 'Nota fiscal cadastrada',
      amount: 250,
      createdAt: DateTime(2026, 5, 15),
    ),
  ];
}
```

**Nota:** `initialTransactions` é getter (não const) porque `DateTime` não é `const` em Dart. [VERIFIED: Dart language spec — DateTime não tem constructor const]

### Anti-Patterns to Avoid

- **`StateNotifierProvider`:** Deprecated, proibido no CLAUDE.md. Usar `NotifierProvider` sempre.
- **`ref.watch` em handler de evento:** `_handleLogin()` deve usar `ref.read(userNotifierProvider.notifier)` — nunca `ref.watch`.
- **`ref.watch` em `Provider<GoRouter>`:** CR-03 — já documentado. Causa recriação do router.
- **`autoDispose` no `routerNotifierProvider`:** GoRouter segura referência ao notifier por toda a vida do app; autoDispose pode descartar o notifier em condições de baixa memória, quebrando a integração.
- **`setState` após `login()` sem verificar `mounted`:** O RouterNotifier faz o redirect antes do frame seguinte; `_loginScreenState` pode já estar desmontada quando `setState` é chamado.
- **Chamar `context.go('/home')` manualmente após login:** O redirect do RouterNotifier é automático. Chamada manual pode criar dupla navegação ou estado inconsistente.
- **Construir `GoRouter` dentro de `build()` de widget:** Causa `GlobalKey` crash. Sempre via `goRouterProvider`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Listenable multi-listener | Lista manual de VoidCallback | `ChangeNotifier` mixin | ChangeNotifier gerencia duplicatas, null checks e notificação thread-safe |
| Serialização JSON de `User` | Encoders manuais | `User.toJson()` / `User.fromJson()` (já implementados) | Modelos já têm round-trip verificado em testes |
| Persistência de lista de strings | JSON encode manual | `SharedPreferences.getStringList`/`setStringList` | API nativa do pacote, mais eficiente para List<String> |
| State local de formulário | Provider Riverpod | `StatefulWidget` local (`_isLoading`, `_isPasswordVisible`) | Estado efêmero de UI não pertence ao Riverpod (CLAUDE.md) |
| Blur decorativo | Shader personalizado | `BackdropFilter(filter: ImageFilter.blur(...))` + `ClipOval` | API Material nativa, sem dependências extras |
| FilledButton estilizado | Widget customizado | `FilledButton` com `style: FilledButton.styleFrom(backgroundColor: AppColors.primary)` | Material 3 nativo com acessibilidade built-in |

**Key insight:** O código da Fase 1 já entregou modelos de domínio completos com `toJson/fromJson`. A Fase 2 consome esses modelos diretamente — não há lógica de serialização para reimplementar.

---

## Common Pitfalls

### Pitfall 1: RouterNotifier descarregado pelo autoDispose antes do redirect

**What goes wrong:** Com `AutoDisposeAsyncNotifier`, o Riverpod pode descartar `RouterNotifier` quando não há watchers ativos. GoRouter segura uma referência ao notifier descartado — o `notifyListeners()` nunca dispara, e o redirect não ocorre.

**Why it happens:** `AutoDisposeAsyncNotifier` libera o state quando todos os listeners são removidos. Entre builds de widget, pode não haver listener ativo por um frame.

**How to avoid:** Usar `AsyncNotifierProvider<RouterNotifier, void>` (sem autoDispose). GoRouter garante que o `refreshListenable` é ouvido continuamente.

**Warning signs:** Redirect funciona na primeira vez mas para de funcionar após hot reload ou saída e retorno ao app.

---

### Pitfall 2: `setState` após redirect em `_LoginScreenState`

**What goes wrong:** `_handleLogin()` chama `Future.delayed` + `ref.read(...).login()`. O RouterNotifier dispara o redirect no mesmo frame (ou frame seguinte). A `LoginScreen` é desmontada. Se o código após `await` tentar `setState(() => _isLoading = false)`, Flutter lança `setState() called after dispose()`.

**Why it happens:** O `await Future.delayed` cede o controle; o redirect pode desmontar o widget antes do resumo.

**How to avoid:** Verificar `if (mounted)` antes de qualquer `setState` após `await`:
```dart
if (mounted) setState(() => _isLoading = false);
```

**Warning signs:** `FlutterError: setState() called after dispose()` no console.

---

### Pitfall 3: `initialLocation: AppRoutes.home` com auth guard ativo

**What goes wrong:** Se `goRouterProvider` mantiver `initialLocation: AppRoutes.home` (configuração da Fase 1), ao iniciar sem sessão persistida o redirect dispara `/home → /login` mas pode causar um flash do HomeScreen por 1 frame antes do redirect.

**Why it happens:** GoRouter navega para `initialLocation` e só depois avalia `redirect()`.

**How to avoid:** Mudar `initialLocation` para `AppRoutes.login`. Com sessão persistida, `UserNotifier.build()` retorna o usuário imediatamente (sem async gap), e `redirect()` redireciona para `/home` antes de renderizar a LoginScreen. [ASSUMED — comportamento do GoRouter 14.x; verificado por padrão na documentação go_router]

**Warning signs:** Tela Home aparece brevemente antes da tela de Login em inicialização fria.

---

### Pitfall 4: `BackdropFilter` aplica blur em todo o stack acima, não apenas aos blobs

**What goes wrong:** `BackdropFilter` aplica o filtro ao que estiver **abaixo** dele no Stack, não ao Container filho. Se posicionado incorretamente, vai embaçar o card de login em vez dos blobs decorativos.

**Why it happens:** A semântica do `BackdropFilter` é "aplique este filtro à imagem renderizada abaixo deste widget".

**How to avoid:** Estrutura correta:
```dart
Stack(
  children: [
    // 1. Blobs (sem blur ainda)
    Positioned(..., child: ClipOval(child: Container(color: AppColors.primary.withValues(alpha: 0.25)))),
    Positioned(..., child: ClipOval(child: Container(color: AppColors.primary.withValues(alpha: 0.15)))),
    // 2. BackdropFilter SOBRE os blobs — embaça tudo abaixo (os blobs)
    Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(color: Colors.transparent), // filho obrigatório
      ),
    ),
    // 3. Conteúdo (card + campos) — não sofre blur
    Center(child: SingleChildScrollView(...)),
  ],
)
```

**Warning signs:** O card de login aparece embaçado em vez de nítido; os blobs aparecem nítidos em vez de desfocados.

---

### Pitfall 5: `withOpacity` deprecated — usar `withValues`

**What goes wrong:** `AppColors.primary.withOpacity(0.3)` gera deprecated warning no Flutter 3.27+. O código do CONTEXT.md e UI-SPEC já usa `withValues(alpha: 0.3)` — seguir esse padrão.

**Why it happens:** Flutter 3.27 deprecou `withOpacity` em favor de `withValues` para suporte a color spaces além de sRGB.

**How to avoid:** Usar `color.withValues(alpha: 0.X)` em todo código desta fase. [VERIFIED: 01-02-SUMMARY.md usa `withValues` no NavigationBar — padrão já estabelecido no projeto]

---

### Pitfall 6: WR-02 — `CoinTransaction.fromJson` lança `FormatException`

**What goes wrong:** `DateTime.parse(json['createdAt'])` lança `FormatException` se os dados do SharedPreferences estiverem corrompidos. Um crash de parse de data na inicialização do app bloquearia permanentemente o app.

**Why it happens:** `DateTime.parse` é throw, não nullable.

**How to avoid:** Aplicar o fix de WR-02 ao implementar o `CoinNotifier`:
```dart
createdAt: DateTime.tryParse(json['createdAt'] as String) ?? DateTime.fromMillisecondsSinceEpoch(0),
```
Esta é uma oportunidade de corrigir WR-02 ao escrever o code do `CoinNotifier` que consome `CoinTransaction.fromJson`. [VERIFIED: 01-REVIEW.md WR-02]

---

## Code Examples

### Glassmorphic Card Container
```dart
// Source: CONTEXT.md specifics + UI-SPEC.md Color section
Container(
  decoration: BoxDecoration(
    color: AppColors.surface.withValues(alpha: 0.7),
    borderRadius: BorderRadius.circular(AppSizes.radiusXL), // 24.0
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.1),
      width: 1.0,
    ),
  ),
  padding: const EdgeInsets.all(AppSizes.spacingL), // 24.0
  child: Column(...),
)
```

### TextFormField estilizado com ícone Lucide
```dart
// Source: UI-SPEC.md Layout Structure
TextFormField(
  decoration: InputDecoration(
    hintText: 'seu@email.com',
    hintStyle: TextStyle(color: AppColors.textSecondary),
    prefixIcon: const Icon(LucideIcons.mail, color: AppColors.textSecondary),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusM), // 12.0
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      borderSide: const BorderSide(color: AppColors.primary),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
    ),
  ),
)
```

### FilledButton "Avançar" full-width
```dart
// Source: CONTEXT.md D-04 + UI-SPEC.md Component Inventory
SizedBox(
  width: double.infinity,
  child: FilledButton(
    onPressed: _isLoading ? null : _handleLogin,
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.background, // texto escuro sobre fundo verde
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusL), // 16.0
      ),
    ),
    child: const Text('Avançar'),
  ),
)
```

### Loading state (substitui o botão)
```dart
// Source: CONTEXT.md D-06 + UI-SPEC.md Interaction States
_isLoading
    ? const SizedBox(
        height: 48,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      )
    : SizedBox(width: double.infinity, child: FilledButton(...))
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `StateNotifierProvider` | `NotifierProvider` | Riverpod 2.0 | API mais concisa; StateNotifier deprecated |
| `ref.listenSelf` (em Ref) | `listenSelf` (em Notifier diretamente) | Riverpod 2.6.x | Deprecation aviso removido; Fase 1 já adotou |
| `color.withOpacity(x)` | `color.withValues(alpha: x)` | Flutter 3.27 | Deprecation warning suprimido |
| `CardTheme` | `CardThemeData` | Flutter 3.41.9 | Fase 1 já corrigiu |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `FavoritesNotifier` usa `SharedPreferences.getStringList`/`setStringList` em vez de JSON manual | Standard Stack / Patterns | Baixo — se API não existir (improvável), fallback trivial para JSON encode |
| A2 | `initialLocation` deve mudar para `/login` na Fase 2 para evitar flash do HomeScreen | Pitfalls / Pattern 2 | Médio — se GoRouter 14.x avaliar redirect antes de renderizar, flash não ocorre; mudar de volta para `/home` seria o fix |
| A3 | Remover `autoDispose` de `routerNotifierProvider` é necessário para evitar dispose prematuro | Patterns / Pitfall 1 | Alto — se deixado como autoDispose, redirect pode parar de funcionar após rebuild; reverter para autoDispose apenas se testes mostrarem que não há problema |
| A4 | `CoinNotifier.build()` faz `ref.watch(userNotifierProvider)` para obter o saldo inicial do `User.coinBalance` | Patterns | Baixo — lógica derivada dos requisitos; alternativa é hardcodar 750 em MockData |
| A5 | `MockData.supermarketDistances` como `Map<String, double>` é suficiente para Fase 2 | Code Examples | Baixo — Fase 3 definirá modelo `Supermarket` completo; a Fase 2 não exige modelo completo |

---

## Open Questions

1. **`CoinTransaction.fromJson` — quando corrigir WR-02?**
   - What we know: WR-02 está documentado na review. A `CoinNotifier` vai consumir `CoinTransaction.fromJson`.
   - What's unclear: O fix deve ser aplicado no arquivo de domínio (`coin_transaction.dart`) ou contornado na camada do Notifier com try/catch?
   - Recommendation: Corrigir em `coin_transaction.dart` (usar `DateTime.tryParse` com fallback) — é o lugar correto para validação de deserialização. Isso resolve WR-02 definitivamente.

2. **`Product.tags` — corrigir WR-01 nesta fase?**
   - What we know: WR-01 (tags mutável em classe @immutable) está na review. `MockData.products` usará `Product` com tags.
   - What's unclear: O planner deve incluir a correção de WR-01 nesta fase ou diferir para Fase 3 quando `Product` for usado extensivamente?
   - Recommendation: Incluir fix de WR-01 nesta fase como parte da criação de `MockData` — custo mínimo (1 linha por construtor/fromJson) e previne bug antes que Fase 3 distribua instâncias de `Product` amplamente.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | Compilação | ✓ | 3.41.9 | — |
| flutter_riverpod | Notifiers, state | ✓ | 2.6.1 | — |
| go_router | Roteamento | ✓ | 14.8.1 | — |
| shared_preferences | Persistência | ✓ | 2.5.5 | — |
| lucide_icons 0.257.0 | Ícones (mail, lock, eye, eyeOff) | ✓ | 0.257.0 | — |
| P:\ subst drive | flutter test (workaround path-with-spaces) | ✓ | N/A | Re-criar com `subst P: "C:\Users\Jose Augusto\Desktop\Unesc\Fase 5\Desenvolvimento Mobile\gsd"` |

**Missing dependencies with no fallback:** nenhum

**Missing dependencies with fallback:** nenhum

**Nota de ambiente:** O workaround de `subst P:` para `flutter test` é necessário (Fase 1 documentou isso). O planner deve incluir instrução de verificação/criação do `subst P:` antes de rodar a suite de testes.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (SDK bundled) |
| Config file | none — usa `flutter test` diretamente |
| Quick run command | `flutter test test/providers/ -x` (via P:\ subst) |
| Full suite command | `flutter test test/ -x` (via P:\ subst) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AUTH-01 | LoginScreen renderiza campos email/senha com ícones Lucide e blobs de fundo | widget | `flutter test test/widgets/login_screen_test.dart -x` | ❌ Wave 0 |
| AUTH-02 | Toque em "Avançar" preenche UserNotifier com MockData.user e navega para /home | unit + widget | `flutter test test/providers/user_notifier_test.dart -x` | ❌ Wave 0 |
| AUTH-03 | RouterNotifier redireciona para /login quando user==null | unit | `flutter test test/routing/router_notifier_test.dart -x` | ❌ Wave 0 |
| D-15 | CartNotifier, FavoritesNotifier, CoinNotifier persistem e hidratam do SharedPreferences | unit | `flutter test test/providers/cart_notifier_test.dart test/providers/favorites_notifier_test.dart test/providers/coin_notifier_test.dart -x` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `flutter test test/ -x` (full suite — roda em < 30s, Fase 1 rodou 9 testes em < 5s)
- **Per wave merge:** full suite via P:\ subst
- **Phase gate:** Full suite green antes do `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/providers/user_notifier_test.dart` — cobre AUTH-02 + persistência de sessão
- [ ] `test/providers/cart_notifier_test.dart` — cobre D-15 (cart persistence)
- [ ] `test/providers/favorites_notifier_test.dart` — cobre D-15 (favorites persistence)
- [ ] `test/providers/coin_notifier_test.dart` — cobre D-15 (coin persistence)
- [ ] `test/routing/router_notifier_test.dart` — cobre AUTH-03 (redirect logic)
- [ ] `test/widgets/login_screen_test.dart` — cobre AUTH-01 (UI rendering)

**Nota:** Testes de widget precisam de `flutter_test` com `pumpWidget` e `ProviderScope`. Testes de Notifier precisam de `ProviderContainer` com `sharedPreferencesProvider` overridden usando `MockSharedPreferences` ou equivalente. [ASSUMED — padrão de teste Riverpod amplamente documentado em riverpod.dev]

---

## Security Domain

> `security_enforcement: true`, `security_asvs_level: 1` (config.json)

Esta fase implementa autenticação **simulada** sem backend real. Os controles de segurança ASVS aplicáveis são limitados pelo escopo acadêmico/local.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | Sim (simulado) | Login simulado — sem senhas reais; qualquer entrada aceita (D-05). ASVS V2 não se aplica plenamente a auth mock. |
| V3 Session Management | Sim (parcial) | Sessão persistida em SharedPreferences (local, sem transmissão de rede). Sem token de sessão real — apenas dados do User serializado. |
| V4 Access Control | Sim | RouterNotifier.redirect() implementa guarda de rota — usuário null não acessa rotas protegidas. |
| V5 Input Validation | Não aplicável | D-05: sem validação de formulário por decisão do projeto. Auth é 100% simulado. |
| V6 Cryptography | Não aplicável | Sem criptografia — dados locais, sem transmissão. Projeto acadêmico. |

### Known Threat Patterns for Flutter/Riverpod

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Listener substituído (CR-02) | Tampering — guard de rota pode ser bypassado | ChangeNotifier mixin (D-08) |
| GoRouter recriado com ref.watch (CR-03) | Tampering — reset de estado de navegação | ref.read(.notifier) (D-09) |
| SharedPreferences corrompido → crash na inicialização | Denial of Service | try/catch em todos os fromJson; DateTime.tryParse (WR-02) |

---

## Sources

### Primary (HIGH confidence)

- Código fonte verificado diretamente: `lib/routing/router_notifier.dart`, `lib/routing/app_router.dart`, `lib/features/auth/domain/user.dart`, `lib/core/persistence/shared_preferences_provider.dart`, `pubspec.yaml`, `lib/core/constants/app_colors.dart`, `lib/core/constants/app_sizes.dart`
- `C:/pub-cache/hosted/pub.dev/lucide_icons-0.257.0/lib/lucide_icons.dart` — verificado: `mail`, `lock`, `eye`, `eyeOff` presentes [VERIFIED: lucide_icons pub cache]
- `.planning/phases/01-foundation/01-REVIEW.md` — CR-02, CR-03, WR-01, WR-02 documentados com código de fix
- `.planning/phases/02-auth-state-layer/02-CONTEXT.md` — decisões D-01 a D-15 (fonte canônica)
- `.planning/phases/02-auth-state-layer/02-UI-SPEC.md` — especificação visual completa
- `CLAUDE.md` — restrições técnicas (Riverpod 2.x patterns, proibições ref.watch)
- `.planning/config.json` — `nyquist_validation: true`, `security_enforcement: true`

### Secondary (MEDIUM confidence)

- `.planning/phases/01-foundation/01-01-SUMMARY.md` — versões exatas resolvidas, padrões de test TDD
- `.planning/phases/01-foundation/01-02-SUMMARY.md` — decisões de routing (listenSelf, GlobalKey, StatefulShellRoute)

### Tertiary (LOW confidence)

- [ASSUMED] Remoção de `autoDispose` de `routerNotifierProvider` é necessária — baseado em análise do CR-03 e comportamento documentado do Riverpod com GoRouter, não verificado em docs oficiais desta sessão.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — todos os pacotes verificados no pubspec.yaml e pub-cache
- Architecture patterns: HIGH — derivados diretamente do CONTEXT.md (decisões D-08 a D-10) e code review (CR-02, CR-03)
- Pitfalls: HIGH para CR-02/CR-03 (documentados na review); MEDIUM para pitfalls de BackdropFilter e `initialLocation` (ASSUMED baseado em comportamento Flutter/GoRouter)
- Lucide icons: HIGH — verificados diretamente no pub-cache (mail, lock, eye, eyeOff presentes)

**Research date:** 2026-06-01
**Valid until:** 2026-07-01 (stack estável; 30 dias de validade para Riverpod 2.x + go_router 14.x)

---
phase: 02-auth-state-layer
plan: 01
status: completed
completed_at: "2026-06-01"
tests_added: 9
files_created: 4
files_modified: 2
---

# Plan 02-01 Summary — Auth Backbone

## What was done

**Task 1: MockData + UserNotifier (TDD)**
- Created `lib/core/data/mock_data.dart` — abstract class with: `User` José Augusto (750 moedas), 12 `Product` instances across 4 categories, `supermarketDistances` (4 entries), `initialTransactions` getter.
- Created `lib/core/providers/user_notifier.dart` — `Notifier<User?>` with build() hydration from SharedPreferences, login(), logout(), _persist(). Key `'lista_smart_user'`.
- Created `test/providers/user_notifier_test.dart` — 6 tests: null on empty prefs, login sets José Augusto, login persists, session hydrates on restart, logout clears, corrupted JSON returns null.

**Task 2: CR-02 + CR-03 fixes + redirect active**
- Replaced `lib/routing/router_notifier.dart` — `AsyncNotifier<void> with ChangeNotifier` (removed AutoDispose, removed single-slot Listenable impl). `build()` watches userNotifierProvider. `redirect()` returns `/login` when null, `/home` when logged in and on login page.
- Patched `lib/routing/app_router.dart` — `ref.read` (not watch), `initialLocation: AppRoutes.login`, `debugLogDiagnostics: kDebugMode`. Added `import 'package:flutter/foundation.dart' show kDebugMode`.
- Created `test/routing/router_notifier_test.dart` — 3 tests verifying auth state governing redirect decisions. Note: GoRouterState not trivially instantiable in unit tests; tested via userNotifierProvider state.
- Fixed pre-existing `test/widget_test.dart` — was referencing non-existent `MyApp`; replaced with App smoke test using ProviderScope.

## Results

- 19/19 tests passing (regression + new)
- `flutter analyze lib/core/` → 0 issues
- `flutter analyze lib/routing/` → 0 issues
- All acceptance criteria met

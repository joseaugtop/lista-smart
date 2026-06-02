---
phase: 02
slug: auth-state-layer
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-02
---

# Phase 02 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (built-in) |
| **Config file** | pubspec.yaml (flutter_test dependency) |
| **Quick run command** | `flutter test test/ --no-pub` |
| **Full suite command** | `flutter test test/ && flutter analyze lib/` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/ --no-pub`

---

## Validation Architecture

### Wave 0 — Prerequisites

- [ ] `flutter analyze lib/` exits 0 — no static analysis errors after RouterNotifier + goRouterProvider fixes (CR-02, CR-03)
- [ ] `flutter test test/models/ test/repositories/` exits 0 — Phase 1 tests still green (regression guard)
- [ ] `pubspec.yaml` contains `intl: ^0.19.0` as direct dependency (CR-01)

### Wave 1 — Router + Auth Guard

- [ ] `RouterNotifier` uses `with ChangeNotifier` mixin and calls `notifyListeners()` (not single-slot `_routerListener`)
- [ ] `goRouterProvider` uses `ref.read(routerNotifierProvider.notifier)` — not `ref.watch`
- [ ] `routerNotifierProvider` is NOT `autoDispose` — GoRouter holds reference for app lifetime
- [ ] `initialLocation` in `goRouterProvider` changed from `/home` to `/login`
- [ ] `RouterNotifier.redirect()`: user==null → `/login`; user!=null on `/login` route → `/home`; else `null`

### Wave 2 — Login Screen

- [ ] `lib/features/auth/presentation/login_screen.dart` uses `BackdropFilter` with `ImageFilter.blur`
- [ ] Login screen has 2 blobs (colored circles) with opacity behind the glassmorphic card
- [ ] `TextFormField` for email uses `LucideIcons.mail` prefix icon
- [ ] `TextFormField` for password uses `LucideIcons.lock` prefix + `LucideIcons.eye`/`eyeOff` suffix toggle
- [ ] FilledButton "Avançar" has `style: FilledButton.styleFrom(backgroundColor: AppColors.primary)`
- [ ] `flutter analyze lib/features/auth/` exits 0

### Wave 3 — State Notifiers + Mock Data

- [ ] `lib/core/data/mock_data.dart` exists with `MockData.user`, `MockData.products` (10-15 items), `MockData.supermarkets` (4 items)
- [ ] `UserNotifier` extends `Notifier<User?>` — NOT `StateNotifier`
- [ ] `CartNotifier`, `FavoritesNotifier`, `CoinNotifier` all extend `Notifier<T>` pattern
- [ ] All 4 notifiers persist via SharedPreferences on state change
- [ ] `CoinTransaction.fromJson` uses `DateTime.tryParse` (fix WR-02)
- [ ] `Product.tags` wrapped with `List<String>.unmodifiable()` in constructor + fromJson (fix WR-01)
- [ ] `flutter test test/` exits 0 (all unit tests pass)

### Human Verification Required

- [ ] Tap "Avançar" on login screen → loading spinner appears briefly (~500ms) → app navigates to Home tab
- [ ] App starts on login screen (`/login` initial route)
- [ ] After login, hitting back does not return to login screen (GoRouter state correct)
- [ ] Hot reload after login preserves logged-in state

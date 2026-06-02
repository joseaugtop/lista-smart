<!-- GSD:project-start source:PROJECT.md -->
## Project

**Lista Smart**

Lista Smart é um aplicativo Flutter para Android e iOS que combina lista de compras inteligente com comparação de preços entre supermercados e rastreamento de economia em combustível. O app usa um sistema de gamificação com "Smart Coins" para recompensar usuários que cadastram notas fiscais, incentivando a contribuição de dados de preços. É um projeto acadêmico de Desenvolvimento Mobile (Unesc, Fase 5) com foco em demonstrar arquitetura limpa, design system sofisticado e fluência nativa Flutter.

**Core Value:** Ajudar usuários a fazer compras mais baratas mostrando qual supermercado tem o menor preço final, incluindo o custo de deslocamento por combustível.

### Constraints

- **Tech Stack**: Flutter + Riverpod + go_router + shared_preferences — definido pelo enunciado
- **Dados**: Totalmente local/mocked — sem backend, sem rede
- **Ícones**: lucide_icons obrigatório
- **Fontes**: google_fonts obrigatório
- **Plataformas**: Android & iOS nativos apenas (sem web/desktop)
- **Versões**: flutter_riverpod ^2.5.1, go_router ^14.0.0
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## Recommended Stack
| Package | Pinned Version | Latest Stable | Purpose | Notes |
|---------|---------------|---------------|---------|-------|
| flutter_riverpod | ^2.5.1 | 3.3.1 (3.x branch) | Global state management | Course-prescribed. 2.x branch latest is 2.6.1. Pinning ^2.5.1 resolves to 2.6.x — intentional. Do NOT upgrade to 3.x (breaking API). |
| go_router | ^14.0.0 | 17.2.3 | Declarative routing with redirect support | Course-prescribed. ^14.0.0 resolves to 14.x. Latest is 17.x but 14.x is stable and fully functional for this scope. Do NOT upgrade to 15+ without migration guide review. |
| shared_preferences | ^2.2.0 | 2.x (maintained) | Local key-value persistence | Sufficient for cart, favorites, session. No SQL needed — all data is mocked. |
| lucide_icons | ^0.257.0 | 0.257.0 | Icon system | FIXED: course spec said ^3.0.0 but that version does not exist on pub.dev. Correct version is ^0.257.0. |
| google_fonts | ^6.1.0 | 8.x | Typography (Inter/Poppins) | 6.x is stable. Disable runtime HTTP fetching — see integration notes. |
| intl | ^0.19.0 | 0.19.x | Date/number formatting (BRL currency) | Pin to ^0.19.0. Flutter SDK ships its own intl; version must match. |
## Integration Patterns
### 1. App Entry Point — ProviderScope + SharedPreferences Init
### 2. Riverpod Provider Types — Which to Use
| Use Case | Provider Type | Rationale |
|----------|--------------|-----------|
| Read-only derived data (product list from mock) | `Provider<T>` | No side effects, pure computation |
| Simple sync mutable state (cart items, favorites) | `NotifierProvider<T, S>` | Modern API, replaces deprecated StateNotifier |
| Async state (simulated camera flow, coin award) | `AsyncNotifierProvider<T, S>` | Handles loading/error states ergonomically |
| Shared preferences access | `Provider<SharedPreferences>` | Overridden at startup, synchronous after init |
| User session (auth simulation) | `NotifierProvider<UserNotifier, UserState>` | Notifier implements Listenable for go_router |
### 3. go_router + Riverpod — Router Provider Pattern
### 4. Riverpod Consumer Patterns in Widgets
### 5. google_fonts Integration
### 6. intl — Brazilian Real Formatting
## Folder Structure
## Version Compatibility Notes
### CRITICAL — lucide_icons version mismatch
### flutter_riverpod 2.5.1 vs current 3.x
- Course pins `^2.5.1` which resolves to the latest 2.x release (2.6.1 as of 2024-10-22)
- Riverpod 3.0.0 was released 2025-09-10 with breaking API changes (Ref changes, legacy providers moved, AsyncValue parameter changes)
- **Do NOT upgrade to 3.x** — the prescribed API (`Notifier`, `AsyncNotifier`, `Provider`, `ConsumerWidget`) works identically in 2.5.x and 2.6.x
- The `StateNotifierProvider` is deprecated in 2.x — avoid it even though it still compiles
### go_router 14.x vs current 17.x
- `^14.0.0` resolves to the 14.x series (latest in that series: ~14.8.x)
- Breaking change in 14.0: `GoRouteData.onExit` now takes 2 parameters (`BuildContext`, `GoRouterState`)
- Versions 15-17 introduced additional changes not covered by the ^14 constraint
- **Do NOT upgrade** — 14.x is stable and sufficient for all required navigation patterns (nested routes, redirects, shell routes for bottom nav)
### intl version alignment
- `intl: ^0.19.0` must match the version bundled with the Flutter SDK's own `intl` dependency
- Flutter 3.16+ bundles intl 0.18.x/0.19.x — a mismatch causes `version solving failed`
- Run `flutter pub deps` after setup to verify intl version is consistent across the dependency graph
- If there is a conflict: override with `dependency_overrides:` in pubspec.yaml (acceptable for academic project)
### google_fonts 6.1.0
- Latest is 8.x but 6.x is stable
- The `^6.1.0` constraint will NOT upgrade to 7.x or 8.x — safe and intentional
- 6.x has no known breaking issues with Flutter 3.x
## What NOT to Do
### 1. Do not use `StateNotifierProvider`
### 2. Do not use `ref.watch` inside a `Provider` to create GoRouter
### 3. Do not create providers inside widget classes or functions
### 4. Do not use `google_fonts` without disabling HTTP fetching
### 5. Do not store ephemeral UI state (hover, form focus, animation progress) in Riverpod providers
### 6. Do not use `context.read<T>()` (inherited widget pattern) — use `ref.read(provider)`
### 7. Do not call `ref.watch` inside `initState`, `dispose`, or event handlers
### 8. Do not skip the `Listenable` implementation on `UserNotifier`
## pubspec.yaml Setup
## Confidence
| Area | Level | Reason |
|------|-------|--------|
| Riverpod 2.5.x patterns (Notifier, ConsumerWidget) | HIGH | Verified against riverpod.dev official docs and Context7 (3735+ code snippets) |
| go_router 14.x redirect + refreshListenable | HIGH | Verified against pub.dev changelog and multiple 2024 integration guides |
| Riverpod + go_router Listenable pattern | HIGH | Confirmed by Q Agency (2024), codewithandrea, official Riverpod discussions |
| SharedPreferences ProviderScope override | HIGH | Verified against official codewithandrea.com Riverpod initialization guide |
| lucide_icons version mismatch | HIGH | Directly verified on pub.dev — no 3.x version exists |
| google_fonts offline config | HIGH | Documented on pub.dev package page and multiple production guides |
| Folder structure recommendation | MEDIUM | Feature-first is the consensus recommendation; the specific split chosen here is opinionated for this project's domain |
| intl version conflict risk | MEDIUM | Documented pattern, specific Flutter SDK version in student's environment unknown |
## Sources
- [Riverpod Official Do's and Don'ts](https://riverpod.dev/docs/root/do_dont)
- [go_router pub.dev package page](https://pub.dev/packages/go_router)
- [flutter_riverpod changelog](https://pub.dev/packages/flutter_riverpod/changelog)
- [Handling Authentication State with go_router and Riverpod — Q Agency](https://q.agency/blog/handling-authentication-state-with-go_router-and-riverpod/)
- [Flutter App Architecture with Riverpod: Feature-first structure — codewithandrea.com](https://codewithandrea.com/articles/flutter-project-structure/)
- [Robust App Initialization with Riverpod — codewithandrea.com](https://codewithandrea.com/articles/robust-app-initialization-riverpod/)
- [Migrating from StateNotifier — Riverpod docs](https://riverpod.dev/docs/migration/from_state_notifier)
- [lucide_icons on pub.dev](https://pub.dev/packages/lucide_icons)
- [google_fonts on pub.dev](https://pub.dev/packages/google_fonts)
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->

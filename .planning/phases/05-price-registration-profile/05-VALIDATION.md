---
phase: 5
slug: price-registration-profile
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-02
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (built-in Flutter SDK) |
| **Config file** | none — standard flutter test runner |
| **Quick run command** | `flutter test test/providers/user_notifier_test.dart` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~8s |

---

## Sampling Rate

- **After every task commit:** `flutter test test/providers/user_notifier_test.dart`
- **After every plan wave:** `flutter test`
- **Before `/gsd-verify-work`:** Full suite green (currently 92 tests)
- **Max feedback latency:** ~8s

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------------|-----------|-------------------|-------------|--------|
| 05-01-01 | 01 | 1 | PREG-01 | N/A | widget | `flutter test test/features/scanner/scanner_screen_test.dart` | ❌ W0 | ⬜ pending |
| 05-01-02 | 01 | 1 | PREG-02 | N/A | widget | `flutter test test/features/scanner/scanner_screen_test.dart` | ❌ W0 | ⬜ pending |
| 05-01-03 | 01 | 1 | PREG-03 | N/A | widget | `flutter test test/features/scanner/scanner_screen_test.dart` | ❌ W0 | ⬜ pending |
| 05-01-04 | 01 | 1 | PREG-04 | double.tryParse fallback on fuelEfficiency | unit | `flutter test test/providers/coin_notifier_test.dart` | ✅ | ⬜ pending |
| 05-02-01 | 02 | 1 | PROF-01 | N/A | widget | `flutter test test/features/profile/profile_screen_test.dart` | ❌ W0 | ⬜ pending |
| 05-02-02 | 02 | 1 | PROF-02 | double.tryParse on fuelEfficiency; trim on text fields | unit | `flutter test test/providers/user_notifier_test.dart` | ✅ | ⬜ pending |
| 05-02-03 | 02 | 1 | PROF-03 | N/A | widget | `flutter test test/features/profile/profile_screen_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/features/scanner/scanner_screen_test.dart` — stubs covering PREG-01, PREG-02, PREG-03
- [ ] `test/features/profile/profile_screen_test.dart` — stubs covering PROF-01, PROF-03
- [ ] New test cases in `test/providers/user_notifier_test.dart` — covers PROF-02 (updateProfile persistence + vehicleModel/fuelEfficiency fields)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Confete anima ao entrar na etapa 3 | PREG-03 | flutter_test usa fake_async — partículas não renderizam, suavidade não verificável | Rodar app em device/emulator, escanear nota, verificar chuva de confete na tela 3 |
| Loading overlay 2s na etapa 1 aparece e desaparece | PREG-01 | Timing real não testado em widget test | Pressionar QR/Foto, observar overlay com blur + CircularProgressIndicator durante 2s |
| Salvar perfil persiste entre sessões | PROF-02 | Persistência real de SharedPreferences requer restart | Editar nome + km/L, salvar, matar app, reabrir, verificar campos mantidos |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

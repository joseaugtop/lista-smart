import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';

/// Root widget — watches goRouterProvider and passes it to MaterialApp.router.
/// ConsumerWidget is required so ref.watch() is available in build().
/// CRITICAL: uses only theme: appTheme (already dark) — do NOT add darkTheme: or themeMode:.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'Lista Smart',
      theme: appTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

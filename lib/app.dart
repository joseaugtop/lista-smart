import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'Lista Smart',
      theme: appLightTheme,
      darkTheme: appDarkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

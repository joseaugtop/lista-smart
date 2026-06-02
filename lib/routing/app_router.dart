import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../core/constants/app_colors.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/price_comparison/presentation/price_comparison_screen.dart';
// price_registration is a modal/flow, not a bottom nav branch — imported in Phase 2
import '../features/profile/presentation/profile_screen.dart';
import '../features/shopping_list/presentation/shopping_list_screen.dart';
import '../features/smart_coins/presentation/store_screen.dart';
import 'app_routes.dart';
import 'router_notifier.dart';

// GlobalKeys declared as top-level constants — CRASH PREVENTION.
// Never declare GlobalKey inside build() — creates new key on every rebuild.
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _tab0Key = GlobalKey<NavigatorState>(debugLabel: 'tab0');
final _tab1Key = GlobalKey<NavigatorState>(debugLabel: 'tab1');
final _tab2Key = GlobalKey<NavigatorState>(debugLabel: 'tab2');
final _tab3Key = GlobalKey<NavigatorState>(debugLabel: 'tab3');
final _tab4Key = GlobalKey<NavigatorState>(debugLabel: 'tab4');

/// GoRouter declared as a Riverpod Provider — NEVER inside widget build().
/// Using Provider<GoRouter> prevents GlobalKey conflicts and router recreation.
final goRouterProvider = Provider<GoRouter>((ref) {
  // Use .notifier to get RouterNotifier instance without subscribing to its state.
  // This avoids recreating GoRouter on every auth state change.
  final notifier = ref.read(routerNotifierProvider.notifier);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      // StatefulShellRoute.indexedStack — NOT ShellRoute.
      // Each branch gets its own Navigator → preserves scroll, sub-route stack, and Riverpod state.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithBottomNav(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _tab0Key,
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, __) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _tab1Key,
            routes: [
              GoRoute(
                path: AppRoutes.shoppingList,
                builder: (_, __) => const ShoppingListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _tab2Key,
            routes: [
              GoRoute(
                path: AppRoutes.comparison,
                builder: (_, __) => const PriceComparisonScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _tab3Key,
            routes: [
              GoRoute(
                path: AppRoutes.store,
                builder: (_, __) => const StoreScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _tab4Key,
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Bottom navigation scaffold — wraps the StatefulNavigationShell.
/// Uses NavigationBar (Material 3) for visual consistency with the dark theme.
class ScaffoldWithBottomNav extends StatelessWidget {
  const ScaffoldWithBottomNav({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.shoppingCart),
            label: 'Lista',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.barChart2),
            label: 'Comparar',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.store),
            label: 'Loja',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.user),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

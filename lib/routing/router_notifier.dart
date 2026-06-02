import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/user_notifier.dart';
import 'app_routes.dart';

class RouterNotifier extends AsyncNotifier<void> with ChangeNotifier {
  @override
  Future<void> build() async {
    ref.watch(userNotifierProvider);
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

final routerNotifierProvider =
    AsyncNotifierProvider<RouterNotifier, void>(RouterNotifier.new);

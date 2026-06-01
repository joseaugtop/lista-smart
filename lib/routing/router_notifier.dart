import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RouterNotifier extends AutoDisposeAsyncNotifier<void> implements Listenable {
  VoidCallback? _routerListener;

  @override
  Future<void> build() async {
    // Phase 1: no auth watch — redirect always returns null.
    // Phase 2 will add: ref.watch(authNotifierProvider);
    listenSelf((_, __) => _routerListener?.call());
  }

  /// Route guard — returns null unconditionally in Phase 1.
  /// Phase 2 will activate the auth guard here.
  String? redirect(BuildContext context, GoRouterState state) {
    return null;
  }

  @override
  void addListener(VoidCallback listener) => _routerListener = listener;

  @override
  void removeListener(VoidCallback listener) => _routerListener = null;
}

final routerNotifierProvider =
    AutoDisposeAsyncNotifierProvider<RouterNotifier, void>(RouterNotifier.new);

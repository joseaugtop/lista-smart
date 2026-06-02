import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../persistence/shared_preferences_provider.dart';
import '../../features/auth/domain/user.dart';

class UserNotifier extends Notifier<User?> {
  static const _key = 'lista_smart_user';

  @override
  User? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final json = prefs.getString(_key);
    if (json == null) return null;
    try {
      return User.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  void login() {
    const user = MockData.user;
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

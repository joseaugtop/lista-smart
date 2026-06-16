import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/shared_preferences_provider.dart';

class RecentSearchesNotifier extends Notifier<List<String>> {
  static const _key = 'lista_smart_recent_searches';
  static const _maxItems = 5;

  @override
  List<String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e as String).toList();
    } catch (_) {
      return [];
    }
  }

  void addSearch(String query) {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    var newList = List<String>.from(state);
    newList.remove(cleanQuery);
    newList.insert(0, cleanQuery);

    if (newList.length > _maxItems) {
      newList = newList.sublist(0, _maxItems);
    }

    state = newList;
    _persist();
  }

  void removeSearch(String query) {
    state = state.where((e) => e != query).toList();
    _persist();
  }

  void clearHistory() {
    state = [];
    _persist();
  }

  void _persist() {
    ref.read(sharedPreferencesProvider)
        .setString(_key, jsonEncode(state));
  }
}

final recentSearchesProvider =
    NotifierProvider<RecentSearchesNotifier, List<String>>(RecentSearchesNotifier.new);

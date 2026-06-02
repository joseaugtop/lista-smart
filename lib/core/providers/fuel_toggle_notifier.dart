import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/shared_preferences_provider.dart';

class FuelToggleNotifier extends Notifier<bool> {
  static const _key = 'lista_smart_fuel_toggle';

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_key) ?? true;
  }

  void toggle() {
    state = !state;
    ref.read(sharedPreferencesProvider).setBool(_key, state);
  }
}

final fuelToggleProvider =
    NotifierProvider<FuelToggleNotifier, bool>(FuelToggleNotifier.new);

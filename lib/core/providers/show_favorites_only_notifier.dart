import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShowFavoritesOnlyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final showFavoritesOnlyProvider =
    NotifierProvider<ShowFavoritesOnlyNotifier, bool>(
        ShowFavoritesOnlyNotifier.new);

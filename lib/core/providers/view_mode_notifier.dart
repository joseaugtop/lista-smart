import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ViewMode { grid, list }

class ViewModeNotifier extends Notifier<ViewMode> {
  @override
  ViewMode build() => ViewMode.grid;

  void setGrid() => state = ViewMode.grid;
  void setList() => state = ViewMode.list;
}

final viewModeProvider =
    NotifierProvider<ViewModeNotifier, ViewMode>(ViewModeNotifier.new);

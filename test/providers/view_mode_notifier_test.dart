import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_smart/core/providers/view_mode_notifier.dart';

void main() {
  group('ViewModeNotifier', () {
    ProviderContainer makeContainer() {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      return container;
    }

    test('build() defaults to grid mode', () {
      final container = makeContainer();
      expect(container.read(viewModeProvider), equals(ViewMode.grid));
    });

    test('setList() switches to list mode', () {
      final container = makeContainer();
      container.read(viewModeProvider.notifier).setList();
      expect(container.read(viewModeProvider), equals(ViewMode.list));
    });

    test('setGrid() switches back to grid mode', () {
      final container = makeContainer();
      container.read(viewModeProvider.notifier).setList();
      container.read(viewModeProvider.notifier).setGrid();
      expect(container.read(viewModeProvider), equals(ViewMode.grid));
    });
  });
}

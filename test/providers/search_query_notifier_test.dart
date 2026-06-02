import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_smart/core/providers/search_query_notifier.dart';

void main() {
  group('SearchQueryNotifier', () {
    ProviderContainer makeContainer() {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      return container;
    }

    test('build() returns empty string', () {
      final container = makeContainer();
      expect(container.read(searchQueryProvider), equals(''));
    });

    test('update() sets the query', () {
      final container = makeContainer();
      container.read(searchQueryProvider.notifier).update('leite');
      expect(container.read(searchQueryProvider), equals('leite'));
    });

    test('clear() resets to empty string', () {
      final container = makeContainer();
      container.read(searchQueryProvider.notifier).update('arroz');
      container.read(searchQueryProvider.notifier).clear();
      expect(container.read(searchQueryProvider), equals(''));
    });

    test('update() replaces previous query', () {
      final container = makeContainer();
      container.read(searchQueryProvider.notifier).update('leite');
      container.read(searchQueryProvider.notifier).update('queijo');
      expect(container.read(searchQueryProvider), equals('queijo'));
    });
  });
}

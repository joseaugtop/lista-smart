import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_smart/core/persistence/shared_preferences_provider.dart';
import 'package:lista_smart/core/providers/cart_notifier.dart';
import 'package:lista_smart/core/providers/shopping_lists_notifier.dart';
import 'package:lista_smart/features/shopping_list/domain/cart_item.dart';
import 'package:lista_smart/features/shopping_list/presentation/shopping_list_screen.dart';
import 'package:lista_smart/features/home/presentation/product_detail_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<ProviderContainer> buildContainer() async {
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
  }

  Future<void> pumpScreen(WidgetTester tester, ProviderContainer container) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
      child: const MaterialApp(
        home: ShoppingListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Shopping Lists Integration / UI Tests', () {
    testWidgets('exibe aba Minhas Listas vazia e permite criar primeira lista', (tester) async {
      final container = await buildContainer();
      addTearDown(container.dispose);

      await pumpScreen(tester, container);

      // Tap on the 'Minhas Listas' tab
      await tester.tap(find.text('Minhas Listas'));
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma lista personalizada'), findsOneWidget);

      // Tap on 'Criar Primeira Lista'
      await tester.tap(find.text('Criar Primeira Lista'));
      await tester.pumpAndSettle();

      // Dialog should be visible
      expect(find.text('Criar Nova Lista'), findsOneWidget);

      // Enter name and submit
      await tester.enterText(find.byType(TextField), 'Churrasco FDS');
      await tester.tap(find.text('Criar'));
      await tester.pumpAndSettle();

      // List should now be visible
      expect(find.text('Churrasco FDS'), findsOneWidget);
      expect(find.text('0 itens'), findsOneWidget);
    });

    testWidgets('permite renomear e excluir lista na aba de listas', (tester) async {
      final container = await buildContainer();
      addTearDown(container.dispose);

      // Seed a list first
      container.read(shoppingListsProvider.notifier).createList('Supermercado');

      await pumpScreen(tester, container);
      await tester.tap(find.text('Minhas Listas'));
      await tester.pumpAndSettle();

      expect(find.text('Supermercado'), findsOneWidget);

      // Tap on rename button (edit2 icon)
      await tester.tap(find.byIcon(LucideIcons.edit2));
      await tester.pumpAndSettle();

      expect(find.text('Renomear Lista'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Supermercado Mês');
      await tester.tap(find.text('Renomear'));
      await tester.pumpAndSettle();

      expect(find.text('Supermercado Mês'), findsOneWidget);

      // Tap on delete button (trash2 icon)
      await tester.tap(find.byIcon(LucideIcons.trash2).last); // last because cart tab also has trash button
      await tester.pumpAndSettle();

      expect(find.text('Excluir lista?'), findsOneWidget);
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma lista personalizada'), findsOneWidget);
    });

    testWidgets('detalhes da lista exibe itens e permite manipulação e quick cart', (tester) async {
      final container = await buildContainer();
      addTearDown(container.dispose);

      const testItem = CartItem(
        productId: 'item_x',
        productName: 'Pão de Alho',
        brand: 'Santa Massa',
        imageUrl: '',
        quantity: 3,
        unitPrice: 15.0,
      );

      // Seed a list with items
      container.read(shoppingListsProvider.notifier).createList('Churrasco', [testItem]);

      await pumpScreen(tester, container);
      await tester.tap(find.text('Minhas Listas'));
      await tester.pumpAndSettle();

      // Tap the list card to navigate to detail view
      await tester.tap(find.text('Churrasco'));
      await tester.pumpAndSettle();

      // Detail view components should render
      expect(find.text('Pão de Alho'), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // quantity
      expect(find.textContaining('45,00'), findsOneWidget); // total (15.0 * 3)

      // Increment quantity
      await tester.tap(find.byIcon(LucideIcons.plus));
      await tester.pumpAndSettle();
      expect(find.text('4'), findsOneWidget);
      expect(find.textContaining('60,00'), findsOneWidget);

      // Decrement quantity
      await tester.tap(find.byIcon(LucideIcons.minus));
      await tester.pumpAndSettle();
      expect(find.text('3'), findsOneWidget);

      // Load to cart (Quick Cart button)
      await tester.tap(find.byIcon(LucideIcons.shoppingCart).first);
      await tester.pumpAndSettle();

      // Verify SnackBar message
      expect(find.text('Itens da lista "Churrasco" carregados no carrinho!'), findsOneWidget);

      // Go back to lists
      await tester.tap(find.byIcon(LucideIcons.arrowLeft));
      await tester.pumpAndSettle();

      // Go to Active Cart Tab
      await tester.tap(find.text('Meu Carrinho'));
      await tester.pumpAndSettle();

      // Cart should contain the item
      expect(find.text('Pão de Alho'), findsOneWidget);
    });

    testWidgets('salvar carrinho como lista cria uma nova lista customizada', (tester) async {
      final container = await buildContainer();
      addTearDown(container.dispose);

      // Seed cart
      container.read(cartProvider.notifier).addItem(const CartItem(
            productId: 'c1',
            productName: 'Cerveja',
            brand: 'Heineken',
            imageUrl: '',
            quantity: 6,
            unitPrice: 6.50,
          ));

      await pumpScreen(tester, container);

      expect(find.text('Cerveja'), findsOneWidget);

      // Tap 'Salvar como Lista'
      await tester.tap(find.text('Salvar como Lista'));
      await tester.pumpAndSettle();

      expect(find.text('Salvar Carrinho como Lista'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Festinha');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Carrinho salvo como a lista "Festinha"!'), findsOneWidget);

      // Go to Minhas Listas tab and verify it's there
      await tester.tap(find.text('Minhas Listas'));
      await tester.pumpAndSettle();

      expect(find.text('Festinha'), findsOneWidget);
      expect(find.text('1 item'), findsOneWidget);
    });

    testWidgets('cria uma lista nova a partir do ProductDetailScreen e adiciona o produto', (tester) async {
      final container = await buildContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProductDetailScreen(productId: 'p01'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify page loaded
      expect(find.text('Leite Integral'), findsWidgets);

      // Scroll to button and tap
      final addToListBtn = find.text('Adicionar à Lista...');
      await tester.ensureVisible(addToListBtn);
      await tester.pumpAndSettle();
      await tester.tap(addToListBtn);
      await tester.pumpAndSettle();

      // Bottom sheet is visible
      expect(find.text('Adicionar à Lista'), findsOneWidget);

      // Tap on the Nova Lista icon button (plus icon)
      await tester.tap(find.byIcon(LucideIcons.plus));
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.text('Criar Nova Lista'), findsOneWidget);

      // Enter name and confirm
      await tester.enterText(find.byType(TextField), 'Lista Café');
      await tester.tap(find.text('Criar e Adicionar'));
      await tester.pumpAndSettle();

      // Verify success message/SnackBar
      expect(find.textContaining('Leite Integral adicionado à lista "Lista Café"!'), findsOneWidget);

      // Verify the list has indeed been created in the provider
      final lists = container.read(shoppingListsProvider);
      expect(lists, hasLength(1));
      expect(lists.first.name, equals('Lista Café'));
      expect(lists.first.items, hasLength(1));
      expect(lists.first.items.first.productId, equals('p01'));
    });
  });
}

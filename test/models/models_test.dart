import 'package:flutter_test/flutter_test.dart';
import 'package:lista_smart/features/auth/domain/user.dart';
import 'package:lista_smart/features/profile/domain/vehicle.dart';
import 'package:lista_smart/features/profile/domain/product.dart';
import 'package:lista_smart/features/shopping_list/domain/cart_item.dart';
import 'package:lista_smart/features/smart_coins/domain/coin_transaction.dart';

void main() {
  group('User model', () {
    test('round-trips toJson/fromJson with all fields', () {
      const user = User(
        id: 'u1',
        name: 'José Augusto',
        email: 'jose@example.com',
        address: 'Rua das Flores, 123',
        coinBalance: 150,
      );

      final json = user.toJson();
      final restored = User.fromJson(json);

      expect(restored.id, equals(user.id));
      expect(restored.name, equals(user.name));
      expect(restored.email, equals(user.email));
      expect(restored.address, equals(user.address));
      expect(restored.coinBalance, equals(user.coinBalance));
    });

    test('fromJson handles missing optional fields with defaults', () {
      final json = {
        'id': 'u2',
        'name': 'Ana',
        'email': 'ana@example.com',
      };

      final user = User.fromJson(json);

      expect(user.address, equals(''));
      expect(user.coinBalance, equals(0));
    });
  });

  group('Vehicle model', () {
    test('round-trips toJson/fromJson', () {
      const vehicle = Vehicle(
        id: 'v1',
        model: 'Honda Civic',
        fuelEfficiencyKmPerLiter: 12.5,
      );

      final json = vehicle.toJson();
      final restored = Vehicle.fromJson(json);

      expect(restored.id, equals(vehicle.id));
      expect(restored.model, equals(vehicle.model));
      expect(restored.fuelEfficiencyKmPerLiter,
          equals(vehicle.fuelEfficiencyKmPerLiter));
    });
  });

  group('Product model', () {
    test('round-trips toJson/fromJson including tags list', () {
      const product = Product(
        id: 'p1',
        name: 'Leite Integral',
        brand: 'Tirol',
        category: 'Laticínios',
        imageUrl: 'https://example.com/leite.png',
        averagePrice: 5.99,
        tags: ['laticínio', 'bebida', 'integral'],
      );

      final json = product.toJson();
      final restored = Product.fromJson(json);

      expect(restored.id, equals(product.id));
      expect(restored.name, equals(product.name));
      expect(restored.brand, equals(product.brand));
      expect(restored.category, equals(product.category));
      expect(restored.imageUrl, equals(product.imageUrl));
      expect(restored.averagePrice, equals(product.averagePrice));
      expect(restored.tags, equals(product.tags));
    });
  });

  group('CartItem model', () {
    test('round-trips toJson/fromJson', () {
      const item = CartItem(
        productId: 'p1',
        productName: 'Leite Integral',
        brand: 'Tirol',
        imageUrl: 'https://example.com/leite.png',
        quantity: 3,
        unitPrice: 5.99,
      );

      final json = item.toJson();
      final restored = CartItem.fromJson(json);

      expect(restored.productId, equals(item.productId));
      expect(restored.productName, equals(item.productName));
      expect(restored.brand, equals(item.brand));
      expect(restored.imageUrl, equals(item.imageUrl));
      expect(restored.quantity, equals(item.quantity));
      expect(restored.unitPrice, equals(item.unitPrice));
    });
  });

  group('CoinTransaction model', () {
    test('round-trips toJson/fromJson with positive amount (gain)', () {
      final tx = CoinTransaction(
        id: 'tx1',
        description: 'Nota fiscal cadastrada',
        amount: 10,
        createdAt: DateTime.utc(2026, 6, 1, 12, 0, 0),
      );

      final json = tx.toJson();
      final restored = CoinTransaction.fromJson(json);

      expect(restored.id, equals(tx.id));
      expect(restored.description, equals(tx.description));
      expect(restored.amount, equals(tx.amount));
      expect(restored.createdAt, equals(tx.createdAt));
    });

    test('round-trips toJson/fromJson with negative amount (redemption)', () {
      final tx = CoinTransaction(
        id: 'tx2',
        description: 'Resgate de moedas',
        amount: -50,
        createdAt: DateTime.utc(2026, 5, 15, 10, 30, 0),
      );

      final json = tx.toJson();
      final restored = CoinTransaction.fromJson(json);

      expect(restored.amount, equals(-50));
      expect(restored.createdAt, equals(tx.createdAt));
    });
  });
}

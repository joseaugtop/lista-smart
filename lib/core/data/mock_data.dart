import '../../features/auth/domain/user.dart';
import '../../features/profile/domain/product.dart';
import '../../features/smart_coins/domain/coin_transaction.dart';

abstract class MockData {
  static const User user = User(
    id: 'jose_augusto_001',
    name: 'José Augusto',
    email: 'jose.rocha@zorte.com.br',
    address: 'Criciúma, SC',
    coinBalance: 750,
  );

  static const List<Product> products = [
    // Laticínios
    Product(
      id: 'p01',
      name: 'Leite Integral',
      brand: 'Tirol',
      category: 'Laticínios',
      imageUrl: '',
      averagePrice: 5.49,
      tags: ['laticínio', 'bebida'],
    ),
    Product(
      id: 'p02',
      name: 'Queijo Mussarela',
      brand: 'Tirolez',
      category: 'Laticínios',
      imageUrl: '',
      averagePrice: 38.90,
      tags: ['laticínio', 'fatiado'],
    ),
    Product(
      id: 'p03',
      name: 'Iogurte Natural',
      brand: 'Danone',
      category: 'Laticínios',
      imageUrl: '',
      averagePrice: 4.79,
      tags: ['laticínio', 'probiótico'],
    ),
    // Frutas e verduras
    Product(
      id: 'p04',
      name: 'Banana Prata',
      brand: 'Hortifruti',
      category: 'Frutas e verduras',
      imageUrl: '',
      averagePrice: 6.99,
      tags: ['fruta', 'natural'],
    ),
    Product(
      id: 'p05',
      name: 'Tomate',
      brand: 'Hortifruti',
      category: 'Frutas e verduras',
      imageUrl: '',
      averagePrice: 8.49,
      tags: ['verdura', 'tempero'],
    ),
    Product(
      id: 'p06',
      name: 'Alface Crespa',
      brand: 'Hortifruti',
      category: 'Frutas e verduras',
      imageUrl: '',
      averagePrice: 3.29,
      tags: ['verdura', 'folhosa'],
    ),
    // Limpeza e higiene
    Product(
      id: 'p07',
      name: 'Detergente Líquido',
      brand: 'Ypê',
      category: 'Limpeza e higiene',
      imageUrl: '',
      averagePrice: 2.49,
      tags: ['limpeza', 'louça'],
    ),
    Product(
      id: 'p08',
      name: 'Sabão em Pó',
      brand: 'OMO',
      category: 'Limpeza e higiene',
      imageUrl: '',
      averagePrice: 19.90,
      tags: ['limpeza', 'roupa'],
    ),
    Product(
      id: 'p09',
      name: 'Shampoo',
      brand: 'Seda',
      category: 'Limpeza e higiene',
      imageUrl: '',
      averagePrice: 12.99,
      tags: ['higiene', 'cabelo'],
    ),
    // Padaria e granel
    Product(
      id: 'p10',
      name: 'Pão de Forma',
      brand: 'Wickbold',
      category: 'Padaria e granel',
      imageUrl: '',
      averagePrice: 8.99,
      tags: ['padaria', 'carboidrato'],
    ),
    Product(
      id: 'p11',
      name: 'Arroz Branco',
      brand: 'Camil',
      category: 'Padaria e granel',
      imageUrl: '',
      averagePrice: 24.90,
      tags: ['granel', 'carboidrato'],
    ),
    Product(
      id: 'p12',
      name: 'Feijão Carioca',
      brand: 'Camil',
      category: 'Padaria e granel',
      imageUrl: '',
      averagePrice: 9.49,
      tags: ['granel', 'proteína'],
    ),
  ];

  static const Map<String, double> supermarketDistances = {
    'Bistek': 2.3,
    'Giassi': 3.7,
    'Angeloni': 4.1,
    'Atacadão': 6.8,
  };

  static List<CoinTransaction> get initialTransactions => [
        CoinTransaction(
          id: '1',
          description: 'Bônus de boas-vindas',
          amount: 500,
          createdAt: DateTime(2026, 5, 1),
        ),
        CoinTransaction(
          id: '2',
          description: 'Primeira nota fiscal cadastrada',
          amount: 250,
          createdAt: DateTime(2026, 5, 15),
        ),
      ];
}

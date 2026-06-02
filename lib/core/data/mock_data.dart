import '../../features/auth/domain/user.dart';
import '../../features/profile/domain/nutritional_info.dart';
import '../../features/profile/domain/product.dart';
import '../../features/profile/domain/vehicle.dart';
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
      imageUrl:
          'https://bistek.vtexassets.com/arquivos/ids/207160-800-800?v=638888095157130000&width=800&height=800&aspect=true',
      averagePrice: 5.49,
      tags: ['laticínio', 'bebida'],
      department: 'Alimentos',
      subcategory: 'Leite UHT',
      ean: '7891058009011',
      nutritionalInfo: NutritionalInfo(
        calories: 61, protein: 3.2, carbs: 4.7, fat: 3.2,
        fiber: 0, sodium: 48, servingSize: '200ml',
      ),
    ),
    Product(
      id: 'p02',
      name: 'Queijo Mussarela',
      brand: 'Tirolez',
      category: 'Laticínios',
      imageUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRmX1xQdi7nHDZ4R3gQEnrKfINtDegM3KzvFw&s',
      averagePrice: 38.90,
      tags: ['laticínio', 'fatiado'],
      department: 'Alimentos',
      subcategory: 'Queijos',
      ean: '7896015500157',
      nutritionalInfo: NutritionalInfo(
        calories: 264, protein: 18.2, carbs: 2.1, fat: 20.0,
        fiber: 0, sodium: 610, servingSize: '30g',
      ),
    ),
    Product(
      id: 'p03',
      name: 'Iogurte Natural',
      brand: 'Danone',
      category: 'Laticínios',
      imageUrl:
          'https://tauste.com.br/media/catalog/product/cache/207e23213cf636ccdef205098cf3c8a3/1/4/1483121777414119.jpg',
      averagePrice: 4.79,
      tags: ['laticínio', 'probiótico'],
      department: 'Alimentos',
      subcategory: 'Iogurtes',
      ean: '7891025100418',
      nutritionalInfo: NutritionalInfo(
        calories: 55, protein: 4.3, carbs: 6.2, fat: 1.5,
        fiber: 0, sodium: 55, servingSize: '100g',
      ),
    ),
    // Frutas e verduras
    Product(
      id: 'p04',
      name: 'Banana Prata',
      brand: 'Hortifruti',
      category: 'Frutas e verduras',
      imageUrl:
          'https://ceagesp.gov.br/wp-content/uploads/2019/12/Banana_pratapng-328x328.png',
      averagePrice: 6.99,
      tags: ['fruta', 'natural'],
      department: 'Hortifruti',
      subcategory: 'Frutas',
      ean: '2000000000014',
      nutritionalInfo: NutritionalInfo(
        calories: 98, protein: 1.3, carbs: 22.8, fat: 0.1,
        fiber: 2.0, sodium: 1, servingSize: '100g',
      ),
    ),
    Product(
      id: 'p05',
      name: 'Tomate',
      brand: 'Hortifruti',
      category: 'Frutas e verduras',
      imageUrl:
          'https://www.proativaalimentos.com.br/image/cache/catalog/img_prod/Tomate-Cereja-6[1]-1000x1000.jpg',
      averagePrice: 8.49,
      tags: ['verdura', 'tempero'],
      department: 'Hortifruti',
      subcategory: 'Legumes',
      ean: '2000000000021',
      nutritionalInfo: NutritionalInfo(
        calories: 15, protein: 0.9, carbs: 2.9, fat: 0.2,
        fiber: 1.2, sodium: 5, servingSize: '100g',
      ),
    ),
    Product(
      id: 'p06',
      name: 'Alface Crespa',
      brand: 'Hortifruti',
      category: 'Frutas e verduras',
      imageUrl:
          'https://redemix.vteximg.com.br/arquivos/ids/214350-1000-1000/7898903384029.jpg?v=638350625838000000',
      averagePrice: 3.29,
      tags: ['verdura', 'folhosa'],
      department: 'Hortifruti',
      subcategory: 'Folhosas',
      ean: '2000000000038',
      nutritionalInfo: NutritionalInfo(
        calories: 13, protein: 1.4, carbs: 1.5, fat: 0.2,
        fiber: 1.3, sodium: 9, servingSize: '100g',
      ),
    ),
    // Limpeza e higiene
    Product(
      id: 'p07',
      name: 'Detergente Líquido',
      brand: 'Ypê',
      category: 'Limpeza e higiene',
      imageUrl:
          'https://applicativa-marketplace-prod.s3.amazonaws.com/produtos/detergente-lquido-neutro-yp-500ml-0-7896098900208.webp',
      averagePrice: 2.49,
      tags: ['limpeza', 'louça'],
      department: 'Limpeza',
      subcategory: 'Lava-louça',
      ean: '7896098900208',
    ),
    Product(
      id: 'p08',
      name: 'Sabão em Pó',
      brand: 'OMO',
      category: 'Limpeza e higiene',
      imageUrl:
          'https://m.media-amazon.com/images/I/71bXBFl912L._AC_SL1500_.jpg',
      averagePrice: 19.90,
      tags: ['limpeza', 'roupa'],
      department: 'Limpeza',
      subcategory: 'Lava-roupas',
      ean: '7891150078482',
    ),
    Product(
      id: 'p09',
      name: 'Shampoo',
      brand: 'Seda',
      category: 'Limpeza e higiene',
      imageUrl:
          'https://destro.fbitsstatic.net/img/p/shampoo-seda-liso-extremo-325ml-70857/257393.jpg?w=500&h=500&v=202501231555&qs=ignore',
      averagePrice: 12.99,
      tags: ['higiene', 'cabelo'],
      department: 'Higiene',
      subcategory: 'Shampoos',
      ean: '7891150029218',
    ),
    // Padaria e granel
    Product(
      id: 'p10',
      name: 'Pão de Forma',
      brand: 'Wickbold',
      category: 'Padaria e granel',
      imageUrl:
          'https://storetheme.vtexassets.com/unsafe/800x800/center/middle/https%3A%2F%2Fsantaluzia.vtexassets.com%2Farquivos%2Fids%2F1000842%2F20240724_Do_Forno_Original_Wickbold_450g_V0724_FRENTE.png%3Fv%3D638863661472100000',
      averagePrice: 8.99,
      tags: ['padaria', 'carboidrato'],
      department: 'Alimentos',
      subcategory: 'Pães',
      ean: '7622300488710',
      nutritionalInfo: NutritionalInfo(
        calories: 252, protein: 8.0, carbs: 46.0, fat: 3.5,
        fiber: 2.5, sodium: 430, servingSize: '50g (2 fatias)',
      ),
    ),
    Product(
      id: 'p11',
      name: 'Arroz Branco',
      brand: 'Camil',
      category: 'Padaria e granel',
      imageUrl:
          'https://m.media-amazon.com/images/I/81-Yw7YyRBL._AC_UF894,1000_QL80_.jpg',
      averagePrice: 24.90,
      tags: ['granel', 'carboidrato'],
      department: 'Alimentos',
      subcategory: 'Arroz',
      ean: '7896006700066',
      nutritionalInfo: NutritionalInfo(
        calories: 360, protein: 7.0, carbs: 79.0, fat: 0.5,
        fiber: 1.5, sodium: 0, servingSize: '100g (cru)',
      ),
    ),
    Product(
      id: 'p12',
      name: 'Feijão Carioca',
      brand: 'Camil',
      category: 'Padaria e granel',
      imageUrl:
          'https://remembrstore.com/cdn/shop/files/remembr-default-title-camil-feijao-carioca-1kg-brazilian-pinto-beans-35865911755043.jpg?v=1776376488',
      averagePrice: 9.49,
      tags: ['granel', 'proteína'],
      department: 'Alimentos',
      subcategory: 'Feijões',
      ean: '7896006701094',
      nutritionalInfo: NutritionalInfo(
        calories: 329, protein: 22.0, carbs: 57.0, fat: 1.3,
        fiber: 19.0, sodium: 10, servingSize: '100g (cru)',
      ),
    ),
  ];

  static const double fuelPrice = 6.50;

  static const Vehicle vehicle = Vehicle(
    id: 'vehicle_default',
    model: 'Fiat Uno',
    fuelEfficiencyKmPerLiter: 12.0,
  );

  static const Map<String, Map<String, double>> prices = {
    'p01': {'Bistek': 5.29, 'Giassi': 5.49, 'Angeloni': 5.69, 'Atacadão': 4.99},
    'p02': {
      'Bistek': 37.90,
      'Giassi': 39.90,
      'Angeloni': 41.50,
      'Atacadão': 35.80
    },
    'p03': {'Bistek': 4.59, 'Giassi': 4.79, 'Angeloni': 4.99, 'Atacadão': 4.39},
    'p04': {'Bistek': 6.79, 'Giassi': 6.99, 'Angeloni': 7.19, 'Atacadão': 6.49},
    'p05': {'Bistek': 8.29, 'Giassi': 8.49, 'Angeloni': 8.69, 'Atacadão': 7.99},
    'p06': {'Bistek': 3.09, 'Giassi': 3.29, 'Angeloni': 3.49, 'Atacadão': 2.99},
    'p07': {'Bistek': 2.29, 'Giassi': 2.49, 'Angeloni': 2.69, 'Atacadão': 2.09},
    'p08': {
      'Bistek': 18.90,
      'Giassi': 19.90,
      'Angeloni': 21.50,
      'Atacadão': 17.50
    },
    'p09': {
      'Bistek': 12.49,
      'Giassi': 12.99,
      'Angeloni': 13.49,
      'Atacadão': 11.99
    },
    'p10': {'Bistek': 8.49, 'Giassi': 8.99, 'Angeloni': 9.49, 'Atacadão': 7.99},
    'p11': {
      'Bistek': 23.90,
      'Giassi': 24.90,
      'Angeloni': 25.90,
      'Atacadão': 22.50
    },
    'p12': {'Bistek': 9.09, 'Giassi': 9.49, 'Angeloni': 9.99, 'Atacadão': 8.69},
  };

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

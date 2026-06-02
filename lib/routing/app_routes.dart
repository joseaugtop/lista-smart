abstract class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String shoppingList = '/shopping-list';
  static const String comparison = '/comparison';
  static const String store = '/store';
  static const String profile = '/profile';
  static const String scanner = '/scanner';
  static const String productDetailPattern = '/home/product/:productId';
  static const String comparisonResult = '/shopping-list/comparison';
  static String productDetailPath(String productId) => '/home/product/$productId';
}

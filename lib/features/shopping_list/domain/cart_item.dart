import 'package:flutter/foundation.dart' show immutable;

@immutable
class CartItem {
  const CartItem({
    required this.productId,
    required this.productName,
    required this.brand,
    required this.imageUrl,
    required this.quantity,
    required this.unitPrice,
  });

  final String productId;
  final String productName;
  final String brand;
  final String imageUrl;
  final int quantity;
  final double unitPrice;

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        brand: json['brand'] as String,
        imageUrl: json['imageUrl'] as String,
        quantity: json['quantity'] as int,
        unitPrice: (json['unitPrice'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'brand': brand,
        'imageUrl': imageUrl,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };

  CartItem copyWith({
    String? productId,
    String? productName,
    String? brand,
    String? imageUrl,
    int? quantity,
    double? unitPrice,
  }) =>
      CartItem(
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        brand: brand ?? this.brand,
        imageUrl: imageUrl ?? this.imageUrl,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
      );
}

import 'package:flutter/foundation.dart' show immutable;

@immutable
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.imageUrl,
    required this.averagePrice,
    required this.tags,
  });

  final String id;
  final String name;
  final String brand;
  final String category;
  final String imageUrl;
  final double averagePrice;
  final List<String> tags;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        brand: json['brand'] as String,
        category: json['category'] as String,
        imageUrl: json['imageUrl'] as String,
        averagePrice: (json['averagePrice'] as num).toDouble(),
        tags: (json['tags'] as List<dynamic>).cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'category': category,
        'imageUrl': imageUrl,
        'averagePrice': averagePrice,
        'tags': List<String>.from(tags),
      };

  Product copyWith({
    String? id,
    String? name,
    String? brand,
    String? category,
    String? imageUrl,
    double? averagePrice,
    List<String>? tags,
  }) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        brand: brand ?? this.brand,
        category: category ?? this.category,
        imageUrl: imageUrl ?? this.imageUrl,
        averagePrice: averagePrice ?? this.averagePrice,
        tags: tags ?? this.tags,
      );
}

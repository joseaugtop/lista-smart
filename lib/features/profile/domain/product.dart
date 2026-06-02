import 'package:flutter/foundation.dart' show immutable;

import 'nutritional_info.dart';

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
    this.ean = '',
    this.subcategory = '',
    this.department = '',
    this.nutritionalInfo,
  });

  final String id;
  final String name;
  final String brand;
  final String category;
  final String imageUrl;
  final double averagePrice;
  final List<String> tags;
  final String ean;
  final String subcategory;
  final String department;
  final NutritionalInfo? nutritionalInfo;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        brand: json['brand'] as String,
        category: json['category'] as String,
        imageUrl: json['imageUrl'] as String,
        averagePrice: (json['averagePrice'] as num).toDouble(),
        tags: (json['tags'] as List<dynamic>).cast<String>(),
        ean: json['ean'] as String? ?? '',
        subcategory: json['subcategory'] as String? ?? '',
        department: json['department'] as String? ?? '',
        nutritionalInfo: json['nutritionalInfo'] != null
            ? NutritionalInfo.fromJson(
                json['nutritionalInfo'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'category': category,
        'imageUrl': imageUrl,
        'averagePrice': averagePrice,
        'tags': List<String>.from(tags),
        'ean': ean,
        'subcategory': subcategory,
        'department': department,
        if (nutritionalInfo != null) 'nutritionalInfo': nutritionalInfo!.toJson(),
      };

  Product copyWith({
    String? id,
    String? name,
    String? brand,
    String? category,
    String? imageUrl,
    double? averagePrice,
    List<String>? tags,
    String? ean,
    String? subcategory,
    String? department,
    NutritionalInfo? nutritionalInfo,
  }) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        brand: brand ?? this.brand,
        category: category ?? this.category,
        imageUrl: imageUrl ?? this.imageUrl,
        averagePrice: averagePrice ?? this.averagePrice,
        tags: tags ?? this.tags,
        ean: ean ?? this.ean,
        subcategory: subcategory ?? this.subcategory,
        department: department ?? this.department,
        nutritionalInfo: nutritionalInfo ?? this.nutritionalInfo,
      );
}

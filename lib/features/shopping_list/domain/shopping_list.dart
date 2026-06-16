import 'package:flutter/foundation.dart' show immutable;
import 'cart_item.dart';

@immutable
class ShoppingList {
  const ShoppingList({
    required this.id,
    required this.name,
    required this.items,
  });

  final String id;
  final String name;
  final List<CartItem> items;

  factory ShoppingList.fromJson(Map<String, dynamic> json) => ShoppingList(
        id: json['id'] as String,
        name: json['name'] as String,
        items: (json['items'] as List<dynamic>)
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': items.map((e) => e.toJson()).toList(),
      };

  ShoppingList copyWith({
    String? id,
    String? name,
    List<CartItem>? items,
  }) =>
      ShoppingList(
        id: id ?? this.id,
        name: name ?? this.name,
        items: items ?? this.items,
      );
}

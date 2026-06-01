import 'package:flutter/foundation.dart' show immutable;

@immutable
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.address = '',
    this.coinBalance = 0,
  });

  final String id;
  final String name;
  final String email;
  final String address;
  final int coinBalance;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        address: json['address'] as String? ?? '',
        coinBalance: json['coinBalance'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'address': address,
        'coinBalance': coinBalance,
      };

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? address,
    int? coinBalance,
  }) =>
      User(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        address: address ?? this.address,
        coinBalance: coinBalance ?? this.coinBalance,
      );
}

import 'package:flutter/foundation.dart' show immutable;

@immutable
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.address = '',
    this.coinBalance = 0,
    this.vehicleModel = '',
    this.fuelEfficiency = 0.0,
  });

  final String id;
  final String name;
  final String email;
  final String address;
  final int coinBalance;
  final String vehicleModel;
  final double fuelEfficiency;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        address: json['address'] as String? ?? '',
        coinBalance: json['coinBalance'] as int? ?? 0,
        vehicleModel: json['vehicleModel'] as String? ?? '',
        fuelEfficiency: (json['fuelEfficiency'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'address': address,
        'coinBalance': coinBalance,
        'vehicleModel': vehicleModel,
        'fuelEfficiency': fuelEfficiency,
      };

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? address,
    int? coinBalance,
    String? vehicleModel,
    double? fuelEfficiency,
  }) =>
      User(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        address: address ?? this.address,
        coinBalance: coinBalance ?? this.coinBalance,
        vehicleModel: vehicleModel ?? this.vehicleModel,
        fuelEfficiency: fuelEfficiency ?? this.fuelEfficiency,
      );
}

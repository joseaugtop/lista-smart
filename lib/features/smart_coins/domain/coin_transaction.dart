import 'package:flutter/foundation.dart' show immutable;

@immutable
class CoinTransaction {
  const CoinTransaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.createdAt,
  });

  final String id;
  final String description;

  /// Positive = coin gain (e.g. fiscal receipt registration).
  /// Negative = coin redemption.
  final int amount;
  final DateTime createdAt;

  factory CoinTransaction.fromJson(Map<String, dynamic> json) =>
      CoinTransaction(
        id: json['id'] as String,
        description: json['description'] as String,
        amount: json['amount'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'createdAt': createdAt.toIso8601String(),
      };

  CoinTransaction copyWith({
    String? id,
    String? description,
    int? amount,
    DateTime? createdAt,
  }) =>
      CoinTransaction(
        id: id ?? this.id,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        createdAt: createdAt ?? this.createdAt,
      );
}

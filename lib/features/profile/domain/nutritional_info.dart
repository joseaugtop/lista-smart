import 'package:flutter/foundation.dart' show immutable;

@immutable
class NutritionalInfo {
  const NutritionalInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sodium,
    required this.servingSize,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sodium;
  final String servingSize;

  factory NutritionalInfo.fromJson(Map<String, dynamic> json) => NutritionalInfo(
        calories: (json['calories'] as num).toDouble(),
        protein: (json['protein'] as num).toDouble(),
        carbs: (json['carbs'] as num).toDouble(),
        fat: (json['fat'] as num).toDouble(),
        fiber: (json['fiber'] as num).toDouble(),
        sodium: (json['sodium'] as num).toDouble(),
        servingSize: json['servingSize'] as String,
      );

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'sodium': sodium,
        'servingSize': servingSize,
      };
}

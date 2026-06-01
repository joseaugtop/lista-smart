import 'package:flutter/foundation.dart' show immutable;

@immutable
class Vehicle {
  const Vehicle({
    required this.id,
    required this.model,
    required this.fuelEfficiencyKmPerLiter,
  });

  final String id;
  final String model;
  final double fuelEfficiencyKmPerLiter;

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as String,
        model: json['model'] as String,
        fuelEfficiencyKmPerLiter:
            (json['fuelEfficiencyKmPerLiter'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'model': model,
        'fuelEfficiencyKmPerLiter': fuelEfficiencyKmPerLiter,
      };

  Vehicle copyWith({
    String? id,
    String? model,
    double? fuelEfficiencyKmPerLiter,
  }) =>
      Vehicle(
        id: id ?? this.id,
        model: model ?? this.model,
        fuelEfficiencyKmPerLiter:
            fuelEfficiencyKmPerLiter ?? this.fuelEfficiencyKmPerLiter,
      );
}

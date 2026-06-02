import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import 'cart_notifier.dart';
import 'fuel_toggle_notifier.dart';
import 'prices_provider.dart';
import 'vehicle_provider.dart';

@immutable
class SupermarketTotal {
  const SupermarketTotal({
    required this.supermarket,
    required this.productsCost,
    required this.fuelCost,
    required this.distanceKm,
    required this.totalCost,
  });

  final String supermarket;
  final double productsCost;
  final double fuelCost;
  final double distanceKm;
  final double totalCost;
}

final comparisonResultsProvider = Provider<List<SupermarketTotal>>((ref) {
  final cart = ref.watch(cartProvider);
  final prices = ref.watch(pricesProvider);
  final vehicle = ref.watch(vehicleProvider);
  final fuelToggle = ref.watch(fuelToggleProvider);
  const double fuelPrice = MockData.fuelPrice;
  const distances = MockData.supermarketDistances;

  return distances.entries.map((entry) {
    final supermarket = entry.key;
    final distanceKm = entry.value;
    final productsCost = cart.fold<double>(0.0, (sum, item) {
      final price = prices[item.productId]?[supermarket] ?? item.unitPrice;
      return sum + price * item.quantity;
    });
    // CRITICAL: use vehicle.fuelEfficiencyKmPerLiter (NOT fuelEfficiency)
    final fuelCost = fuelToggle
        ? (distanceKm * 2 / vehicle.fuelEfficiencyKmPerLiter) * fuelPrice
        : 0.0;
    return SupermarketTotal(
      supermarket: supermarket,
      productsCost: productsCost,
      fuelCost: fuelCost,
      distanceKm: distanceKm,
      totalCost: productsCost + fuelCost,
    );
  }).toList()
    ..sort((a, b) => a.totalCost.compareTo(b.totalCost));
});

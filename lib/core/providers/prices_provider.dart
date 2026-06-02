import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';

final pricesProvider =
    Provider<Map<String, Map<String, double>>>((ref) => MockData.prices);

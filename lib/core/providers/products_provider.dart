import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../../features/profile/domain/product.dart';

final productsProvider = Provider<List<Product>>((ref) => MockData.products);

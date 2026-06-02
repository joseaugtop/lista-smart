import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../../features/profile/domain/vehicle.dart';

final vehicleProvider = Provider<Vehicle>((ref) => MockData.vehicle);

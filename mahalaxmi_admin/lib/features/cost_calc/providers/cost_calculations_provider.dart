import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahalaxmi_shared/mahalaxmi_shared.dart';

import '../repository/cost_calculations_repository.dart';

final costCalculationsRepositoryProvider =
    Provider<CostCalculationsRepository>((ref) {
  return CostCalculationsRepository();
});

final costCalculationsProvider = FutureProvider<List<CostCalculation>>((ref) {
  return ref.read(costCalculationsRepositoryProvider).getAll();
});

final costCalculationsByCategoryProvider =
    FutureProvider.family<List<CostCalculation>, String>((ref, category) {
  return ref.read(costCalculationsRepositoryProvider).getByCategory(category);
});

import 'package:riverpod/riverpod.dart';

import 'repository_providers.dart';

final defaultMarginProvider = FutureProvider<double>((ref) {
  return ref.read(settingsRepositoryProvider).getDefaultMargin();
});

final labourCostProvider = FutureProvider<double>((ref) {
  return ref.read(settingsRepositoryProvider).getLabourCost();
});

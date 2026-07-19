import 'package:riverpod/riverpod.dart';

import '../models/chuda_customization_option.dart';
import 'repository_providers.dart';

final chudaCustomizationOptionsProvider =
    FutureProvider<List<ChudaCustomizationOption>>((ref) async {
  final repo = ref.read(chudaCustomizationRepositoryProvider);
  return await repo.getActiveOptions();
});

final chudaPattiOptionsProvider = Provider<List<ChudaCustomizationOption>>((ref) {
  final all = ref.watch(chudaCustomizationOptionsProvider).valueOrNull ?? [];
  return all.where((o) => o.groupType == 'patti').toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
});

final chudaColorOptionsProvider = Provider<List<ChudaCustomizationOption>>((ref) {
  final all = ref.watch(chudaCustomizationOptionsProvider).valueOrNull ?? [];
  return all.where((o) => o.groupType == 'color').toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
});

final chudaBoxOptionsProvider = Provider<List<ChudaCustomizationOption>>((ref) {
  final all = ref.watch(chudaCustomizationOptionsProvider).valueOrNull ?? [];
  return all.where((o) => o.groupType == 'box').toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
});

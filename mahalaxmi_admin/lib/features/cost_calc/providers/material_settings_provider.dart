import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repository/material_settings_repository.dart';

final materialSettingsRepositoryProvider =
    Provider<MaterialSettingsRepository>((ref) {
  return MaterialSettingsRepository();
});

final materialSettingsProvider =
    FutureProvider<Map<String, dynamic>?>((ref) {
  return ref.read(materialSettingsRepositoryProvider).get();
});

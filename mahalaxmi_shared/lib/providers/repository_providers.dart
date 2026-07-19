import 'package:riverpod/riverpod.dart';

import '../repositories/category_repository.dart';
import '../repositories/customer_repository.dart';
import '../repositories/item_repository.dart';
import '../repositories/material_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/chuda_customization_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/tag_repository.dart';
import '../repositories/cutmail_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository();
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

final tagRepositoryProvider = Provider<TagRepository>((ref) {
  return TagRepository();
});

final materialRepositoryProvider = Provider<MaterialRepository>((ref) {
  return MaterialRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final chudaCustomizationRepositoryProvider =
    Provider<ChudaCustomizationRepository>((ref) {
  return ChudaCustomizationRepository();
});

final cutmailRepositoryProvider = Provider<CutmailRepository>((ref) {
  return CutmailRepository();
});

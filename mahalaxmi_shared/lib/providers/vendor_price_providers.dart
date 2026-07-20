import 'package:riverpod/riverpod.dart';

import '../models/vendor_price.dart';
import 'repository_providers.dart';

final allVendorPricesProvider = FutureProvider<List<VendorPrice>>((ref) {
  return ref.read(vendorPriceRepositoryProvider).getAll();
});

final vendorPricesByCategoryProvider =
    FutureProvider.family<List<VendorPrice>, String>((ref, category) {
  return ref.read(vendorPriceRepositoryProvider).getByCategory(category);
});

final vendorPricesByVendorProvider =
    FutureProvider.family<List<VendorPrice>, String>((ref, vendorName) {
  return ref.read(vendorPriceRepositoryProvider).getByVendor(vendorName);
});

final vendorPriceByIdProvider =
    FutureProvider.family<VendorPrice?, String>((ref, id) {
  return ref.read(vendorPriceRepositoryProvider).getById(id);
});

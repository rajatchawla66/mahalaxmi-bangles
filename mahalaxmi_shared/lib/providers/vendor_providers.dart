import 'package:riverpod/riverpod.dart';

import '../models/vendor_master.dart';
import 'repository_providers.dart';

final activeVendorsProvider = FutureProvider<List<VendorMaster>>((ref) {
  return ref.read(vendorRepositoryProvider).getVendors(activeOnly: true);
});

final allVendorsProvider = FutureProvider<List<VendorMaster>>((ref) {
  return ref.read(vendorRepositoryProvider).getVendors();
});

final vendorNamesProvider = FutureProvider<List<String>>((ref) {
  return ref.read(vendorRepositoryProvider).getVendorNames();
});

import 'package:riverpod/riverpod.dart';

import '../models/item.dart';
import '../services/ledger_service.dart';
import 'repository_providers.dart';
import 'vendor_price_providers.dart';

final ledgerServiceProvider = Provider<LedgerService>((ref) {
  return LedgerService();
});

final allRateItemsProvider = FutureProvider<List<RateItem>>((ref) {
  return ref.read(itemRepositoryProvider).getAllItems();
});

final allLedgerItemsProvider = FutureProvider<List<LedgerItem>>((ref) async {
  final rateItems = await ref.read(allRateItemsProvider.future);
  final vendorPrices = await ref.read(allVendorPricesProvider.future);
  final service = ref.read(ledgerServiceProvider);
  return service.merge(rateItems: rateItems, vendorPrices: vendorPrices);
});

final ledgerCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final items = await ref.read(allRateItemsProvider.future);
  final categories = items.map((i) => i.category).toSet().toList()..sort();
  return categories;
});

final ledgerVendorsProvider = FutureProvider<List<String>>((ref) async {
  final rateItems = await ref.read(allRateItemsProvider.future);
  final vendorPrices = await ref.read(allVendorPricesProvider.future);
  final service = ref.read(ledgerServiceProvider);
  final vendors = service.extractVendors(
    rateItems: rateItems,
    vendorPrices: vendorPrices,
  );
  final list = vendors.toList()..sort();
  return list;
});

final ledgerItemsByCategoryProvider =
    FutureProvider.family<List<LedgerItem>, String>((ref, category) async {
  final rateItems = await ref.read(allRateItemsProvider.future);
  final vendorPrices = await ref.read(allVendorPricesProvider.future);
  final service = ref.read(ledgerServiceProvider);
  return service.filterByCategory(
    rateItems: rateItems,
    vendorPrices: vendorPrices,
    category: category,
  );
});

final ledgerItemsByVendorProvider =
    FutureProvider.family<List<LedgerItem>, String>((ref, vendor) async {
  final rateItems = await ref.read(allRateItemsProvider.future);
  final vendorPrices = await ref.read(allVendorPricesProvider.future);
  final service = ref.read(ledgerServiceProvider);
  return service.filterByVendor(
    rateItems: rateItems,
    vendorPrices: vendorPrices,
    vendor: vendor,
  );
});

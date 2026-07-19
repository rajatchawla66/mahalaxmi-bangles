import 'package:riverpod/riverpod.dart';

import '../models/item.dart';
import 'repository_providers.dart';

final allItemsProvider = FutureProvider<List<RateItem>>((ref) {
  return ref.read(itemRepositoryProvider).getAllItems();
});

final customerCatalogueProvider = FutureProvider<List<RateItem>>((ref) {
  return ref.read(itemRepositoryProvider).getCustomerCatalogue();
});

final customerItemsByCategoryProvider =
    FutureProvider.family<List<RateItem>, String>((ref, category) {
  return ref.read(itemRepositoryProvider).getCustomerItemsByCategory(category);
});

final itemByNumberProvider =
    FutureProvider.family<RateItem?, String>((ref, itemNumber) {
  return ref.read(itemRepositoryProvider).getItemByNumber(itemNumber);
});

final availableItemsProvider =
    FutureProvider<List<RateItem>>((ref) {
  return ref.read(itemRepositoryProvider).getAvailableItems();
});

final availableItemsByCategoryProvider =
    FutureProvider.family<List<RateItem>, String>((ref, category) {
  return ref.read(itemRepositoryProvider).getAvailableItems(category: category);
});

final pricedItemsProvider = FutureProvider<List<RateItem>>((ref) {
  return ref.read(itemRepositoryProvider).getPricedItems();
});

final unpricedItemsProvider = FutureProvider<List<RateItem>>((ref) {
  return ref.read(itemRepositoryProvider).getUnpricedItems();
});

final rateLookupProvider = FutureProvider<Map<String, RateItem>>((ref) {
  return ref.read(itemRepositoryProvider).getRateLookup();
});

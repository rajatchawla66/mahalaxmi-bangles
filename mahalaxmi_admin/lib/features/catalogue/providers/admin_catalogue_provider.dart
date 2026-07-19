import 'package:riverpod/riverpod.dart';
import 'package:mahalaxmi_shared/models/item.dart';
import 'package:mahalaxmi_shared/models/category.dart';
import 'package:mahalaxmi_shared/providers/repository_providers.dart';
import '../../cost_calc/providers/cost_calculations_provider.dart';

class CategoryWithStats {
  final Category category;
  final int totalItems;
  final int availableItems;
  final int costedItems;

  const CategoryWithStats({
    required this.category,
    this.totalItems = 0,
    this.availableItems = 0,
    this.costedItems = 0,
  });
}

final adminCategoriesWithStatsProvider = FutureProvider<List<CategoryWithStats>>((ref) async {
  final categoryRepo = ref.read(categoryRepositoryProvider);
  final itemRepo = ref.read(itemRepositoryProvider);

  final categories = await categoryRepo.getCategories(activeOnly: false);
  final allItems = await itemRepo.getAllItems();
  final costedNumbers = await ref.read(costCalculatedItemNumbersProvider.future);

  return categories.map((cat) {
    final catItems = allItems.where((i) => i.category == cat.name).toList();
    final catCosted = catItems.where((i) => costedNumbers.contains(i.itemNumber)).length;
    return CategoryWithStats(
      category: cat,
      totalItems: catItems.length,
      availableItems: catItems.where((i) => i.isAvailable).length,
      costedItems: catCosted,
    );
  }).toList();
});

final adminCategoryItemsProvider = FutureProvider.family<List<RateItem>, String>((ref, categoryName) async {
  final repo = ref.read(itemRepositoryProvider);
  return repo.getItemsByCategory(categoryName);
});

final adminMissingPriceItemsProvider = FutureProvider<List<RateItem>>((ref) async {
  final itemRepo = ref.read(itemRepositoryProvider);
  final allItems = await itemRepo.getAllItems();
  return allItems.where((i) => i.sellingPrice == 0.0).toList();
});

final costCalculatedItemNumbersProvider = FutureProvider<Set<String>>((ref) async {
  final calcRepo = ref.read(costCalculationsRepositoryProvider);
  final records = await calcRepo.getAll();
  return records
      .where((r) => r.itemNumber != null && r.itemNumber!.isNotEmpty)
      .map((r) => r.itemNumber!)
      .toSet();
});

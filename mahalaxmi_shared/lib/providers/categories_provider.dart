import 'package:riverpod/riverpod.dart';

import '../models/category.dart';
import 'repository_providers.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.read(categoryRepositoryProvider).getCategories();
});

final activeCategoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.read(categoryRepositoryProvider).getCategories(activeOnly: true);
});

final categoryNamesProvider = FutureProvider<List<String>>((ref) {
  return ref.read(categoryRepositoryProvider).getCategoryNames();
});

final activeCategoryNamesProvider = FutureProvider<List<String>>((ref) {
  return ref.read(categoryRepositoryProvider).getCategoryNames(activeOnly: true);
});

final validSubCategoriesProvider =
    FutureProvider.family<List<String>, String>((ref, category) {
  return ref.read(categoryRepositoryProvider).getValidSubCategories(category);
});

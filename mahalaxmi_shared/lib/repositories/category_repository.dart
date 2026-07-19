import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category.dart';
import 'base_repository.dart';
import 'supabase_client_provider.dart';

class CategoryRepository {
  static const _table = 'categories';

  Future<List<Category>> getCategories({bool activeOnly = false}) async {
    try {
      var query = SupabaseClientProvider.from(_table).select();

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final data = await query.order('sort_order').order('name');
      return data.map((json) => Category.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<List<String>> getCategoryNames({bool activeOnly = true}) async {
    final categories = await getCategories(activeOnly: activeOnly);
    return categories.map((c) => c.name).toList();
  }

  Future<List<String>> getValidSubCategories(String category) async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select('sub_categories')
          .eq('name', category)
          .limit(1);

      if (data.isEmpty) return [];

      final raw = data.first['sub_categories'] as String? ?? '';
      if (raw.isEmpty) return [];

      return raw
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<void> updateCategoryName(int categoryId, String name) async {
    try {
      await SupabaseClientProvider.from(_table)
          .update({'name': name})
          .eq('id', categoryId);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<void> updateCategoryCoverImage(int categoryId, String coverImageUrl) async {
    try {
      await SupabaseClientProvider.from(_table)
          .update({'cover_image_url': coverImageUrl})
          .eq('id', categoryId);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<void> updateCategoryHasSizes(int categoryId, bool hasSizes) async {
    try {
      await SupabaseClientProvider.from(_table)
          .update({'has_sizes': hasSizes})
          .eq('id', categoryId);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<void> updateCategorySizeChart(int categoryId, List<String>? sizeChart) async {
    try {
      await SupabaseClientProvider.from(_table)
          .update({'size_chart': sizeChart})
          .eq('id', categoryId);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<void> updateCategoryHasSubcategories(int categoryId, bool hasSubcategories) async {
    try {
      await SupabaseClientProvider.from(_table)
          .update({'has_subcategories': hasSubcategories})
          .eq('id', categoryId);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<void> toggleCategoryActive(int categoryId, bool isActive) async {
    try {
      await SupabaseClientProvider.from(_table)
          .update({'is_active': isActive})
          .eq('id', categoryId);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> insertCategory(Map<String, dynamic> data) async {
    try {
      final response = await SupabaseClientProvider.from(_table)
          .insert(data)
          .select()
          .single();
      return response;
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<void> deleteCategory(int categoryId) async {
    try {
      await SupabaseClientProvider.from(_table)
          .delete()
          .eq('id', categoryId);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<int> getNextSortOrder() async {
    try {
      final result = await SupabaseClientProvider.from(_table)
          .select('sort_order')
          .order('sort_order', ascending: false)
          .limit(1);
      if (result.isEmpty) return 10;
      final maxOrder = result.first['sort_order'] as int? ?? 0;
      return maxOrder + 10;
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<void> updateSortOrder(int categoryId, int newOrder) async {
    try {
      await SupabaseClientProvider.from(_table)
          .update({'sort_order': newOrder})
          .eq('id', categoryId);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<void> swapSortOrder(int idA, int idB) async {
    try {
      final rows = await SupabaseClientProvider.from(_table)
          .select('id, sort_order')
          .filter('id', 'in', '($idA,$idB)');
      if (rows.length != 2) {
        throw RepositoryException('Could not find both categories', tableName: _table);
      }
      final orderA = rows.firstWhere((r) => r['id'] == idA)['sort_order'] as int;
      final orderB = rows.firstWhere((r) => r['id'] == idB)['sort_order'] as int;
      await SupabaseClientProvider.from(_table)
          .update({'sort_order': orderB})
          .eq('id', idA);
      await SupabaseClientProvider.from(_table)
          .update({'sort_order': orderA})
          .eq('id', idB);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }
}

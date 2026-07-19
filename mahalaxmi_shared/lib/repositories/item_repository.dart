import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/item.dart';
import 'base_repository.dart';
import 'supabase_client_provider.dart';

class ItemRepository {
  static const _table = 'rate_list';

  Future<List<RateItem>> getAllItems() async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select()
          .order('item_number');
      return data.map((json) => RateItem.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<List<RateItem>> getItemsByCategory(String category) async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select()
          .eq('category', category)
          .order('created_at', ascending: false)
          .order('item_number');
      return data.map((json) => RateItem.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<void> addRateItem(Map<String, dynamic> item) async {
    try {
      await SupabaseClientProvider.from(_table)
          .insert(item)
          .select()
          .single();
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<RateItem?> getItemByNumber(String itemNumber) async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select()
          .eq('item_number', itemNumber)
          .limit(1);

      if (data.isEmpty) return null;
      return RateItem.fromJson(data.first);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<List<RateItem>> getAvailableItems({String? category}) async {
    try {
      var query = SupabaseClientProvider.from(_table)
          .select()
          .eq('is_available', true);

      if (category != null) {
        query = query.eq('category', category);
      }

      final data = await query.order('item_number');
      return data.map((json) => RateItem.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<List<RateItem>> getCustomerCatalogue() async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select()
          .eq('is_available', true)
          .gt('selling_price', 0)
          .order('item_number');
      return data.map((json) => RateItem.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<List<RateItem>> getCustomerItemsByCategory(String category) async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select()
          .eq('category', category.trim())
          .eq('is_available', true)
          .gt('selling_price', 0)
          .order('item_number');
      return data.map((json) => RateItem.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<List<RateItem>> searchCustomerItems(String query) async {
    try {
      final allItems = await getCustomerCatalogue();
      final q = query.trim().toLowerCase();
      if (q.isEmpty) return allItems;

      return allItems.where((item) {
        return item.itemNumber.toLowerCase().contains(q) ||
            item.category.toLowerCase().contains(q) ||
            (item.subCategory?.toLowerCase().contains(q) ?? false) ||
            item.tags.any((tag) => tag.toLowerCase().contains(q));
      }).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<Map<String, RateItem>> getRateLookup() async {
    final items = await getAllItems();
    return {for (final item in items) item.itemNumber: item};
  }

  Future<Map<String, String>> getImageLookup() async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select('item_number,image_url')
          .order('item_number');

      return {
        for (final row in data)
          row['item_number'] as String: (row['image_url'] as String?) ?? '',
      };
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<List<RateItem>> getPricedItems() async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select()
          .eq('status', 'priced')
          .gt('selling_price', 0)
          .order('item_number');
      return data.map((json) => RateItem.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<List<RateItem>> getUnpricedItems() async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select()
          .eq('status', 'new')
          .order('item_number');
      return data.map((json) => RateItem.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getCostingStatus() async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select('item_number,category,image_url,cost_price,selling_price')
          .order('item_number');
      return data;
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<RateItem?> getItemCostingDetail(String itemNumber) async {
    return getItemByNumber(itemNumber);
  }

  Future<List<RateItem>> getItemsByTag(String tagName) async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select()
          .filter('tags', 'cs', jsonEncode([tagName]))
          .order('item_number');
      return data.map((json) => RateItem.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<void> updateItemAvailability(String itemNumber, bool isAvailable) async {
    try {
      await SupabaseClientProvider.from(_table)
          .update({'is_available': isAvailable})
          .eq('item_number', itemNumber);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<void> updateItemSellingPrice(String itemNumber, double sellingPrice) async {
    try {
      await SupabaseClientProvider.from(_table)
          .update({'selling_price': sellingPrice})
          .eq('item_number', itemNumber);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<void> updateItemTags(String itemNumber, List<String> tags) async {
    try {
      final payload = <String, dynamic>{'tags': tags};
      await SupabaseClientProvider.from(_table)
          .update(payload)
          .eq('item_number', itemNumber);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<List<RateItem>> getItemsWithTag(String tag) async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select()
          .filter('tags', 'cs', jsonEncode([tag]))
          .order('item_number');
      return data.map((json) => RateItem.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<void> renameTagInAllItems(String oldTag, String newTag) async {
    final items = await getItemsWithTag(oldTag);
    for (final item in items) {
      final updatedTags = item.tags.map((t) => t == oldTag ? newTag : t).toList();
      await updateItemTags(item.itemNumber, updatedTags);
    }
  }

  Future<void> removeTagFromAllItems(String tag) async {
    final items = await getItemsWithTag(tag);
    for (final item in items) {
      final updatedTags = item.tags.where((t) => t != tag).toList();
      await updateItemTags(item.itemNumber, updatedTags);
    }
  }

  Future<void> updateRateItem(String itemNumber, Map<String, dynamic> updates) async {
    try {
      await SupabaseClientProvider.from(_table)
          .update(updates)
          .eq('item_number', itemNumber);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<void> deleteRateItem(String itemNumber) async {
    try {
      await SupabaseClientProvider.from(_table)
          .delete()
          .eq('item_number', itemNumber);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }
}

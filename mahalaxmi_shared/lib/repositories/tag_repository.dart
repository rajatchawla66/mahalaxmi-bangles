import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/tag.dart';
import 'base_repository.dart';
import 'supabase_client_provider.dart';

class TagRepository {
  static const _table = 'tag_master';

  Future<List<TagMaster>> getTagMaster({bool activeOnly = false}) async {
    try {
      var query = SupabaseClientProvider.from(_table).select();

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final data = await query.order('display_name');
      return data
          .map((json) => _normalizeTag(json))
          .where((t) => t.deletedAt == null)
          .toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> insertTag(Map<String, dynamic> data) async {
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

  Future<void> softDeleteTag(int tagId) async {
    try {
      await SupabaseClientProvider.from(_table)
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', tagId);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<void> updateTag(int tagId, Map<String, dynamic> data) async {
    try {
      await SupabaseClientProvider.from(_table)
          .update(data)
          .eq('id', tagId);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  TagMaster _normalizeTag(Map<String, dynamic> json) {
    final rawCategories = json['categories'];
    final legacyCategory = json['category'] as String?;

    List<String> categories;
    if (rawCategories is List) {
      categories = rawCategories
          .map((c) => c.toString().trim())
          .where((c) => c.isNotEmpty)
          .toList();
    } else if (legacyCategory != null && legacyCategory.isNotEmpty) {
      categories = [legacyCategory.trim()];
    } else {
      categories = [];
    }

    json['categories'] = categories;
    return TagMaster.fromJson(json);
  }
}

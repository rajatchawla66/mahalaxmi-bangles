import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cutmail.dart';
import '../models/cutmail_size.dart';
import 'base_repository.dart';
import 'supabase_client_provider.dart';

class CutmailRepository {
  static const _table = 'cutmails';
  static const _sizesTable = 'cutmail_sizes';

  Future<Cutmail> createCutmail(Cutmail cutmail, List<CutmailSize> sizes) async {
    try {
      final cutmailData = cutmail.toJson();
      cutmailData.remove('id');
      cutmailData.remove('created_at');
      cutmailData.remove('updated_at');
      cutmailData.remove('reviewed_at');
      cutmailData.remove('reviewed_by');

      final result = await SupabaseClientProvider.from(_table)
          .insert(cutmailData)
          .select()
          .single();

      final createdCutmail = Cutmail.fromJson(result);
      final cutmailId = createdCutmail.id!;

      if (sizes.isNotEmpty) {
        final sizesData = sizes.map((s) {
          final data = s.toJson();
          data.remove('id');
          data.remove('cutmail_id');
          data.remove('created_at');
          data['cutmail_id'] = cutmailId;
          return data;
        }).toList();

        await SupabaseClientProvider.from(_sizesTable).insert(sizesData);
      }

      return createdCutmail;
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<List<Cutmail>> getCutmails({
    String? status,
    String? category,
    String? search,
    int? limit,
  }) async {
    try {
      var query = SupabaseClientProvider.from(_table).select();

      if (status != null && status != 'all') {
        query = query.eq('status', status);
      }
      if (category != null && category.isNotEmpty) {
        query = query.eq('category_name', category);
      }
      if (search != null && search.isNotEmpty) {
        query = query.or(
          'item_name_snapshot.ilike.%$search%,item_number_snapshot.ilike.%$search%',
        );
      }

      var ordered = query.order('created_at', ascending: false);

      if (limit != null) {
        ordered = ordered.limit(limit);
      }

      final data = await ordered;
      return data.map((json) => Cutmail.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<Cutmail?> getCutmailById(String id) async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select()
          .eq('id', id)
          .limit(1);

      if (data.isEmpty) return null;
      return Cutmail.fromJson(data.first);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<List<CutmailSize>> getCutmailSizes(String cutmailId) async {
    try {
      final data = await SupabaseClientProvider.from(_sizesTable)
          .select()
          .eq('cutmail_id', cutmailId)
          .order('size');

      return data.map((json) => CutmailSize.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _sizesTable,
        originalError: e,
      );
    }
  }

  Future<void> updateCutmail(String id, Map<String, dynamic> updates) async {
    try {
      await SupabaseClientProvider.from(_table)
          .update(updates)
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<void> updateCutmailSizes(String cutmailId, List<CutmailSize> sizes) async {
    try {
      await SupabaseClientProvider.from(_sizesTable)
          .delete()
          .eq('cutmail_id', cutmailId);

      if (sizes.isNotEmpty) {
        final sizesData = sizes.map((s) {
          final data = s.toJson();
          data.remove('id');
          data.remove('cutmail_id');
          data.remove('created_at');
          data['cutmail_id'] = cutmailId;
          return data;
        }).toList();

        await SupabaseClientProvider.from(_sizesTable).insert(sizesData);
      }
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _sizesTable,
        originalError: e,
      );
    }
  }

  Future<void> markReviewed(String id, String reviewedBy) async {
    try {
      await SupabaseClientProvider.from(_table)
          .update({
            'status': 'reviewed',
            'reviewed_at': DateTime.now().toIso8601String(),
            'reviewed_by': reviewedBy,
          })
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<void> archiveCutmail(String id) async {
    try {
      await SupabaseClientProvider.from(_table)
          .update({'status': 'archived'})
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<void> deleteCutmail(String id) async {
    try {
      await SupabaseClientProvider.from(_table)
          .delete()
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chuda_customization_option.dart';
import 'base_repository.dart';
import 'supabase_client_provider.dart';

class ChudaCustomizationRepository {
  static const _table = 'chuda_customization_options';

  Future<List<ChudaCustomizationOption>> getActiveOptions() async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select()
          .eq('is_active', true)
          .order('group_type')
          .order('sort_order');
      return data
          .map((json) => ChudaCustomizationOption.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message, tableName: _table, originalError: e);
    }
  }

  Future<List<ChudaCustomizationOption>> getAllOptions() async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select()
          .order('group_type')
          .order('sort_order');
      return data
          .map((json) => ChudaCustomizationOption.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message, tableName: _table, originalError: e);
    }
  }

  Future<ChudaCustomizationOption> createOption(
      Map<String, dynamic> data) async {
    try {
      final response = await SupabaseClientProvider.from(_table)
          .insert(data)
          .select()
          .single();
      return ChudaCustomizationOption.fromJson(response);
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message, tableName: _table, originalError: e);
    }
  }

  Future<void> updateOption(int id, Map<String, dynamic> data) async {
    try {
      await SupabaseClientProvider.from(_table)
          .update(data)
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message, tableName: _table, originalError: e);
    }
  }

  Future<void> deactivateOption(int id) async {
    try {
      await SupabaseClientProvider.from(_table)
          .update({'is_active': false})
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message, tableName: _table, originalError: e);
    }
  }

  Future<void> reactivateOption(int id) async {
    try {
      await SupabaseClientProvider.from(_table)
          .update({'is_active': true})
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message, tableName: _table, originalError: e);
    }
  }

  Future<void> setDefaultOption(String groupType, int optionId) async {
    try {
      await SupabaseClientProvider.from(_table)
          .update({'is_default': false})
          .eq('group_type', groupType)
          .eq('is_default', true);
      await SupabaseClientProvider.from(_table)
          .update({'is_default': true})
          .eq('id', optionId);
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message, tableName: _table, originalError: e);
    }
  }
}

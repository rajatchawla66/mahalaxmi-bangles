import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vendor_master.dart';
import 'base_repository.dart';
import 'supabase_client_provider.dart';

class VendorRepository {
  static const _table = 'vendor_master';

  Future<List<VendorMaster>> getVendors({bool activeOnly = false}) async {
    try {
      var query = SupabaseClientProvider.from(_table).select();
      if (activeOnly) query = query.eq('is_active', true);
      final data = await query.order('name');
      return data.map((json) => VendorMaster.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message, tableName: _table, originalError: e);
    }
  }

  Future<List<String>> getVendorNames({bool activeOnly = true}) async {
    final vendors = await getVendors(activeOnly: activeOnly);
    return vendors.map((v) => v.name).toList();
  }

  Future<VendorMaster?> getVendorByName(String name) async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select()
          .eq('name', name)
          .limit(1);
      if (data.isEmpty) return null;
      return VendorMaster.fromJson(data.first);
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message, tableName: _table, originalError: e);
    }
  }

  Future<Map<String, dynamic>> addVendor(Map<String, dynamic> data) async {
    try {
      final result = await SupabaseClientProvider.from(_table)
          .insert(data)
          .select()
          .single();
      return result;
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message, tableName: _table, originalError: e);
    }
  }

  Future<void> updateVendor(int id, Map<String, dynamic> data) async {
    try {
      await SupabaseClientProvider.from(_table)
          .update(data)
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message, tableName: _table, originalError: e);
    }
  }

  Future<void> toggleVendorActive(int id, bool isActive) async {
    try {
      await SupabaseClientProvider.from(_table)
          .update({'is_active': isActive})
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message, tableName: _table, originalError: e);
    }
  }
}

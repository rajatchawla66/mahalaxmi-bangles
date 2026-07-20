import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vendor_price.dart';
import 'base_repository.dart';
import 'supabase_client_provider.dart';

class VendorPriceRepository {
  static const _table = 'vendor_prices';

  Future<List<VendorPrice>> getAll() async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select()
          .order('created_at', ascending: false);
      return data.map((json) => VendorPrice.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message, tableName: _table, originalError: e);
    }
  }

  Future<List<VendorPrice>> getByCategory(String category) async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select()
          .eq('category', category)
          .order('created_at', ascending: false);
      return data.map((json) => VendorPrice.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message, tableName: _table, originalError: e);
    }
  }

  Future<List<VendorPrice>> getByVendor(String vendorName) async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select()
          .eq('vendor_name', vendorName)
          .order('created_at', ascending: false);
      return data.map((json) => VendorPrice.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message, tableName: _table, originalError: e);
    }
  }

  Future<VendorPrice?> getById(String id) async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select()
          .eq('id', id)
          .limit(1);
      if (data.isEmpty) return null;
      return VendorPrice.fromJson(data.first);
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message, tableName: _table, originalError: e);
    }
  }

  Future<void> add(Map<String, dynamic> record) async {
    try {
      await SupabaseClientProvider.from(_table).insert(record);
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message, tableName: _table, originalError: e);
    }
  }

  Future<void> update(String id, Map<String, dynamic> updates) async {
    try {
      await SupabaseClientProvider.from(_table)
          .update(updates)
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message, tableName: _table, originalError: e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await SupabaseClientProvider.from(_table).delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message, tableName: _table, originalError: e);
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/customer.dart';
import 'base_repository.dart';
import 'supabase_client_provider.dart';

class CustomerRepository {
  static const _table = 'customers';

  Future<List<Customer>> getCustomers() async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select()
          .order('created_at', ascending: false);
      return data.map((json) => Customer.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<Customer?> getCustomerByPin(String pin) async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select()
          .eq('pin', pin)
          .limit(1);

      if (data.isEmpty) return null;
      return Customer.fromJson(data.first);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<Customer?> getCustomerById(int customerId) async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select()
          .eq('id', customerId)
          .limit(1);

      if (data.isEmpty) return null;
      return Customer.fromJson(data.first);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<void> updateCustomerField(int customerId, String field, dynamic value) async {
    try {
      await SupabaseClientProvider.from(_table)
          .update({field: value})
          .eq('id', customerId);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<void> updateCustomerShopName(int customerId, String shopName) async {
    await updateCustomerField(customerId, 'shop_name', shopName);
  }

  Future<void> updateCustomerMobile(int customerId, String mobile) async {
    await updateCustomerField(customerId, 'mobile', mobile);
  }

  Future<void> updateCustomerPin(int customerId, String pin) async {
    await updateCustomerField(customerId, 'pin', pin);
  }

  Future<void> updateCustomerActiveStatus(int customerId, bool isActive) async {
    await updateCustomerField(customerId, 'is_active', isActive);
  }

  Future<Map<String, dynamic>> insertCustomer(Map<String, dynamic> data) async {
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

  Future<void> updateLastCatalogueAccess(int customerId) async {
    assert(customerId > 0, 'customerId must be positive');
    final ts = DateTime.now().toUtc().toIso8601String();
    debugPrint('[CustomerRepo] updateLastCatalogueAccess: id=$customerId ts=$ts');
    try {
      await SupabaseClientProvider.from(_table)
          .update({'last_active_at': ts})
          .eq('id', customerId)
          .select();
      debugPrint('[CustomerRepo] updateLastCatalogueAccess: success');
    } on PostgrestException catch (e) {
      debugPrint('[CustomerRepo] updateLastCatalogueAccess: failed — ${e.message}');
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    } catch (e) {
      debugPrint('[CustomerRepo] updateLastCatalogueAccess: unexpected — $e');
      rethrow;
    }
  }

  Future<bool> isCustomerActive(int customerId) async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select('is_active')
          .eq('id', customerId)
          .limit(1);
      if (data.isEmpty) return false;
      return data.first['is_active'] == true;
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<bool> customerExistsByShopName(String shopName) async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select('id')
          .eq('shop_name', shopName)
          .limit(1);
      return data.isNotEmpty;
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<bool> customerExistsByMobile(String mobile) async {
    if (mobile.isEmpty) return false;
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select('id')
          .eq('mobile', mobile)
          .limit(1);
      return data.isNotEmpty;
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<bool> customerExistsByPin(String pin) async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select('id')
          .eq('pin', pin)
          .limit(1);
      return data.isNotEmpty;
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }
}

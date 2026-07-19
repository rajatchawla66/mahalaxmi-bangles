import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/order.dart';
import 'base_repository.dart';
import 'supabase_client_provider.dart';

class OrderRepository {
  static const _table = 'orders';
  static const _itemsTable = 'order_items';

  Future<List<Order>> getOrdersWithItems() async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select('*, $_itemsTable(*)')
          .isFilter('deleted_at', null)
          .order('order_id', ascending: false);
      return data.map((json) => Order.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<Order?> getOrderById(int orderId) async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select('*, $_itemsTable(*)')
          .isFilter('deleted_at', null)
          .eq('order_id', orderId)
          .limit(1);

      if (data.isEmpty) return null;
      return Order.fromJson(data.first);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<List<Order>> getOrdersByCustomerId(int customerId) async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select('*, $_itemsTable(*)')
          .isFilter('deleted_at', null)
          .eq('customer_id', customerId)
          .order('order_id', ascending: false);
      return data.map((json) => Order.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<List<Order>> getArchivedOrders() async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select('*, $_itemsTable(*)')
          .isFilter('deleted_at', null)
          .inFilter('status', ['completed', 'cancelled']).order(
              'status_updated_at',
              ascending: false);
      return data.map((json) => Order.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<List<OrderItem>> getOrderItems(int orderId) async {
    try {
      final data = await SupabaseClientProvider.from(_itemsTable)
          .select()
          .eq('order_id', orderId);
      return data.map((json) => OrderItem.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _itemsTable,
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> insertOrderHeader(
      Map<String, dynamic> data) async {
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

  Future<void> insertOrderItems(List<Map<String, dynamic>> items) async {
    try {
      await SupabaseClientProvider.from(_itemsTable).insert(items);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _itemsTable,
        originalError: e,
      );
    }
  }

  /// Hard delete — use only for rollback of failed order creation.
  /// Do not call from admin UI for business records.
  Future<void> deleteOrder(int orderId) async {
    try {
      await SupabaseClientProvider.from(_table)
          .delete()
          .eq('order_id', orderId);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  /// Soft delete — sets deleted_at, deleted_by, delete_reason.
  /// Use for admin UI deletion of archived orders.
  Future<void> softDeleteOrder(int orderId,
      {String? deletedBy, String? reason}) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final updates = <String, dynamic>{
        'deleted_at': now,
      };
      if (deletedBy != null) updates['deleted_by'] = deletedBy;
      if (reason != null) updates['delete_reason'] = reason;
      await SupabaseClientProvider.from(_table)
          .update(updates)
          .eq('order_id', orderId);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<void> updateOrderStatus(int orderId, String newStatus) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await SupabaseClientProvider.from(_table)
          .update({'status': newStatus, 'status_updated_at': now}).eq(
              'order_id', orderId);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }
}

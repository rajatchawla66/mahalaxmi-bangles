import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mahalaxmi_shared/mahalaxmi_shared.dart';

class CostCalculationsRepository {
  static const _table = 'cost_calculations';

  Future<List<CostCalculation>> getAll() async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select()
          .order('updated_at', ascending: false);
      return data.map((json) => CostCalculation.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message, tableName: _table, originalError: e);
    }
  }

  Future<List<CostCalculation>> getByCategory(String category) async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select()
          .eq('category', category)
          .order('updated_at', ascending: false);
      return data.map((json) => CostCalculation.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message, tableName: _table, originalError: e);
    }
  }

  Future<CostCalculation?> getById(String id) async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select()
          .eq('id', id)
          .limit(1);
      if (data.isEmpty) return null;
      return CostCalculation.fromJson(data.first);
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message, tableName: _table, originalError: e);
    }
  }

  Future<CostCalculation> create(CostCalculation calc) async {
    try {
      final response = await SupabaseClientProvider.from(_table)
          .insert(calc.toJson())
          .select()
          .single();
      return CostCalculation.fromJson(response);
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message, tableName: _table, originalError: e);
    }
  }

  Future<void> update(CostCalculation calc) async {
    if (calc.id == null) throw const RepositoryException('Cannot update record without id', tableName: _table);
    try {
      await SupabaseClientProvider.from(_table)
          .update(calc.toJson())
          .eq('id', calc.id!);
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message, tableName: _table, originalError: e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await SupabaseClientProvider.from(_table)
          .delete()
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message, tableName: _table, originalError: e);
    }
  }
}

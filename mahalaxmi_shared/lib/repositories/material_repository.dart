import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mahalaxmi_shared/models/material.dart' as models;

import 'base_repository.dart';
import 'supabase_client_provider.dart';

class MaterialRepository {
  static const _table = 'materials';
  static const _costTable = 'cost_breakdown';
  static const _itemMaterialsTable = 'item_materials';

  Future<List<models.Material>> getMaterials() async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select()
          .order('name');
      return data.map((json) => models.Material.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getCostBreakdown(
      String itemNumber) async {
    try {
      final data = await SupabaseClientProvider.from(_costTable)
          .select()
          .eq('item_number', itemNumber)
          .order('id');
      return data;
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _costTable,
        originalError: e,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getItemMaterials(
      String itemNumber) async {
    try {
      final data = await SupabaseClientProvider.from(_itemMaterialsTable)
          .select()
          .eq('item_number', itemNumber);
      return data;
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _itemMaterialsTable,
        originalError: e,
      );
    }
  }

  Future<void> addMaterial(String name, double rate, {String unit = 'pcs', String category = 'General'}) async {
    try {
      await SupabaseClientProvider.from(_table)
          .insert({'name': name, 'rate': rate, 'unit': unit, 'category': category});
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<void> updateMaterial(int materialId, String name, double rate, {String unit = 'pcs', String category = 'General'}) async {
    try {
      await SupabaseClientProvider.from(_table)
          .update({'name': name, 'rate': rate, 'unit': unit, 'category': category})
          .eq('id', materialId);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<void> deleteMaterial(int materialId) async {
    try {
      await SupabaseClientProvider.from(_table)
          .delete()
          .eq('id', materialId);
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }
}

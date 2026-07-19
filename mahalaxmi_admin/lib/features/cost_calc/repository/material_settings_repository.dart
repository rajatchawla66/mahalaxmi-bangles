import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mahalaxmi_shared/mahalaxmi_shared.dart';

class MaterialSettingsRepository {
  static const _table = 'material_settings';

  Future<Map<String, dynamic>?> get() async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select()
          .eq('id', 1)
          .limit(1);
      if (data.isEmpty) return null;
      return data.first;
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message, tableName: _table, originalError: e);
    }
  }

  Future<void> save(Map<String, dynamic> settings) async {
    try {
      await SupabaseClientProvider.from(_table)
          .upsert(settings)
          .eq('id', 1);
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message, tableName: _table, originalError: e);
    }
  }
}

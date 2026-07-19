import 'package:supabase_flutter/supabase_flutter.dart';

import 'base_repository.dart';
import 'supabase_client_provider.dart';

class SettingsRepository {
  static const _table = 'app_settings';

  Future<String?> getSetting(String key, {String? defaultValue}) async {
    try {
      final data = await SupabaseClientProvider.from(_table)
          .select('value')
          .eq('key', key)
          .limit(1);

      if (data.isEmpty) return defaultValue;
      return data.first['value'] as String? ?? defaultValue;
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<double> getDefaultMargin() async {
    final raw = await getSetting('default_margin', defaultValue: '30.0');
    return double.tryParse(raw ?? '30.0') ?? 30.0;
  }

  Future<double> getLabourCost() async {
    final raw = await getSetting('labour_cost_flat', defaultValue: '50');
    return double.tryParse(raw ?? '50') ?? 50.0;
  }

  Future<void> saveSetting(String key, String value) async {
    try {
      final existing = await SupabaseClientProvider.from(_table)
          .select('key')
          .eq('key', key)
          .limit(1);

      if (existing.isNotEmpty) {
        await SupabaseClientProvider.from(_table)
            .update({'value': value})
            .eq('key', key);
      } else {
        await SupabaseClientProvider.from(_table)
            .insert({'key': key, 'value': value});
      }
    } on PostgrestException catch (e) {
      throw RepositoryException(
        e.message,
        tableName: _table,
        originalError: e,
      );
    }
  }

  Future<void> saveDefaultMargin(double margin) async {
    await saveSetting('default_margin', margin.toStringAsFixed(1));
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientProvider {
  SupabaseClientProvider._();

  static SupabaseClient get client =>
      _clientOverride != null ? _clientOverride!() : Supabase.instance.client;

  static PostgrestQueryBuilder from(String table) => client.from(table);

  /// For testing: replace the client with a mock.
  static SupabaseClient Function()? _clientOverride;

  static void setClientOverride(SupabaseClient Function()? override) {
    _clientOverride = override;
  }
}

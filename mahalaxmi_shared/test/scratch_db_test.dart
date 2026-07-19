import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Print category names', () async {
    final client = SupabaseClient(
      'https://lgiepatlslklpxmeqkww.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxnaWVwYXRsc2xrbHB4bWVxa3d3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAyMzYyMzEsImV4cCI6MjA5NTgxMjIzMX0.ciwTJjAjNeZ01tsZDUFgZ_ryQDQltloJQm_OQinryKQ',
    );
    final data = await client.from('categories').select('*');
    print('Categories table: $data');
  });
}

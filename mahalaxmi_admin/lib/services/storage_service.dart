import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mahalaxmi_shared/repositories/supabase_client_provider.dart';

class StorageService {
  static const _bucket = 'product-images';

  static Future<String> uploadCategoryCover(Uint8List imageBytes, String categoryName, String fileExtension) async {
    final slug = categoryName.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
    final storagePath = 'category_covers/$slug.jpg';

    await SupabaseClientProvider.client.storage
        .from(_bucket)
        .uploadBinary(
          storagePath,
          imageBytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );

    final publicUrl = SupabaseClientProvider.client.storage
        .from(_bucket)
        .getPublicUrl(storagePath);

    return publicUrl;
  }

  static Future<String> uploadProductImage(Uint8List imageBytes, String itemNumber, String fileExtension) async {
    final slug = itemNumber.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
    final storagePath = 'items/$slug.jpg';

    await SupabaseClientProvider.client.storage
        .from(_bucket)
        .uploadBinary(
          storagePath,
          imageBytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );

    final publicUrl = SupabaseClientProvider.client.storage
        .from(_bucket)
        .getPublicUrl(storagePath);

    return publicUrl;
  }
}

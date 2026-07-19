import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageProcessor {
  /// Processes the raw image bytes:
  /// 1. Decodes the image.
  /// 2. Bakes the EXIF orientation to correct any camera rotation.
  /// 3. Resizes the image to target dimensions.
  /// 4. Encodes to JPEG at the specified quality.
  static Uint8List? processImage({
    required Uint8List bytes,
    required int targetWidth,
    required int targetHeight,
    required int jpegQuality,
  }) {
    try {
      var decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      // Fix EXIF orientation (rotation, flipping)
      decoded = img.bakeOrientation(decoded);

      // Resize to exact target output dimensions using cubic interpolation for higher quality
      final resized = img.copyResize(
        decoded,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.cubic,
      );

      // Encode as JPEG at target quality
      return Uint8List.fromList(img.encodeJpg(resized, quality: jpegQuality));
    } catch (_) {
      return null;
    }
  }
}

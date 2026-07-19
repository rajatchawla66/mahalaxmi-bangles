import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:mahalaxmi_shared/constants/image_policy.dart';
import 'package:mahalaxmi_shared/models/item.dart';

class SharePhotoResult {
  final List<Uint8List> generatedBytes;
  final List<String> skippedItemNumbers;

  const SharePhotoResult({
    required this.generatedBytes,
    required this.skippedItemNumbers,
  });

  bool get allSkipped => generatedBytes.isEmpty;
  int get successCount => generatedBytes.length;
  int get skippedCount => skippedItemNumbers.length;
}

class SharePhotoService {
  static const int _stripHeight = 90;
  static const int _padding = 32;

  static Future<SharePhotoResult> generate({
    required List<RateItem> items,
    required void Function(int current, int total) onProgress,
  }) async {
    final generatedBytes = <Uint8List>[];
    final skippedItems = <String>[];

    for (int i = 0; i < items.length; i++) {
      onProgress(i + 1, items.length);
      final item = items[i];
      final bytes = await _generateOne(item);
      if (bytes != null) {
        generatedBytes.add(bytes);
      } else {
        skippedItems.add(item.itemNumber);
      }
    }

    return SharePhotoResult(
      generatedBytes: generatedBytes,
      skippedItemNumbers: skippedItems,
    );
  }

  static Future<Uint8List?> _generateOne(RateItem item) async {
    Uint8List? imageBytes;
    if (item.imageUrl.isNotEmpty) {
      imageBytes = await _downloadImage(item.imageUrl);
    }
    return _composeCard(item, imageBytes);
  }

  static Future<Uint8List?> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (_) {}
    return null;
  }

  static Uint8List? _composeCard(RateItem item, Uint8List? rawImage) {
    try {
      const width = ImagePolicy.productOutputWidth;
      const height = ImagePolicy.productOutputHeight;
      const stripY = height - _stripHeight;

      final canvas = img.Image(width: width, height: height);

      img.fill(canvas, color: img.ColorRgb8(255, 255, 255));

      if (rawImage != null) {
        final decoded = img.decodeImage(rawImage);
        if (decoded != null) {
          final resized = img.copyResize(
            decoded,
            width: width,
            height: height,
            interpolation: img.Interpolation.cubic,
          );
          img.compositeImage(canvas, resized, dstX: 0, dstY: 0);
        }
      }

      img.fillRect(
        canvas,
        x1: 0,
        y1: stripY,
        x2: width,
        y2: height,
        color: img.ColorRgba8(0, 0, 0, 180),
      );

      const textCenterY = stripY + (_stripHeight - 48) ~/ 2;

      _drawString(
        canvas,
        item.itemNumber,
        _padding,
        textCenterY,
        font: img.arial48,
        color: img.ColorRgb8(255, 255, 255),
      );

      final priceText = item.sellingPrice > 0
          ? 'INR ${_formatPrice(item.sellingPrice)}'
          : 'Price not set';
      final priceWidth = _measureTextWidth(img.arial48, priceText);
      final priceX = width - _padding - priceWidth;

      _drawString(
        canvas,
        priceText,
        priceX,
        textCenterY,
        font: img.arial48,
        color: img.ColorRgb8(255, 215, 0),
      );

      return Uint8List.fromList(
        img.encodeJpg(canvas, quality: ImagePolicy.productJpegQuality),
      );
    } catch (_) {
      return null;
    }
  }

  static String _formatPrice(double price) {
    final whole = price.round();
    final str = whole.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
      count++;
    }
    return buffer.toString().split('').reversed.join('');
  }

  static int _measureTextWidth(img.BitmapFont font, String text) {
    int w = 0;
    for (final c in text.codeUnits) {
      final ch = font.characters[c];
      w += ch?.xAdvance ?? 0;
    }
    return w;
  }

  static void _drawString(
    img.Image canvas,
    String text,
    int x,
    int y, {
    required img.BitmapFont font,
    img.Color? color,
  }) {
    img.drawString(
      canvas,
      text,
      font: font,
      x: x,
      y: y,
      color: color ?? const img.ConstColorRgb8(255, 255, 255),
    );
  }

  static String fileNameForItem(RateItem item) {
    final sanitizedName = item.itemNumber
        .replaceAll(RegExp(r'[^\w\-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final priceStr = item.sellingPrice.round().toString();
    return 'MBS_${sanitizedName}_$priceStr.jpg';
  }

  /// Share generated image bytes using platform-appropriate method.
  /// Works on both web (via Web Share API or download) and mobile.
  static Future<void> shareBytes({
    required List<Uint8List> bytesList,
    required List<String> fileNames,
  }) async {
    final dir = await getTemporaryDirectory();
    final xFiles = <XFile>[];
    for (int i = 0; i < bytesList.length; i++) {
      final file = File('${dir.path}/${fileNames[i]}');
      await file.writeAsBytes(bytesList[i]);
      xFiles.add(XFile(file.path, mimeType: 'image/jpeg'));
    }
    await Share.shareXFiles(xFiles);
  }
}

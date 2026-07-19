import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/order.dart';

enum _PdfVariant { customer, admin, labour }

class OrderPdfService {
  // Format currency values as "INR <amount>" without using the ₹ symbol.
  static String _formatINR(double amount) {
    if (amount == amount.roundToDouble()) {
      return 'INR ${amount.round()}';
    }
    return 'INR ${amount.toStringAsFixed(2)}';
  }

  // Safe string helper to prevent crash on null or empty values.
  static String _safe(String? value, {String fallback = '-'}) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value;
  }

  /// Generates the Customer Confirmation PDF (with pricing, hides mobile/ID).
  static Future<Uint8List> generateCustomerPdf(Order order, {Map<String, String>? imageLookup}) async {
    return _generatePdf(order, variant: _PdfVariant.customer, imageLookup: imageLookup);
  }

  /// Generates the Admin Internal PDF (with pricing, includes mobile/ID).
  static Future<Uint8List> generateAdminPdf(Order order, {Map<String, String>? imageLookup}) async {
    return _generatePdf(order, variant: _PdfVariant.admin, imageLookup: imageLookup);
  }

  /// Generates the Labour/Karigar Slip (no pricing, English-only, production-focused).
  static Future<Uint8List> generateLabourPdf(Order order, {Map<String, String>? imageLookup}) async {
    return _generatePdf(order, variant: _PdfVariant.labour, imageLookup: imageLookup);
  }

  // Download image bytes from HTTPS URL with a 5-second timeout guard.
  static Future<Uint8List?> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (_) {
      // Fail close/safely by returning null (triggers offline "No Image" placeholder fallback)
    }
    return null;
  }

  // Compress and resize image to keep generated PDF file size compact.
  static Uint8List? _compressImage(Uint8List originalBytes) {
    try {
      final image = img.decodeImage(originalBytes);
      if (image == null) return null;

      // Resize if width is greater than 600px to keep patterns clear but file compact.
      if (image.width > 600) {
        final resized = img.copyResize(image, width: 600);
        return Uint8List.fromList(img.encodeJpg(resized, quality: 82));
      } else {
        // Just encode to JPEG with 82% quality if it's already under 600px width.
        return Uint8List.fromList(img.encodeJpg(image, quality: 82));
      }
    } catch (_) {
      // Fallback to original bytes if resizing fails
    }
    return originalBytes;
  }

  static Future<Uint8List> _generatePdf(Order order, {required _PdfVariant variant, Map<String, String>? imageLookup}) async {
    final pdf = pw.Document();

    // Concurrently download and compress all product images associated with items in the order
    final Map<String, Uint8List> preloadedImages = {};
    if (imageLookup != null) {
      final List<Future<void>> downloads = [];
      for (final item in order.orderItems) {
        final url = imageLookup[item.itemNumber];
        if (url != null && url.isNotEmpty) {
          downloads.add(() async {
            final rawBytes = await _downloadImage(url);
            if (rawBytes != null) {
              final compressed = _compressImage(rawBytes);
              if (compressed != null) {
                preloadedImages[item.itemNumber] = compressed;
              }
            }
          }());
        }
      }
      await Future.wait(downloads);
    }

    // Brand Colors (Premium Maroon and Warm Gold theme)
    final PdfColor primaryColor = variant == _PdfVariant.labour 
        ? PdfColor.fromHex('#424242') 
        : PdfColor.fromHex('#800020'); // Premium Maroon
    final PdfColor accentColor = variant == _PdfVariant.labour
        ? PdfColor.fromHex('#757575')
        : PdfColor.fromHex('#B5A642'); // Accent Gold
    final PdfColor cardBgColor = PdfColor.fromHex('#FDFBF7'); // Cream background card style
    final PdfColor borderLightColor = PdfColor.fromHex('#E0D5C0'); // Light grey/beige border
    final PdfColor textDarkColor = PdfColor.fromHex('#2A2A2A'); // Charcoal dark text for visual clarity

    final showPricing = variant != _PdfVariant.labour;

    // Horizontal summary card below the header
    final summaryCard = pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: cardBgColor,
        border: pw.Border.all(color: borderLightColor, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Section 1: Customer Details
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CUSTOMER',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: accentColor),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  _safe(order.customerName),
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: textDarkColor),
                ),
                if (variant == _PdfVariant.admin) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Mobile: ${_safe(order.customerMobile)}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                  pw.Text(
                    'ID: ${order.customerId?.toString() ?? '-'}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                ],
              ],
            ),
          ),
          
          // Divider 1
          pw.Container(
            height: 35,
            width: 0.5,
            color: borderLightColor,
            margin: const pw.EdgeInsets.symmetric(horizontal: 8),
          ),
          
          // Section 2: Order Status
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'STATUS & SOURCE',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: accentColor),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  order.status.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 11, 
                    fontWeight: pw.FontWeight.bold, 
                    color: order.status == 'cancelled' ? PdfColor.fromHex('#C62828') : primaryColor,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Source: ${order.source.toUpperCase()}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
              ],
            ),
          ),
          
          // Section 3: Grand Total (Only Customer/Admin)
          if (showPricing) ...[
            // Divider 2
            pw.Container(
              height: 35,
              width: 0.5,
              color: borderLightColor,
              margin: const pw.EdgeInsets.symmetric(horizontal: 8),
            ),
            pw.Expanded(
              flex: 3,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'GRAND TOTAL',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: accentColor),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    _formatINR(order.totalAmount),
                    style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: primaryColor),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    // Metadata card specs row (Color, Grind/Finish, Box Type)
    final specsRow = pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderLightColor, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        color: PdfColors.grey50,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          pw.Column(
            children: [
              pw.Text('Color', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: accentColor)),
              pw.SizedBox(height: 2),
              pw.Text(_safe(order.color), style: pw.TextStyle(fontSize: 9, color: textDarkColor, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Column(
            children: [
              pw.Text('Grind Type / Finish', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: accentColor)),
              pw.SizedBox(height: 2),
              pw.Text(_safe(order.grindType), style: pw.TextStyle(fontSize: 9, color: textDarkColor, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Column(
            children: [
              pw.Text('Box Type', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: accentColor)),
              pw.SizedBox(height: 2),
              pw.Text(_safe(order.boxType), style: pw.TextStyle(fontSize: 9, color: textDarkColor, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    );

    // Build item cards stack list
    final List<pw.Widget> itemCards = [];
    for (int i = 0; i < order.orderItems.length; i++) {
      final item = order.orderItems[i];
      
      // Left side: Large product image with aspect ratio fit
      pw.Widget imageWidget;
      final imageBytes = preloadedImages[item.itemNumber];
      if (imageBytes != null) {
        imageWidget = pw.Image(
          pw.MemoryImage(imageBytes),
          fit: pw.BoxFit.contain,
        );
      } else {
        imageWidget = pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'No Image',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey500),
            ),
          ],
        );
      }
      
      final leftColumn = pw.Container(
        width: 220,
        height: 160,
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: borderLightColor, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        alignment: pw.Alignment.center,
        child: imageWidget,
      );
      
      // Right side: Item specifications, quantity metrics, and pricing details
      final List<pw.Widget> specsList = [];
      if (item.totalSizeQty > 0) {
        // Size-based item (displaying only quantities > 0 with bullet tags)
        specsList.add(
          pw.Text(
            'Size Quantities:',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: accentColor),
          ),
        );
        specsList.add(pw.SizedBox(height: 2));
        
        if (item.qty22 > 0) specsList.add(pw.Text('  * 2.2: ${item.qty22}', style: pw.TextStyle(fontSize: 8, color: textDarkColor)));
        if (item.qty24 > 0) specsList.add(pw.Text('  * 2.4: ${item.qty24}', style: pw.TextStyle(fontSize: 8, color: textDarkColor)));
        if (item.qty26 > 0) specsList.add(pw.Text('  * 2.6: ${item.qty26}', style: pw.TextStyle(fontSize: 8, color: textDarkColor)));
        if (item.qty28 > 0) specsList.add(pw.Text('  * 2.8: ${item.qty28}', style: pw.TextStyle(fontSize: 8, color: textDarkColor)));
        if (item.qty210 > 0) specsList.add(pw.Text('  * 2.10: ${item.qty210}', style: pw.TextStyle(fontSize: 8, color: textDarkColor)));
        if (item.qty212 > 0) specsList.add(pw.Text('  * 2.12: ${item.qty212}', style: pw.TextStyle(fontSize: 8, color: textDarkColor)));
        
        specsList.add(pw.SizedBox(height: 4));
        specsList.add(
          pw.Text(
            'Total Size Qty: ${item.totalSizeQty} sets',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: textDarkColor),
          ),
        );
      } else {
        // Quantity-based item
        final unitStr = _safe(item.unit, fallback: 'sets');
        final doubleQty = item.quantity;
        final qtyStr = doubleQty == doubleQty.roundToDouble() ? '${doubleQty.round()}' : '$doubleQty';
        
        specsList.add(
          pw.Text(
            'Quantity:',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: accentColor),
          ),
        );
        specsList.add(pw.SizedBox(height: 2));
        specsList.add(
          pw.Text(
            '$qtyStr $unitStr',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textDarkColor),
          ),
        );
      }
      
      final rightColumn = pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.start,
        children: [
          // Item Badge
          pw.Text(
            'Item #${i + 1} (No. ${_safe(item.itemNumber)})',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: primaryColor),
          ),
          pw.SizedBox(height: 2),
          // Item Name (Category)
          pw.Text(
            item.category.replaceAll('_', ' '),
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: textDarkColor),
          ),
          
          if (item.color != null && item.color!.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text('Color: ${item.color}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          ],
          if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              'Notes: ${item.notes}',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
            ),
          ],
          if (item.customization != null) _buildPdfCustomisation(item.customization!),
          
          pw.SizedBox(height: 6),
          
          // Sizing details list
          ...specsList,
          
          if (showPricing) ...[
            pw.SizedBox(height: 8),
            // Unit Price and Line Total
            pw.Row(
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Unit Price', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    pw.Text(_formatINR(item.unitPrice), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textDarkColor)),
                  ],
                ),
                pw.SizedBox(width: 32),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Line Total', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    pw.Text(_formatINR(item.lineTotal), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                  ],
                ),
              ],
            ),
          ],
        ],
      );
      
      final card = pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: cardBgColor,
          border: pw.Border.all(color: borderLightColor, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            leftColumn,
            pw.SizedBox(width: 15),
            pw.Expanded(child: rightColumn),
          ],
        ),
      );
      
      // Cards are placed in multi-page flow and automatically kept together
      itemCards.add(card);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ),
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'MAHALAXMI BANGLES',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        variant == _PdfVariant.labour
                            ? 'PRODUCTION SHEET / KARIGAR SLIP'
                            : variant == _PdfVariant.admin
                                ? 'INTERNAL COPY (ADMIN)'
                                : 'ORDER CONFIRMATION RECEIPT',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: accentColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Order #${order.orderId ?? '-'}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Date: ${_safe(order.orderDate)}',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1.5, color: primaryColor),
              pw.SizedBox(height: 12),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(thickness: 0.5, color: borderLightColor),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    variant == _PdfVariant.labour
                        ? 'Confidential - For Production Use Only'
                        : 'Thank you for choosing Mahalaxmi Bangles',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          // Compute summary row widgets
          pw.Widget grandTotalWidget;
          if (variant != _PdfVariant.labour) {
            grandTotalWidget = pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 240,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: primaryColor, width: 1.5),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    color: cardBgColor,
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total Items Quantity:', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                          pw.Text('${_calculateTotalSets(order.orderItems)} sets', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textDarkColor)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Divider(thickness: 0.5, color: borderLightColor),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Grand Total:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                          pw.Text(
                            _formatINR(order.totalAmount),
                            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: primaryColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            // For Labour slip, just show total production sets
            grandTotalWidget = pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 200,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: primaryColor, width: 1),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    color: cardBgColor,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Production Qty:', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      pw.Text('${_calculateTotalSets(order.orderItems)} sets', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textDarkColor)),
                    ],
                  ),
                ),
              ],
            );
          }

          // Build remarks and signatory box at bottom
          final remarksAndSignature = pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              // Remarks Box
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Remarks:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                  pw.SizedBox(height: 2),
                  pw.Container(
                    width: 250,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: borderLightColor, width: 0.5),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      color: cardBgColor,
                    ),
                    child: pw.Text(
                      _safe(order.additionalInfo, fallback: 'No notes provided.'),
                      style: pw.TextStyle(fontSize: 8, color: textDarkColor),
                    ),
                  ),
                ],
              ),
              // Signatory line
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 30),
                  pw.Container(width: 150, height: 0.5, color: textDarkColor),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    variant == _PdfVariant.labour ? 'Karigar Signature' : 'Authorized Signatory',
                    style: pw.TextStyle(fontSize: 9, color: textDarkColor),
                  ),
                ],
              ),
            ],
          );

          return [
            summaryCard,
            pw.SizedBox(height: 12),
            specsRow,
            pw.SizedBox(height: 16),

            // Order Items Section Title strip
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: pw.BoxDecoration(
                color: primaryColor,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                'ORDER ITEMS (${order.orderItems.length})',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white, letterSpacing: 0.8),
              ),
            ),
            pw.SizedBox(height: 12),

            // Render all two-column item cards
            ...itemCards,
            pw.SizedBox(height: 16),

            // Grand Total summary card
            grandTotalWidget,

            // Customer confirmation instruction footer note
            if (variant == _PdfVariant.customer) ...[
              pw.SizedBox(height: 12),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'Please confirm if any changes are required.',
                  style: pw.TextStyle(fontSize: 9, color: primaryColor, fontWeight: pw.FontWeight.bold, fontStyle: pw.FontStyle.italic),
                ),
              ),
            ],

            pw.SizedBox(height: 24),
            // Bottom Remarks & Sign-off area
            remarksAndSignature,
          ];
        },
      ),
    );

    return pdf.save();
  }

  // Build PDF customisation widget from saved JSONB snapshot
  static pw.Widget _buildPdfCustomisation(Map<String, dynamic> c) {
    final pattiName = (c['pattiName'] as String?) ?? '';
    final pattiDiff = ((c['pattiPriceDiff'] as num?) ?? 0).toDouble();
    final colorName = (c['colorName'] as String?) ?? '';
    final customColorText = c['customColorText'] as String?;
    final boxName = (c['boxName'] as String?) ?? '';
    final boxDiff = ((c['boxPriceDiff'] as num?) ?? 0).toDouble();
    final totalDiff = ((c['totalDifference'] as num?) ?? 0).toDouble();

    String _diff(double d) {
      if (d == 0) return ' (Included)';
      if (d > 0) return ' (+${_formatINR(d)})';
      return ' (-${_formatINR(d.abs())})';
    }

    final displayColor = customColorText != null ? 'Custom - "$customColorText"' : colorName;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 4),
        pw.Text('Chooda Customisation:',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#B8860B'))),
        pw.SizedBox(height: 1),
        pw.Text('  Patti: $pattiName${_diff(pattiDiff)}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        pw.Text('  Patti Color: $displayColor${_diff(0)}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        pw.Text('  Box: $boxName${_diff(boxDiff)}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        if (totalDiff > 0)
          pw.Text('  Customisation: ${_formatINR(totalDiff)}',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2E7D32'))),
      ],
    );
  }

  // Calculates sum of sets across all items
  static int _calculateTotalSets(List<OrderItem> items) {
    return items.fold<int>(0, (sum, item) {
      if (item.totalSizeQty > 0) {
        return sum + item.totalSizeQty;
      }
      return sum + item.quantity.toInt();
    });
  }
}

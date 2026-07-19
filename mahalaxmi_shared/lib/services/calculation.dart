import '../constants/category_schemas.dart';
import '../constants/size_charts.dart';
import '../models/cart_item.dart';
import '../models/order_summary.dart';

double _safeDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value >= 0 ? value : 0.0;
  if (value is int) return value >= 0 ? value.toDouble() : 0.0;
  if (value is String) {
    final n = double.tryParse(value);
    if (n != null && n >= 0) return n;
    return 0.0;
  }
  return 0.0;
}

int _sumSizeQtys(CartItem item) {
  return item.qty22 + item.qty24 + item.qty26 + item.qty28 + item.qty210 + item.qty212;
}

double calculateLineTotal(CartItem item, String category, double unitPrice) {
  final schema = kCategorySchemas[category];

  if (schema == null) {
    // Dynamic category — determine formula from item's hasSizes flag
    if (item.hasSizes) {
      final totalQty = _sumSizeQtys(item);
      return double.parse((totalQty * unitPrice).toStringAsFixed(2));
    } else {
      final qty = _safeDouble(item.quantity);
      return double.parse((qty * unitPrice).toStringAsFixed(2));
    }
  }

  // Override formula based on item's hasSizes flag
  if (item.hasSizes) {
    final totalQty = _sumSizeQtys(item);
    return double.parse((totalQty * unitPrice).toStringAsFixed(2));
  }

  final formula = schema.lineTotal;

  if (formula == 'sum_sizes_x_price') {
    final totalQty = _sumSizeQtys(item);
    return double.parse((totalQty * unitPrice).toStringAsFixed(2));
  }

  if (formula == 'qty_x_price') {
    final qty = _safeDouble(item.quantity);
    final validQty = qty < 0 ? 0.0 : qty;
    return double.parse((validQty * unitPrice).toStringAsFixed(2));
  }

  return 0.0;
}

OrderSummary buildOrderSummary(
    List<CartItem> cart, Map<String, Map<String, dynamic>> rateLookup) {
  final Map<String, List<CartItem>> categoryBuckets = {};
  final Map<String, double> categoryLineTotals = {};

  for (final item in cart) {
    if (item.itemNumber.isEmpty) continue;

    final itemInfo = rateLookup[item.itemNumber] ?? {};

    final category =
        (itemInfo['category'] as String?)?.isNotEmpty == true
            ? itemInfo['category'] as String
            : item.category;

    final unitPrice = item.customization != null
        ? item.unitPrice
        : _safeDouble(itemInfo['selling_price'] ?? item.unitPrice);

    final lineTotal = calculateLineTotal(item, category, unitPrice);

    categoryBuckets.putIfAbsent(category, () => []);
    categoryBuckets[category]!.add(item);
    categoryLineTotals.update(
      category,
      (v) => v + lineTotal,
      ifAbsent: () => lineTotal,
    );
  }

  final groups = <CategoryGroup>[];
  final sortedKeys = categoryBuckets.keys.toList()..sort();

  for (final category in sortedKeys) {
    final items = categoryBuckets[category]!;
    final subtotal =
        double.parse((categoryLineTotals[category] ?? 0.0).toStringAsFixed(2));
    final summaryItems = items.map((item) {
      final itemInfo = rateLookup[item.itemNumber] ?? {};
      final unitPrice = item.customization != null
          ? item.unitPrice
          : _safeDouble(itemInfo['selling_price'] ?? item.unitPrice);
      return OrderSummaryItem(
        itemNumber: item.itemNumber,
        imageUrl: (itemInfo['image_url'] as String?) ?? '',
        totalSets: item.hasSizes ? item.totalSizeQty : item.quantity.toInt(),
        lineTotal: calculateLineTotal(item, category, unitPrice),
        sizes: () {
          final chart = getSizeChartForCategory(category);
          if (chart.isEmpty) return <String, int>{};
          final qtyMap = <String, int>{
            '2.2': item.qty22,
            '2.4': item.qty24,
            '2.6': item.qty26,
            '2.8': item.qty28,
            '2.10': item.qty210,
            '2.12': item.qty212,
          };
          return {for (final s in chart) if ((qtyMap[s] ?? 0) > 0) s: qtyMap[s]!};
        }(),
      );
    }).toList();

    groups.add(CategoryGroup(
      category: category,
      items: summaryItems,
      subtotal: subtotal,
    ));
  }

  final grandTotal = double.parse(
    groups.fold(0.0, (sum, g) => sum + g.subtotal).toStringAsFixed(2),
  );

  return OrderSummary(groups: groups, grandTotal: grandTotal);
}

import '../models/item.dart';
import '../models/vendor_price.dart';

class LedgerItem {
  final String id;
  final String name;
  final String? itemNumber;
  final String? category;
  final String vendor;
  final double costPrice;
  final double sellingPrice;
  final double marginPct;
  final String source;
  final String? notes;
  final String? imageUrl;

  const LedgerItem({
    required this.id,
    required this.name,
    this.itemNumber,
    this.category,
    required this.vendor,
    required this.costPrice,
    required this.sellingPrice,
    required this.marginPct,
    required this.source,
    this.notes,
    this.imageUrl,
  });
}

class LedgerService {
  List<LedgerItem> merge({
    required List<RateItem> rateItems,
    required List<VendorPrice> vendorPrices,
  }) {
    final items = <LedgerItem>[];

    for (final item in rateItems) {
      if (item.costPrice <= 0 && item.sellingPrice <= 0) continue;
      items.add(_fromRateItem(item));
    }

    for (final vp in vendorPrices) {
      items.add(_fromVendorPrice(vp));
    }

    return items;
  }

  List<LedgerItem> filterByCategory({
    required List<RateItem> rateItems,
    required List<VendorPrice> vendorPrices,
    required String category,
  }) {
    final items = <LedgerItem>[];

    for (final item in rateItems) {
      if (item.category != category) continue;
      if (item.costPrice <= 0 && item.sellingPrice <= 0) continue;
      items.add(_fromRateItem(item));
    }

    for (final vp in vendorPrices) {
      if (vp.category != category) continue;
      items.add(_fromVendorPrice(vp));
    }

    return items;
  }

  List<LedgerItem> filterByVendor({
    required List<RateItem> rateItems,
    required List<VendorPrice> vendorPrices,
    required String vendor,
  }) {
    final items = <LedgerItem>[];
    final isNoVendor = vendor == 'No Vendor';

    for (final item in rateItems) {
      final itemVendor = item.vendor;
      if (isNoVendor ? itemVendor != null : itemVendor != vendor) continue;
      if (item.costPrice <= 0 && item.sellingPrice <= 0) continue;
      items.add(_fromRateItem(item));
    }

    for (final vp in vendorPrices) {
      if (isNoVendor) continue;
      if (vp.vendorName != vendor) continue;
      items.add(_fromVendorPrice(vp));
    }

    return items;
  }

  Set<String> extractVendors({
    required List<RateItem> rateItems,
    required List<VendorPrice> vendorPrices,
  }) {
    final vendors = <String>{};
    for (final item in rateItems) {
      if (item.vendor != null && item.vendor!.isNotEmpty) {
        vendors.add(item.vendor!);
      }
    }
    for (final vp in vendorPrices) {
      vendors.add(vp.vendorName);
    }
    return vendors;
  }

  Map<String, List<LedgerItem>> groupByCategory({
    required List<RateItem> rateItems,
    required List<VendorPrice> vendorPrices,
  }) {
    final groups = <String, List<LedgerItem>>{};

    for (final item in rateItems) {
      if (item.costPrice <= 0 && item.sellingPrice <= 0) continue;
      final cat = item.category;
      groups.putIfAbsent(cat, () => []).add(_fromRateItem(item));
    }

    for (final vp in vendorPrices) {
      final cat = vp.category ?? 'Uncategorised';
      groups.putIfAbsent(cat, () => []).add(_fromVendorPrice(vp));
    }

    return groups;
  }

  Map<String, List<LedgerItem>> groupByVendor({
    required List<RateItem> rateItems,
    required List<VendorPrice> vendorPrices,
  }) {
    final groups = <String, List<LedgerItem>>{};

    for (final item in rateItems) {
      if (item.costPrice <= 0 && item.sellingPrice <= 0) continue;
      final vendor = item.vendor;
      final key = (vendor != null && vendor.isNotEmpty) ? vendor : 'No Vendor';
      groups.putIfAbsent(key, () => []).add(_fromRateItem(item));
    }

    for (final vp in vendorPrices) {
      groups.putIfAbsent(vp.vendorName, () => []).add(_fromVendorPrice(vp));
    }

    return groups;
  }

  LedgerItem _fromRateItem(RateItem item) {
    final margin = _calcMargin(item.costPrice, item.sellingPrice);
    return LedgerItem(
      id: item.itemNumber,
      name: item.itemNumber,
      itemNumber: item.itemNumber,
      category: item.category,
      vendor: item.vendor ?? '',
      costPrice: item.costPrice,
      sellingPrice: item.sellingPrice,
      marginPct: margin,
      source: 'rate_list',
      imageUrl: item.imageUrl.isNotEmpty ? item.imageUrl : null,
    );
  }

  LedgerItem _fromVendorPrice(VendorPrice vp) {
    final margin = _calcMargin(vp.costPrice, vp.sellingPrice);
    return LedgerItem(
      id: vp.id ?? vp.itemName,
      name: vp.itemName,
      category: vp.category,
      vendor: vp.vendorName,
      costPrice: vp.costPrice,
      sellingPrice: vp.sellingPrice,
      marginPct: margin,
      source: 'vendor_prices',
      notes: vp.notes,
    );
  }

  double _calcMargin(double cost, double selling) {
    if (cost <= 0) return 0;
    return ((selling - cost) / cost * 100);
  }
}

class CategoryGroup {
  final String category;
  final List<OrderSummaryItem> items;
  final double subtotal;

  const CategoryGroup({
    required this.category,
    required this.items,
    required this.subtotal,
  });
}

class OrderSummaryItem {
  final String itemNumber;
  final String imageUrl;
  final int totalSets;
  final double lineTotal;
  final Map<String, int> sizes;

  const OrderSummaryItem({
    required this.itemNumber,
    required this.imageUrl,
    required this.totalSets,
    required this.lineTotal,
    required this.sizes,
  });
}

class OrderSummary {
  final List<CategoryGroup> groups;
  final double grandTotal;

  const OrderSummary({
    required this.groups,
    required this.grandTotal,
  });
}

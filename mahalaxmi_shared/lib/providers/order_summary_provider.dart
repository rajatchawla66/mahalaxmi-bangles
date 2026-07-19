import 'package:riverpod/riverpod.dart';

import '../models/order_summary.dart';
import '../services/calculation.dart';
import 'cart_provider.dart';
import 'items_provider.dart';

final orderSummaryProvider = FutureProvider<OrderSummary>((ref) async {
  final cart = ref.watch(cartProvider);
  final rateLookup = await ref.watch(rateLookupProvider.future);

  final lookup = rateLookup.map((key, value) => MapEntry(key, <String, dynamic>{
    'category': value.category,
    'selling_price': value.sellingPrice,
    'image_url': value.imageUrl,
    'has_sizes': value.hasSizes,
    'has_color': value.hasColor,
  }));

  return buildOrderSummary(cart.items, lookup);
});

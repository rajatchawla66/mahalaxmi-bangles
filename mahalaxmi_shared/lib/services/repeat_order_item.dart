import '../models/cart_item.dart';
import '../models/chuda_customization_snapshot.dart';
import '../models/item.dart';
import '../models/order.dart';

CartItem orderItemToCartItem(OrderItem order, RateItem rateItem) {
  ChudaCustomizationSnapshot? customization;
  if (order.customization != null) {
    customization = ChudaCustomizationSnapshot.fromJson(order.customization!);
  }

  return CartItem(
    itemNumber: order.itemNumber,
    category: rateItem.category,
    hasSizes: rateItem.hasSizes,
    hasColor: rateItem.hasColor,
    qty22: order.qty22,
    qty24: order.qty24,
    qty26: order.qty26,
    qty28: order.qty28,
    qty210: order.qty210,
    qty212: order.qty212,
    quantity: order.quantity,
    color: order.color,
    unitPrice: customization != null ? order.unitPrice : rateItem.sellingPrice,
    customization: customization,
  );
}

String? validateRepeatableItem(RateItem? item) {
  if (item == null) return 'Item not found in catalogue';
  if (!item.isAvailable) return 'Item is no longer available';
  if (item.sellingPrice <= 0) return 'Item has no selling price';
  return null;
}

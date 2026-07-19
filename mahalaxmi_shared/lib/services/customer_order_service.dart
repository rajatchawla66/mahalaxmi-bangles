import '../models/app_session.dart';
import '../models/cart_item.dart';
import '../models/cart_state.dart';
import '../models/item.dart';
import '../repositories/order_repository.dart';
import '../services/calculation.dart';
import '../services/validation.dart';

String _today() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

Map<String, dynamic> _itemToRow(CartItem item, Map<String, RateItem> rateLookup) {
  final itemInfo = rateLookup[item.itemNumber];
  final effectiveCategory = itemInfo?.category ?? item.category;

  return {
    'item_number': item.itemNumber,
    'category': effectiveCategory,
    'qty_2_2': item.qty22,
    'qty_2_4': item.qty24,
    'qty_2_6': item.qty26,
    'qty_2_8': item.qty28,
    'qty_2_10': item.qty210,
    'qty_2_12': item.qty212,
    'quantity': item.quantity.toInt(),
    'unit': item.unit,
    'color': item.color,
    'grind_type': item.grindType,
    'box_type': item.boxType,
    'notes': item.notes,
    'unit_price': item.customization != null
        ? item.unitPrice
        : (itemInfo?.sellingPrice ?? item.unitPrice),
    'customization': item.customization?.toJson(),
  };
}

Map<String, Map<String, dynamic>> _rateLookupToSummaryFormat(Map<String, RateItem> rateLookup) {
  return rateLookup.map((key, value) => MapEntry(key, <String, dynamic>{
    'category': value.category,
    'selling_price': value.sellingPrice,
    'image_url': value.imageUrl,
    'has_sizes': value.hasSizes,
    'has_color': value.hasColor,
  }));
}

sealed class CustomerOrderResult {
  const CustomerOrderResult();
}

class CustomerOrderSuccess extends CustomerOrderResult {
  final int orderId;
  const CustomerOrderSuccess({required this.orderId});
}

sealed class CustomerOrderFailure extends CustomerOrderResult {
  const CustomerOrderFailure();
}

class NotLoggedIn extends CustomerOrderFailure {
  const NotLoggedIn();
}

class AccountDisabled extends CustomerOrderFailure {
  const AccountDisabled();
}

class EmptyCart extends CustomerOrderFailure {
  const EmptyCart();
}

class InvalidCartItems extends CustomerOrderFailure {
  final String itemNumber;
  final String message;
  const InvalidCartItems({required this.itemNumber, required this.message});
}

class OrderSaveFailed extends CustomerOrderFailure {
  final String message;
  const OrderSaveFailed(this.message);
}

class RollbackFailed extends CustomerOrderFailure {
  final String originalError;
  final String rollbackError;
  const RollbackFailed({
    required this.originalError,
    required this.rollbackError,
  });
}

class CustomerOrderService {
  final OrderRepository _orderRepo;

  CustomerOrderService(this._orderRepo);

  Future<CustomerOrderResult> placeOrder({
    required AppSession session,
    required CartState cart,
    required Map<String, RateItem> rateLookup,
  }) async {
    if (!session.isCustomer || session.customerId == null) {
      return const NotLoggedIn();
    }

    if (cart.items.isEmpty) {
      return const EmptyCart();
    }

    for (final line in cart.lines) {
      final error = validateCartItem(line.item, line.item.category);
      if (error != null) {
        return InvalidCartItems(
          itemNumber: line.item.itemNumber,
          message: error,
        );
      }
    }

    final lookup = _rateLookupToSummaryFormat(rateLookup);
    final summary = buildOrderSummary(cart.items, lookup);

    final header = <String, dynamic>{
      'customer_name': session.customerShopName ?? '',
      'order_date': _today(),
      'customer_mobile': session.customerMobile ?? '',
      'customer_id': session.customerId,
      'source': 'customer',
      'status': 'pending',
      'total_amount': summary.grandTotal,
    };

    Map<String, dynamic> created;
    try {
      created = await _orderRepo.insertOrderHeader(header);
    } catch (e) {
      return OrderSaveFailed(e.toString());
    }

    final orderId = created['order_id'] as int?;
    if (orderId == null) {
      return const OrderSaveFailed('No order_id returned');
    }

    final itemRows = cart.items.map((item) {
      final row = _itemToRow(item, rateLookup);
      row['order_id'] = orderId;
      return row;
    }).toList();

    try {
      await _orderRepo.insertOrderItems(itemRows);
    } catch (e) {
      try {
        await _orderRepo.deleteOrder(orderId);
      } catch (rollbackErr) {
        return RollbackFailed(
          originalError: e.toString(),
          rollbackError: rollbackErr.toString(),
        );
      }
      return OrderSaveFailed(e.toString());
    }

    return CustomerOrderSuccess(orderId: orderId);
  }
}

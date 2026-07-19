import 'package:flutter_test/flutter_test.dart';
import 'package:mahalaxmi_shared/models/cart_item.dart';
import 'package:mahalaxmi_shared/models/item.dart';
import 'package:mahalaxmi_shared/models/order.dart';
import 'package:mahalaxmi_shared/services/repeat_order_item.dart';

void main() {
  final rateItem = RateItem(
    itemNumber: 'CH-001',
    category: 'Chuda',
    hasSizes: true,
    hasColor: false,
    isAvailable: true,
    sellingPrice: 200,
  );

  final unavailableItem = rateItem.copyWith(isAvailable: false);
  final zeroPriceItem = rateItem.copyWith(sellingPrice: 0);

  group('validateRepeatableItem', () {
    test('returns null for valid item', () {
      expect(validateRepeatableItem(rateItem), isNull);
    });

    test('returns error when item is null', () {
      expect(validateRepeatableItem(null), equals('Item not found in catalogue'));
    });

    test('returns error when item is not available', () {
      expect(validateRepeatableItem(unavailableItem), equals('Item is no longer available'));
    });

    test('returns error when selling price is zero', () {
      expect(validateRepeatableItem(zeroPriceItem), equals('Item has no selling price'));
    });
  });

  group('orderItemToCartItem', () {
    test('converts sized OrderItem to CartItem preserving size quantities', () {
      final orderItem = OrderItem(
        itemNumber: 'CH-001',
        category: 'Chuda',
        qty22: 2,
        qty24: 3,
        qty26: 1,
        color: null,
        quantity: 0,
      );

      final cartItem = orderItemToCartItem(orderItem, rateItem);

      expect(cartItem, isA<CartItem>());
      expect(cartItem.itemNumber, equals('CH-001'));
      expect(cartItem.category, equals('Chuda'));
      expect(cartItem.hasSizes, isTrue);
      expect(cartItem.hasColor, isFalse);
      expect(cartItem.qty22, equals(2));
      expect(cartItem.qty24, equals(3));
      expect(cartItem.qty26, equals(1));
      expect(cartItem.qty28, equals(0));
      expect(cartItem.qty210, equals(0));
      expect(cartItem.quantity, equals(0));
      expect(cartItem.unitPrice, equals(200)); // current catalogue price
    });

    test('converts quantity-based OrderItem to CartItem restoring quantity', () {
      final rateItemNoSizes = rateItem.copyWith(hasSizes: false);
      final orderItem = OrderItem(
        itemNumber: 'KL-001',
        category: 'Kaleera',
        quantity: 10,
        color: 'Red',
      );

      final cartItem = orderItemToCartItem(orderItem, rateItemNoSizes);

      expect(cartItem, isA<CartItem>());
      expect(cartItem.itemNumber, equals('KL-001'));
      expect(cartItem.hasSizes, isFalse);
      expect(cartItem.quantity, equals(10));
      expect(cartItem.color, equals('Red'));
      expect(cartItem.unitPrice, equals(200)); // current catalogue price
    });

    test('uses current catalogue unitPrice not old order price', () {
      final orderItem = OrderItem(
        itemNumber: 'CH-001',
        category: 'Chuda',
        qty22: 5,
        unitPrice: 50, // old order price
      );

      final cartItem = orderItemToCartItem(orderItem, rateItem);

      expect(cartItem.unitPrice, equals(200)); // current catalogue price, not 50
    });

    test('preserves color from OrderItem', () {
      final orderItem = OrderItem(
        itemNumber: 'KL-001',
        category: 'Kaleera',
        quantity: 5,
        color: 'Dark Mehroon',
      );

      final cartItem = orderItemToCartItem(orderItem, rateItem.copyWith(hasColor: true));

      expect(cartItem.color, equals('Dark Mehroon'));
    });
  });
}

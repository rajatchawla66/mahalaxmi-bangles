import 'package:flutter_test/flutter_test.dart';
import 'package:mahalaxmi_shared/services/validation.dart';
import 'package:mahalaxmi_shared/models/cart_item.dart';

void main() {
  group('validateCartItem', () {
    group('Chuda (sized items)', () {
      test('valid — at least one size has qty', () {
        final item = CartItem(
          itemNumber: 'CH-001',
          category: 'Chuda',
          hasSizes: true,
          qty22: 5,
        );
        expect(validateCartItem(item, 'Chuda'), isNull);
      });

      test('valid — multiple sizes with qty', () {
        final item = CartItem(
          itemNumber: 'CH-002',
          category: 'Chuda',
          hasSizes: true,
          qty22: 2,
          qty24: 3,
          qty26: 1,
        );
        expect(validateCartItem(item, 'Chuda'), isNull);
      });

      test('invalid — all sizes zero', () {
        final item = CartItem(
          itemNumber: 'CH-003',
          category: 'Chuda',
          hasSizes: true,
        );
        final result = validateCartItem(item, 'Chuda');
        expect(result, contains('At least one size must have quantity > 0'));
        expect(result, contains('CH-003'));
      });

      test('invalid — all sizes zero via schema fallback (hasSizes not set)', () {
        final item = CartItem(
          itemNumber: 'CH-004',
          category: 'Chuda',
          hasSizes: false,
        );
        final result = validateCartItem(item, 'Chuda');
        expect(result, contains('At least one size must have quantity > 0'));
      });
    });

    group('Kaleera (qty + color)', () {
      test('valid — qty >= 1 and color set', () {
        final item = CartItem(
          itemNumber: 'KL-001',
          category: 'Kaleera',
          quantity: 3,
          color: 'Red',
          hasColor: true,
        );
        expect(validateCartItem(item, 'Kaleera'), isNull);
      });

      test('valid — qty >= 1, hasColor=true, color set', () {
        final item = CartItem(
          itemNumber: 'KL-002',
          category: 'Kaleera',
          quantity: 2,
          color: 'Rani',
          hasColor: true,
        );
        expect(validateCartItem(item, 'Kaleera'), isNull);
      });

      test('invalid — qty < 1 with hasColor=true', () {
        final item = CartItem(
          itemNumber: 'KL-003',
          category: 'Kaleera',
          quantity: 0,
          color: 'Red',
          hasColor: true,
        );
        final result = validateCartItem(item, 'Kaleera');
        expect(result, contains('Quantity must be at least 1 for Kaleera'));
      });

      test('invalid — no color when hasColor=true', () {
        final item = CartItem(
          itemNumber: 'KL-004',
          category: 'Kaleera',
          quantity: 2,
          hasColor: true,
        );
        final result = validateCartItem(item, 'Kaleera');
        expect(result, contains('Color is required for Kaleera'));
      });

      test('valid — no color when hasColor=false (item without color attribute)', () {
        final item = CartItem(
          itemNumber: 'KL-005',
          category: 'Kaleera',
          quantity: 2,
          hasColor: false,
        );
        expect(validateCartItem(item, 'Kaleera'), isNull);
      });

      test('invalid — qty 0 when hasColor=false', () {
        final item = CartItem(
          itemNumber: 'KL-006',
          category: 'Kaleera',
          quantity: 0,
          hasColor: false,
        );
        final result = validateCartItem(item, 'Kaleera');
        expect(result, contains('Quantity must be at least 1 for Kaleera'));
      });
    });

    group('Raw_Material (qty range)', () {
      test('valid — qty within range', () {
        final item = CartItem(
          itemNumber: 'RM-001',
          category: 'Raw_Material',
          quantity: 50.5,
        );
        expect(validateCartItem(item, 'Raw_Material'), isNull);
      });

      test('valid — qty at minimum', () {
        final item = CartItem(
          itemNumber: 'RM-002',
          category: 'Raw_Material',
          quantity: 0.01,
        );
        expect(validateCartItem(item, 'Raw_Material'), isNull);
      });

      test('valid — qty at maximum', () {
        final item = CartItem(
          itemNumber: 'RM-003',
          category: 'Raw_Material',
          quantity: 99999.99,
        );
        expect(validateCartItem(item, 'Raw_Material'), isNull);
      });

      test('invalid — qty zero', () {
        final item = CartItem(
          itemNumber: 'RM-004',
          category: 'Raw_Material',
          quantity: 0,
        );
        final result = validateCartItem(item, 'Raw_Material');
        expect(result, contains('greater than 0'));
      });

      test('invalid — qty too small', () {
        final item = CartItem(
          itemNumber: 'RM-005',
          category: 'Raw_Material',
          quantity: 0.001,
        );
        final result = validateCartItem(item, 'Raw_Material');
        expect(result, contains('between 0.01 and 99999.99'));
      });

      test('invalid — qty too large', () {
        final item = CartItem(
          itemNumber: 'RM-006',
          category: 'Raw_Material',
          quantity: 100000,
        );
        final result = validateCartItem(item, 'Raw_Material');
        expect(result, contains('between 0.01 and 99999.99'));
      });

      test('invalid — more than 2 decimal places', () {
        final item = CartItem(
          itemNumber: 'RM-007',
          category: 'Raw_Material',
          quantity: 50.123,
        );
        final result = validateCartItem(item, 'Raw_Material');
        expect(result, contains('at most 2 decimal places'));
      });

      test('valid — exactly 2 decimal places', () {
        final item = CartItem(
          itemNumber: 'RM-008',
          category: 'Raw_Material',
          quantity: 50.12,
        );
        expect(validateCartItem(item, 'Raw_Material'), isNull);
      });
    });

    group('Metal_Bangles (sized items)', () {
      test('valid — at least one size has qty', () {
        final item = CartItem(
          itemNumber: 'MB-001',
          category: 'Metal_Bangles',
          hasSizes: true,
          qty26: 10,
        );
        expect(validateCartItem(item, 'Metal_Bangles'), isNull);
      });

      test('invalid — all sizes zero', () {
        final item = CartItem(
          itemNumber: 'MB-002',
          category: 'Metal_Bangles',
          hasSizes: true,
        );
        final result = validateCartItem(item, 'Metal_Bangles');
        expect(result, contains('At least one size must have quantity > 0'));
      });
    });

    group('Seasonal (qty >= 1)', () {
      test('valid — qty >= 1', () {
        final item = CartItem(
          itemNumber: 'SN-001',
          category: 'Seasonal',
          quantity: 5,
        );
        expect(validateCartItem(item, 'Seasonal'), isNull);
      });

      test('invalid — qty < 1', () {
        final item = CartItem(
          itemNumber: 'SN-002',
          category: 'Seasonal',
          quantity: 0,
        );
        final result = validateCartItem(item, 'Seasonal');
        expect(result, contains('Quantity must be at least 1 for Seasonal'));
      });
    });

    group('Dynamic category (no schema)', () {
      test('valid — hasSizes with qty', () {
        final item = CartItem(
          itemNumber: 'DC-001',
          category: 'Custom_Category',
          hasSizes: true,
          qty22: 3,
        );
        expect(validateCartItem(item, 'Custom_Category'), isNull);
      });

      test('invalid — hasSizes with no qty', () {
        final item = CartItem(
          itemNumber: 'DC-002',
          category: 'Custom_Category',
          hasSizes: true,
        );
        final result = validateCartItem(item, 'Custom_Category');
        expect(result, contains('At least one size must have quantity > 0'));
      });

      test('valid — non-sized with qty >= 1', () {
        final item = CartItem(
          itemNumber: 'DC-003',
          category: 'Custom_Category',
          hasSizes: false,
          quantity: 1,
        );
        expect(validateCartItem(item, 'Custom_Category'), isNull);
      });

      test('invalid — non-sized with qty 0', () {
        final item = CartItem(
          itemNumber: 'DC-004',
          category: 'Custom_Category',
          hasSizes: false,
          quantity: 0,
        );
        final result = validateCartItem(item, 'Custom_Category');
        expect(result, contains('Quantity must be at least 1'));
      });

      test('valid — unknown category (e.g. Kalira) with no color attribute', () {
        final item = CartItem(
          itemNumber: 'shop',
          category: 'Kalira',
          hasColor: false,
          hasSizes: false,
          quantity: 1,
        );
        expect(validateCartItem(item, 'Kalira'), isNull);
      });
    });
  });

  group('validateOrder', () {
    test('valid order passes', () {
      final cart = [
        CartItem(
          itemNumber: 'CH-001',
          category: 'Chuda',
          hasSizes: true,
          qty22: 5,
          unitPrice: 100,
        ),
      ];
      final rateLookup = {
        'CH-001': {
          'category': 'Chuda',
          'selling_price': 100,
          'has_sizes': true,
        },
      };
      expect(validateOrder(cart, rateLookup), isNull);
    });

    test('empty cart returns error', () {
      expect(
        validateOrder([], {}),
        equals('Cart is empty.'),
      );
    });

    test('item not in rate lookup returns error', () {
      final cart = [
        CartItem(itemNumber: 'NONEXIST', category: 'Chuda'),
      ];
      final result = validateOrder(cart, {});
      expect(result, contains('not found in rate list'));
    });
  });
}

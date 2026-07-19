import 'package:flutter_test/flutter_test.dart';
import 'package:mahalaxmi_shared/models/cart_item.dart';
import 'package:mahalaxmi_shared/models/order.dart';
import 'package:mahalaxmi_shared/models/order_summary.dart';
import 'package:mahalaxmi_shared/services/calculation.dart';

void main() {
  group('calculateLineTotal', () {
    group('Chuda (sum_sizes_x_price)', () {
      test('single size with qty', () {
        final item = CartItem(
          itemNumber: 'CH-001',
          category: 'Chuda',
          hasSizes: true,
          qty22: 5,
          unitPrice: 100,
        );
        expect(calculateLineTotal(item, 'Chuda', 100), equals(500.0));
      });

      test('multiple sizes summed', () {
        final item = CartItem(
          itemNumber: 'CH-002',
          category: 'Chuda',
          hasSizes: true,
          qty22: 2,
          qty24: 3,
          qty26: 1,
          unitPrice: 200,
        );
        // (2+3+1) * 200 = 1200
        expect(calculateLineTotal(item, 'Chuda', 200), equals(1200.0));
      });

      test('zero quantities', () {
        final item = CartItem(
          itemNumber: 'CH-003',
          category: 'Chuda',
          hasSizes: true,
          unitPrice: 100,
        );
        expect(calculateLineTotal(item, 'Chuda', 100), equals(0.0));
      });
    });

    group('Kaleera (qty_x_price)', () {
      test('qty * price', () {
        final item = CartItem(
          itemNumber: 'KL-001',
          category: 'Kaleera',
          quantity: 10,
          unitPrice: 50,
        );
        expect(calculateLineTotal(item, 'Kaleera', 50), equals(500.0));
      });

      test('zero qty', () {
        final item = CartItem(
          itemNumber: 'KL-002',
          category: 'Kaleera',
          quantity: 0,
          unitPrice: 50,
        );
        expect(calculateLineTotal(item, 'Kaleera', 50), equals(0.0));
      });
    });

    group('Raw_Material (qty_x_price)', () {
      test('float qty * price', () {
        final item = CartItem(
          itemNumber: 'RM-001',
          category: 'Raw_Material',
          quantity: 2.5,
          unitPrice: 100,
        );
        expect(calculateLineTotal(item, 'Raw_Material', 100), equals(250.0));
      });
    });

    group('Metal_Bangles (sum_sizes_x_price)', () {
      test('size quantities * price', () {
        final item = CartItem(
          itemNumber: 'MB-001',
          category: 'Metal_Bangles',
          hasSizes: true,
          qty28: 4,
          qty210: 6,
          unitPrice: 300,
        );
        expect(calculateLineTotal(item, 'Metal_Bangles', 300), equals(3000.0));
      });
    });

    group('Seasonal (qty_x_price)', () {
      test('qty * price', () {
        final item = CartItem(
          itemNumber: 'SN-001',
          category: 'Seasonal',
          quantity: 7,
          unitPrice: 25,
        );
        expect(calculateLineTotal(item, 'Seasonal', 25), equals(175.0));
      });
    });

    group('Dynamic category', () {
      test('hasSizes uses sum_sizes_x_price', () {
        final item = CartItem(
          itemNumber: 'DC-001',
          category: 'CustomCat',
          hasSizes: true,
          qty22: 3,
          unitPrice: 150,
        );
        expect(calculateLineTotal(item, 'CustomCat', 150), equals(450.0));
      });

      test('non-sized uses qty_x_price', () {
        final item = CartItem(
          itemNumber: 'DC-002',
          category: 'CustomCat',
          hasSizes: false,
          quantity: 4,
          unitPrice: 75,
        );
        expect(calculateLineTotal(item, 'CustomCat', 75), equals(300.0));
      });
    });

    test('rounds to 2 decimal places', () {
      final item = CartItem(
        itemNumber: 'RM-001',
        category: 'Raw_Material',
        quantity: 3.333,
        unitPrice: 10,
      );
      expect(calculateLineTotal(item, 'Raw_Material', 10), equals(33.33));
    });
  });

  group('buildOrderSummary', () {
    test('groups items by category', () {
      final cart = [
        CartItem(
          itemNumber: 'CH-001',
          category: 'Chuda',
          hasSizes: true,
          qty22: 5,
          unitPrice: 100,
        ),
        CartItem(
          itemNumber: 'KL-001',
          category: 'Kaleera',
          quantity: 3,
          color: 'Red',
          unitPrice: 50,
        ),
      ];
      final rateLookup = {
        'CH-001': {
          'category': 'Chuda',
          'selling_price': 100,
          'image_url': '',
        },
        'KL-001': {
          'category': 'Kaleera',
          'selling_price': 50,
          'image_url': '',
        },
      };

      final summary = buildOrderSummary(cart, rateLookup);

      expect(summary.groups.length, equals(2));
      expect(summary.groups[0].category, equals('Chuda'));
      expect(summary.groups[1].category, equals('Kaleera'));
      expect(summary.grandTotal, equals(500.0 + 150.0));
    });

    test('categories sorted alphabetically', () {
      final cart = [
        CartItem(itemNumber: 'Z-001', category: 'Zebra', quantity: 1, unitPrice: 10),
        CartItem(itemNumber: 'A-001', category: 'Alpha', quantity: 1, unitPrice: 20),
      ];
      final rateLookup = {
        'Z-001': {'category': 'Zebra', 'selling_price': 10, 'image_url': ''},
        'A-001': {'category': 'Alpha', 'selling_price': 20, 'image_url': ''},
      };

      final summary = buildOrderSummary(cart, rateLookup);

      expect(summary.groups.length, equals(2));
      expect(summary.groups[0].category, equals('Alpha'));
      expect(summary.groups[1].category, equals('Zebra'));
    });

    test('single category with multiple items', () {
      final cart = [
        CartItem(
          itemNumber: 'CH-001', category: 'Chuda',
          hasSizes: true, qty22: 2, unitPrice: 100,
        ),
        CartItem(
          itemNumber: 'CH-002', category: 'Chuda',
          hasSizes: true, qty24: 3, unitPrice: 150,
        ),
      ];
      final rateLookup = {
        'CH-001': {'category': 'Chuda', 'selling_price': 100, 'image_url': ''},
        'CH-002': {'category': 'Chuda', 'selling_price': 150, 'image_url': ''},
      };

      final summary = buildOrderSummary(cart, rateLookup);

      expect(summary.groups.length, equals(1));
      expect(summary.groups[0].items.length, equals(2));
      expect(summary.groups[0].subtotal, equals(200.0 + 450.0));
    });

    test('empty cart returns empty summary', () {
      final summary = buildOrderSummary([], {});
      expect(summary.groups, isEmpty);
      expect(summary.grandTotal, equals(0.0));
    });

    test('items without rate lookup use item unitPrice', () {
      final cart = [
        CartItem(
          itemNumber: 'NEW-001', category: 'Chuda',
          hasSizes: true, qty22: 5, unitPrice: 100,
        ),
      ];
      final summary = buildOrderSummary(cart, {});

      expect(summary.groups.length, equals(1));
      expect(summary.groups[0].subtotal, equals(500.0));
    });
  });

  group('OrderItem.lineTotal', () {
    test('sized item uses totalSizeQty * unitPrice', () {
      final item = OrderItem(
        itemNumber: 'CH-001',
        category: 'Chuda',
        qty24: 3,
        qty26: 2,
        unitPrice: 100,
      );
      expect(item.totalSizeQty, equals(5));
      expect(item.lineTotal, equals(500.0));
    });

    test('non-sized item uses quantity * unitPrice', () {
      final item = OrderItem(
        itemNumber: 'KL-001',
        category: 'Kaleera',
        quantity: 3,
        unitPrice: 500,
      );
      expect(item.totalSizeQty, equals(0));
      expect(item.lineTotal, equals(1500.0));
    });

    test('item with both sized and quantity uses totalSizeQty', () {
      final item = OrderItem(
        itemNumber: 'DC-001',
        category: 'Custom',
        qty22: 2,
        quantity: 5,
        unitPrice: 100,
      );
      expect(item.totalSizeQty, equals(2));
      expect(item.lineTotal, equals(200.0));
    });
  });

  group('Order fromJson', () {
    test('parses order_items from snake_case key', () {
      final json = {
        'order_id': 1,
        'customer_name': 'Test',
        'order_date': '2026-06-13',
        'total_amount': 1500,
        'source': 'customer',
        'status': 'pending',
        'order_items': [
          {
            'item_number': 'CH-001',
            'category': 'Chuda',
            'qty_2_4': 3,
            'unit_price': 500,
          },
        ],
      };
      final order = Order.fromJson(json);
      expect(order.orderId, equals(1));
      expect(order.totalAmount, equals(1500.0));
      expect(order.orderItems.length, equals(1));
      expect(order.orderItems[0].itemNumber, equals('CH-001'));
      expect(order.orderItems[0].lineTotal, equals(1500.0));
    });

    test('parses order_items as empty list when key missing', () {
      final json = {
        'order_id': 2,
        'customer_name': 'Test',
        'order_date': '2026-06-13',
        'total_amount': 500,
      };
      final order = Order.fromJson(json);
      expect(order.orderItems, isEmpty);
    });

    test('parses production_status as Map (new Flutter orders)', () {
      final json = {
        'order_id': 3,
        'customer_name': 'Test',
        'order_date': '2026-06-13',
        'total_amount': 500,
        'order_items': [
          {
            'item_number': 'CH-001',
            'production_status': {},
          },
        ],
      };
      final order = Order.fromJson(json);
      expect(order.orderItems[0].productionStatus, isEmpty);
    });

    test('parses production_status as String (legacy Flet orders)', () {
      final json = {
        'order_id': 4,
        'customer_name': 'Test',
        'order_date': '2026-06-13',
        'total_amount': 500,
        'order_items': [
          {
            'item_number': 'CH-001',
            'production_status': '{"2.4": "prepared", "2.6": "prepared"}',
          },
        ],
      };
      final order = Order.fromJson(json);
      expect(order.orderItems[0].productionStatus, hasLength(2));
      expect(order.orderItems[0].productionStatus['2.4'], equals('prepared'));
      expect(order.orderItems[0].productionStatus['2.6'], equals('prepared'));
    });

    test('parses production_status as null', () {
      final json = {
        'order_id': 5,
        'customer_name': 'Test',
        'order_date': '2026-06-13',
        'total_amount': 500,
        'order_items': [
          {
            'item_number': 'CH-001',
            'production_status': null,
          },
        ],
      };
      final order = Order.fromJson(json);
      expect(order.orderItems[0].productionStatus, isEmpty);
    });

    test('handles invalid production_status string gracefully', () {
      final json = {
        'order_id': 6,
        'customer_name': 'Test',
        'order_date': '2026-06-13',
        'total_amount': 500,
        'order_items': [
          {
            'item_number': 'CH-001',
            'production_status': 'not-json',
          },
        ],
      };
      final order = Order.fromJson(json);
      expect(order.orderItems[0].productionStatus, isEmpty);
    });
  });
}

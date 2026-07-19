import 'package:flutter_test/flutter_test.dart';
import 'package:mahalaxmi_shared/models/cart_item.dart';
import 'package:mahalaxmi_shared/models/cart_state.dart';
import 'package:mahalaxmi_shared/providers/cart_provider.dart';

void main() {
  group('CartLine', () {
    test('create generates unique ids', () {
      final line1 = CartLine.create(
        CartItem(itemNumber: 'A', category: 'Chuda'),
      );
      final line2 = CartLine.create(
        CartItem(itemNumber: 'B', category: 'Chuda'),
      );
      expect(line1.id, isNot(equals(line2.id)));
    });

    test('equals and hashCode use id', () {
      final item = CartItem(itemNumber: 'X', category: 'Chuda');
      final a = CartLine(id: 'same-id', item: item);
      final b = CartLine(id: 'same-id', item: item);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different ids are not equal', () {
      final a = CartLine(id: 'id-1', item: CartItem(itemNumber: 'X', category: 'Chuda'));
      final b = CartLine(id: 'id-2', item: CartItem(itemNumber: 'X', category: 'Chuda'));
      expect(a, isNot(equals(b)));
    });
  });

  group('CartState', () {
    test('initial state is empty', () {
      expect(CartState.initial.lines, isEmpty);
      expect(CartState.initial.itemCount, 0);
      expect(CartState.initial.items, isEmpty);
    });

    test('findById returns correct line', () {
      final line = CartLine(id: 'abc', item: CartItem(itemNumber: 'X', category: 'Chuda'));
      final state = CartState(lines: [line]);
      expect(state.findById('abc'), equals(line));
      expect(state.findById('xyz'), isNull);
    });

    test('items getter extracts CartItem list', () {
      final line1 = CartLine(id: '1', item: CartItem(itemNumber: 'A', category: 'Chuda'));
      final line2 = CartLine(id: '2', item: CartItem(itemNumber: 'B', category: 'Kaleera'));
      final state = CartState(lines: [line1, line2]);
      expect(state.items.length, 2);
      expect(state.items[0].itemNumber, 'A');
      expect(state.items[1].itemNumber, 'B');
    });
  });

  group('CartNotifier', () {
    late CartNotifier notifier;

    setUp(() {
      notifier = CartNotifier();
    });

    group('addItem', () {
      test('adds new item to empty cart', () {
        final item = CartItem(
          itemNumber: 'KL-001',
          category: 'Kaleera',
          quantity: 3,
          color: 'Red',
          unitPrice: 50,
        );

        final result = notifier.addItem(item, 'Kaleera');

        expect(result, isA<CartAddSuccess>());
        expect((result as CartAddSuccess).merged, false);
        expect(notifier.state.itemCount, 1);
        expect(notifier.state.items.first.itemNumber, 'KL-001');
      });

      test('adds multiple distinct items', () {
        notifier.addItem(
          CartItem(itemNumber: 'CH-001', category: 'Chuda', hasSizes: true, qty22: 2, unitPrice: 100),
          'Chuda',
        );
        notifier.addItem(
          CartItem(itemNumber: 'KL-001', category: 'Kaleera', quantity: 1, color: 'Red', unitPrice: 50),
          'Kaleera',
        );

        expect(notifier.state.itemCount, 2);
      });

      test('merges same variant (sized) by summing size quantities', () {
        notifier.addItem(
          CartItem(itemNumber: 'CH-001', category: 'Chuda', hasSizes: true, qty22: 2, qty24: 1, unitPrice: 100),
          'Chuda',
        );
        final result = notifier.addItem(
          CartItem(itemNumber: 'CH-001', category: 'Chuda', hasSizes: true, qty22: 3, qty26: 2, unitPrice: 100),
          'Chuda',
        );

        expect(result, isA<CartAddSuccess>());
        expect((result as CartAddSuccess).merged, true);
        expect(notifier.state.itemCount, 1);

        final merged = notifier.state.items.first;
        expect(merged.qty22, 5); // 2 + 3
        expect(merged.qty24, 1);
        expect(merged.qty26, 2);
        expect(merged.qty28, 0);
        expect(merged.qty210, 0);
      });

      test('merges same variant (non-sized) by summing quantity', () {
        notifier.addItem(
          CartItem(itemNumber: 'KL-001', category: 'Kaleera', quantity: 2, color: 'Red', unitPrice: 50),
          'Kaleera',
        );
        notifier.addItem(
          CartItem(itemNumber: 'KL-001', category: 'Kaleera', quantity: 3, color: 'Red', unitPrice: 50),
          'Kaleera',
        );

        expect(notifier.state.itemCount, 1);
        expect(notifier.state.items.first.quantity, 5); // 2 + 3
      });

      test('does not merge different colors', () {
        notifier.addItem(
          CartItem(itemNumber: 'KL-001', category: 'Kaleera', quantity: 2, color: 'Red', unitPrice: 50),
          'Kaleera',
        );
        notifier.addItem(
          CartItem(itemNumber: 'KL-001', category: 'Kaleera', quantity: 3, color: 'Blue', unitPrice: 50),
          'Kaleera',
        );

        expect(notifier.state.itemCount, 2);
      });

      test('does not merge different grind types', () {
        notifier.addItem(
          CartItem(itemNumber: 'CH-001', category: 'Chuda', hasSizes: true, qty22: 2, grindType: 'Regular', unitPrice: 100),
          'Chuda',
        );
        notifier.addItem(
          CartItem(itemNumber: 'CH-001', category: 'Chuda', hasSizes: true, qty22: 1, grindType: 'Fancy', unitPrice: 100),
          'Chuda',
        );

        expect(notifier.state.itemCount, 2);
      });

      test('does not merge different box types', () {
        notifier.addItem(
          CartItem(itemNumber: 'CH-001', category: 'Chuda', hasSizes: true, qty22: 2, boxType: 'Box A', unitPrice: 100),
          'Chuda',
        );
        notifier.addItem(
          CartItem(itemNumber: 'CH-001', category: 'Chuda', hasSizes: true, qty22: 1, boxType: 'Box B', unitPrice: 100),
          'Chuda',
        );

        expect(notifier.state.itemCount, 2);
      });

      test('does not merge different notes', () {
        notifier.addItem(
          CartItem(itemNumber: 'CH-001', category: 'Chuda', hasSizes: true, qty22: 2, notes: 'Urgent', unitPrice: 100),
          'Chuda',
        );
        notifier.addItem(
          CartItem(itemNumber: 'CH-001', category: 'Chuda', hasSizes: true, qty22: 1, notes: 'Normal', unitPrice: 100),
          'Chuda',
        );

        expect(notifier.state.itemCount, 2);
      });

      test('does not merge different categories', () {
        notifier.addItem(
          CartItem(itemNumber: 'CH-001', category: 'Chuda', hasSizes: true, qty22: 2, unitPrice: 100),
          'Chuda',
        );
        notifier.addItem(
          CartItem(itemNumber: 'CH-001', category: 'Metal_Bangles', hasSizes: true, qty22: 1, unitPrice: 100),
          'Metal_Bangles',
        );

        expect(notifier.state.itemCount, 2);
      });

      test('validates item on add — rejects invalid', () {
        final item = CartItem(itemNumber: 'CH-001', category: 'Chuda', hasSizes: true, unitPrice: 100);
        final result = notifier.addItem(item, 'Chuda');

        expect(result, isA<CartValidationError>());
        expect((result as CartValidationError).message, contains('At least one size'));
        expect(notifier.state.itemCount, 0);
      });

      test('uses latest unitPrice on merge', () {
        notifier.addItem(
          CartItem(itemNumber: 'CH-001', category: 'Chuda', hasSizes: true, qty22: 2, unitPrice: 100),
          'Chuda',
        );
        notifier.addItem(
          CartItem(itemNumber: 'CH-001', category: 'Chuda', hasSizes: true, qty22: 1, unitPrice: 120),
          'Chuda',
        );

        expect(notifier.state.items.first.unitPrice, 120);
      });
    });

    group('removeItem', () {
      test('removes item by id', () {
        final result = notifier.addItem(
          CartItem(itemNumber: 'A', category: 'Chuda', hasSizes: true, qty22: 1, unitPrice: 10),
          'Chuda',
        );
        final id = (result as CartAddSuccess).lineId;

        notifier.removeItem(id);
        expect(notifier.state.itemCount, 0);
      });

      test('does nothing for unknown id', () {
        notifier.addItem(
          CartItem(itemNumber: 'A', category: 'Chuda', hasSizes: true, qty22: 1, unitPrice: 10),
          'Chuda',
        );
        notifier.removeItem('non-existent');
        expect(notifier.state.itemCount, 1);
      });

      test('removes correct item when multiple exist', () {
        notifier.addItem(
          CartItem(itemNumber: 'A', category: 'Chuda', hasSizes: true, qty22: 1, unitPrice: 10),
          'Chuda',
        );
        final r2 = notifier.addItem(
          CartItem(itemNumber: 'B', category: 'Chuda', hasSizes: true, qty22: 2, unitPrice: 20),
          'Chuda',
        );
        final id2 = (r2 as CartAddSuccess).lineId;

        notifier.removeItem(id2);
        expect(notifier.state.itemCount, 1);
        expect(notifier.state.items.first.itemNumber, 'A');
      });
    });

    group('updateItem', () {
      test('updates item quantities', () {
        final result = notifier.addItem(
          CartItem(itemNumber: 'CH-001', category: 'Chuda', hasSizes: true, qty22: 2, unitPrice: 100),
          'Chuda',
        );
        final id = (result as CartAddSuccess).lineId;

        final updated = CartItem(
          itemNumber: 'CH-001', category: 'Chuda', hasSizes: true,
          qty22: 5, unitPrice: 100,
        );
        final updateResult = notifier.updateItem(id, updated);

        expect(updateResult, isA<CartUpdateSuccess>());
        expect(notifier.state.items.first.qty22, 5);
      });

      test('rejects invalid update', () {
        final result = notifier.addItem(
          CartItem(itemNumber: 'CH-001', category: 'Chuda', hasSizes: true, qty22: 2, unitPrice: 100),
          'Chuda',
        );
        final id = (result as CartAddSuccess).lineId;

        final invalid = CartItem(
          itemNumber: 'CH-001', category: 'Chuda', hasSizes: true, unitPrice: 100,
        );
        final updateResult = notifier.updateItem(id, invalid);

        expect(updateResult, isA<CartValidationError>());
        expect(notifier.state.items.first.qty22, 2); // unchanged
      });

      test('returns error for unknown id', () {
        final result = notifier.updateItem(
          'no-such-id',
          CartItem(itemNumber: 'X', category: 'Chuda', quantity: 1, unitPrice: 10),
        );
        expect(result, isA<CartMutationError>());
      });
    });

    group('clear', () {
      test('removes all items', () {
        notifier.addItem(
          CartItem(itemNumber: 'A', category: 'Chuda', hasSizes: true, qty22: 1, unitPrice: 10),
          'Chuda',
        );
        notifier.addItem(
          CartItem(itemNumber: 'B', category: 'Kaleera', quantity: 2, color: 'Red', unitPrice: 20),
          'Kaleera',
        );
        expect(notifier.state.itemCount, 2);

        notifier.clear();
        expect(notifier.state, equals(CartState.initial));
        expect(notifier.state.itemCount, 0);
      });
    });

    group('validateAll', () {
      test('returns empty for valid cart', () {
        notifier.addItem(
          CartItem(itemNumber: 'CH-001', category: 'Chuda', hasSizes: true, qty22: 1, unitPrice: 100),
          'Chuda',
        );
        notifier.addItem(
          CartItem(itemNumber: 'KL-001', category: 'Kaleera', quantity: 2, color: 'Red', unitPrice: 50),
          'Kaleera',
        );

        final errors = notifier.validateAll();
        expect(errors, isEmpty);
      });

      test('returns empty for empty cart', () {
        expect(notifier.validateAll(), isEmpty);
      });

      test('detects invalid items when state is directly manipulated', () {
        // Simulate a corrupt state by bypassing addItem validation
        notifier.state = CartState(lines: [
          CartLine(
            id: 'test-id',
            item: CartItem(
              itemNumber: 'CH-BAD',
              category: 'Chuda',
              hasSizes: true,
              unitPrice: 100,
            ),
          ),
        ]);

        final errors = notifier.validateAll();
        expect(errors, isNotEmpty);
        expect(errors.first.itemNumber, 'CH-BAD');
        expect(errors.first.message, contains('At least one size'));
      });

      test('validates all lines independently', () {
        // Set up cart with one valid and one invalid item via state mutation
        notifier.state = CartState(lines: [
          CartLine(
            id: 'good-id',
            item: CartItem(
              itemNumber: 'CH-GOOD', category: 'Chuda', hasSizes: true,
              qty22: 1, unitPrice: 100,
            ),
          ),
          CartLine(
            id: 'bad-id',
            item: CartItem(
              itemNumber: 'KL-BAD', category: 'Kaleera',
              color: 'Red', unitPrice: 50,
            ),
          ),
        ]);

        final errors = notifier.validateAll();
        expect(errors.length, 1);
        expect(errors.first.itemNumber, 'KL-BAD');
      });
    });

    group('dynamic categories', () {
      test('adds item with unknown category and hasSizes=true', () {
        final item = CartItem(
          itemNumber: 'NEW-001',
          category: 'Custom_Category',
          hasSizes: true,
          qty22: 3,
          qty24: 1,
          unitPrice: 200,
        );
        final result = notifier.addItem(item, 'Custom_Category');
        expect(result, isA<CartAddSuccess>());
        expect(notifier.state.itemCount, 1);
      });

      test('adds item with unknown category and hasSizes=false', () {
        final item = CartItem(
          itemNumber: 'NEW-002',
          category: 'Another_Category',
          hasSizes: false,
          quantity: 5,
          unitPrice: 100,
        );
        final result = notifier.addItem(item, 'Another_Category');
        expect(result, isA<CartAddSuccess>());
        expect(notifier.state.itemCount, 1);
      });

      test('validates dynamic category with hasSizes and no qty', () {
        final item = CartItem(
          itemNumber: 'NEW-003',
          category: 'Unknown',
          hasSizes: true,
          unitPrice: 100,
        );
        final result = notifier.addItem(item, 'Unknown');
        expect(result, isA<CartValidationError>());
        expect(notifier.state.itemCount, 0);
      });

      test('validates dynamic category non-sized with zero qty', () {
        final item = CartItem(
          itemNumber: 'NEW-004',
          category: 'Unknown',
          hasSizes: false,
          quantity: 0,
          unitPrice: 100,
        );
        final result = notifier.addItem(item, 'Unknown');
        expect(result, isA<CartValidationError>());
        expect(notifier.state.itemCount, 0);
      });
    });

    group('Raw_Material category', () {
      test('adds valid raw material item', () {
        final item = CartItem(
          itemNumber: 'RM-001',
          category: 'Raw_Material',
          quantity: 5.5,
          unit: 'kg',
          unitPrice: 200,
        );
        final result = notifier.addItem(item, 'Raw_Material');
        expect(result, isA<CartAddSuccess>());
      });

      test('rejects raw material with zero qty', () {
        final item = CartItem(
          itemNumber: 'RM-002',
          category: 'Raw_Material',
          quantity: 0,
          unit: 'pieces',
          unitPrice: 100,
        );
        final result = notifier.addItem(item, 'Raw_Material');
        expect(result, isA<CartValidationError>());
      });
    });

    group('Seasonal category', () {
      test('adds valid seasonal item', () {
        final item = CartItem(
          itemNumber: 'SN-001',
          category: 'Seasonal',
          quantity: 10,
          notes: 'For Diwali',
          unitPrice: 500,
        );
        final result = notifier.addItem(item, 'Seasonal');
        expect(result, isA<CartAddSuccess>());
      });

      test('rejects seasonal with qty < 1', () {
        final item = CartItem(
          itemNumber: 'SN-002',
          category: 'Seasonal',
          quantity: 0,
          unitPrice: 500,
        );
        final result = notifier.addItem(item, 'Seasonal');
        expect(result, isA<CartValidationError>());
      });
    });
  });
}

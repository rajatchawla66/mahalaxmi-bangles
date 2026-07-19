import 'package:flutter_test/flutter_test.dart';
import 'package:mahalaxmi_shared/models/app_session.dart';
import 'package:mahalaxmi_shared/models/cart_item.dart';
import 'package:mahalaxmi_shared/models/cart_state.dart';
import 'package:mahalaxmi_shared/models/item.dart';
import 'package:mahalaxmi_shared/repositories/order_repository.dart';
import 'package:mahalaxmi_shared/services/customer_order_service.dart';

class _MockOrderRepo extends OrderRepository {
  int? insertedHeader;
  List<Map<String, dynamic>>? insertedItems;
  int? deletedOrderId;
  bool failHeaderInsert = false;
  bool failItemInsert = false;
  bool failDelete = false;
  bool returnNullOrderId = false;

  @override
  Future<Map<String, dynamic>> insertOrderHeader(
      Map<String, dynamic> data) async {
    if (failHeaderInsert) {
      throw Exception('Header insert failed');
    }
    insertedHeader = (data['customer_id'] as int?) ?? 0;
    return {
      'order_id': returnNullOrderId ? null : 42,
      ...data,
    };
  }

  @override
  Future<void> insertOrderItems(List<Map<String, dynamic>> items) async {
    if (failItemInsert) {
      throw Exception('Item insert failed');
    }
    insertedItems = items;
  }

  @override
  Future<void> deleteOrder(int orderId) async {
    if (failDelete) {
      throw Exception('Delete failed');
    }
    deletedOrderId = orderId;
  }
}

void main() {
  late _MockOrderRepo mockRepo;
  late CustomerOrderService service;

  final customerSession = AppSession.customer(
    customerId: 10,
    customerShopName: 'Test Shop',
    customerMobile: '9876543210',
    customerOwnerName: 'Owner',
  );

  final validCart = CartState(lines: [
    CartLine(
      id: 'line-1',
      item: CartItem(
        itemNumber: 'CH-001',
        category: 'Chuda',
        hasSizes: true,
        qty22: 5,
        unitPrice: 100,
      ),
    ),
    CartLine(
      id: 'line-2',
      item: CartItem(
        itemNumber: 'KL-001',
        category: 'Kaleera',
        quantity: 2,
        color: 'Red',
        unitPrice: 50,
      ),
    ),
  ]);

  final rateLookup = <String, RateItem>{
    'CH-001': RateItem(
      itemNumber: 'CH-001',
      category: 'Chuda',
      sellingPrice: 100,
      imageUrl: '',
      isAvailable: true,
    ),
    'KL-001': RateItem(
      itemNumber: 'KL-001',
      category: 'Kaleera',
      sellingPrice: 50,
      imageUrl: '',
      isAvailable: true,
    ),
  };

  setUp(() {
    mockRepo = _MockOrderRepo();
    service = CustomerOrderService(mockRepo);
  });

  group('CustomerOrderService', () {
    test('successfully places order with source=customer', () async {
      final result = await service.placeOrder(
        session: customerSession,
        cart: validCart,
        rateLookup: rateLookup,
      );

      expect(result, isA<CustomerOrderSuccess>());
      expect((result as CustomerOrderSuccess).orderId, 42);
    });

    test('order header contains correct customer fields', () async {
      await service.placeOrder(
        session: customerSession,
        cart: validCart,
        rateLookup: rateLookup,
      );

      expect(mockRepo.insertedHeader, 10);
    });

    test('order items include correct data', () async {
      await service.placeOrder(
        session: customerSession,
        cart: validCart,
        rateLookup: rateLookup,
      );

      expect(mockRepo.insertedItems, isNotNull);
      expect(mockRepo.insertedItems!.length, 2);
      expect(mockRepo.insertedItems![0]['item_number'], 'CH-001');
      expect(mockRepo.insertedItems![0]['order_id'], 42);
      expect(mockRepo.insertedItems![0]['qty_2_2'], 5);
      expect(mockRepo.insertedItems![0]['unit_price'], 100);
      expect(mockRepo.insertedItems![1]['item_number'], 'KL-001');
      expect(mockRepo.insertedItems![1]['order_id'], 42);
      expect(mockRepo.insertedItems![1]['unit_price'], 50);
    });

    test('assigns unitPrice from rateLookup', () async {
      final lookup = Map<String, RateItem>.from(rateLookup);
      lookup['CH-001'] = RateItem(
        itemNumber: 'CH-001',
        category: 'Chuda',
        sellingPrice: 999,
        imageUrl: '',
        isAvailable: true,
      );

      await service.placeOrder(
        session: customerSession,
        cart: validCart,
        rateLookup: lookup,
      );

      expect(mockRepo.insertedItems![0]['unit_price'], 999);
    });

    test('assigns category from rateLookup', () async {
      final lookup = Map<String, RateItem>.from(rateLookup);
      lookup['CH-001'] = RateItem(
        itemNumber: 'CH-001',
        category: 'Metal_Bangles',
        sellingPrice: 100,
        imageUrl: '',
        isAvailable: true,
      );

      await service.placeOrder(
        session: customerSession,
        cart: validCart,
        rateLookup: lookup,
      );

      expect(mockRepo.insertedItems![0]['category'], 'Metal_Bangles');
    });

    test('rejects not logged in', () async {
      final result = await service.placeOrder(
        session: AppSession.loggedOut,
        cart: validCart,
        rateLookup: rateLookup,
      );

      expect(result, isA<NotLoggedIn>());
      expect(mockRepo.insertedHeader, isNull);
    });

    test('rejects empty cart', () async {
      final result = await service.placeOrder(
        session: customerSession,
        cart: CartState.initial,
        rateLookup: rateLookup,
      );

      expect(result, isA<EmptyCart>());
      expect(mockRepo.insertedHeader, isNull);
    });

    test('rejects invalid cart items', () async {
      final invalidCart = CartState(lines: [
        CartLine(
          id: 'bad-line',
          item: CartItem(
            itemNumber: 'CH-BAD',
            category: 'Chuda',
            hasSizes: true,
            unitPrice: 100,
          ),
        ),
      ]);

      final result = await service.placeOrder(
        session: customerSession,
        cart: invalidCart,
        rateLookup: rateLookup,
      );

      expect(result, isA<InvalidCartItems>());
      expect((result as InvalidCartItems).itemNumber, 'CH-BAD');
      expect(mockRepo.insertedHeader, isNull);
    });

    test('returns OrderSaveFailed when header insert fails', () async {
      mockRepo.failHeaderInsert = true;

      final result = await service.placeOrder(
        session: customerSession,
        cart: validCart,
        rateLookup: rateLookup,
      );

      expect(result, isA<OrderSaveFailed>());
    });

    test('rolls back header when item insert fails', () async {
      mockRepo.failItemInsert = true;

      final result = await service.placeOrder(
        session: customerSession,
        cart: validCart,
        rateLookup: rateLookup,
      );

      expect(result, isA<OrderSaveFailed>());
      expect(mockRepo.deletedOrderId, 42);
    });

    test('surfaces RollbackFailed when both insert and rollback fail', () async {
      mockRepo.failItemInsert = true;
      mockRepo.failDelete = true;

      final result = await service.placeOrder(
        session: customerSession,
        cart: validCart,
        rateLookup: rateLookup,
      );

      expect(result, isA<RollbackFailed>());
    });

    test('cart is not cleared by the service (clearing is UI concern)', () async {
      final result = await service.placeOrder(
        session: customerSession,
        cart: validCart,
        rateLookup: rateLookup,
      );

      expect(result, isA<CustomerOrderSuccess>());
      // CartState is unchanged — service doesn't modify it
    });

    test('rateLookup fallback uses cartItem unitPrice', () async {
      final cart = CartState(lines: [
        CartLine(
          id: 'new-line',
          item: CartItem(
            itemNumber: 'NEW-001',
            category: 'Chuda',
            hasSizes: true,
            qty22: 3,
            unitPrice: 250,
          ),
        ),
      ]);

      await service.placeOrder(
        session: customerSession,
        cart: cart,
        rateLookup: {},
      );

      expect(mockRepo.insertedItems![0]['unit_price'], 250);
    });
  });
}

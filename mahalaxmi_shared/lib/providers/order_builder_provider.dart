import 'package:riverpod/riverpod.dart';

import '../services/customer_order_service.dart';
import 'cart_provider.dart';
import 'customer_auth_provider.dart';
import 'items_provider.dart';
import 'repository_providers.dart';
import 'session_provider.dart';

class OrderBuilderController {
  final Ref _ref;
  final CustomerOrderService _service;

  OrderBuilderController({
    required Ref ref,
    required CustomerOrderService service,
  })  : _ref = ref,
        _service = service;

  Future<CustomerOrderResult> placeCustomerOrder() async {
    final session = _ref.read(appSessionProvider);
    if (session.isCustomer && session.customerId != null) {
      final controller = _ref.read(customerAuthControllerProvider);
      if (!await controller.validateActiveSession()) {
        _ref.read(forcedLogoutReasonProvider.notifier).state = 'disabled';
        return const AccountDisabled();
      }
    }
    final cart = _ref.read(cartProvider);
    final rateLookup = await _ref.read(rateLookupProvider.future);
    return _service.placeOrder(
      session: session,
      cart: cart,
      rateLookup: rateLookup,
    );
  }
}

final orderBuilderProvider = Provider<OrderBuilderController>((ref) {
  return OrderBuilderController(
    ref: ref,
    service: CustomerOrderService(ref.read(orderRepositoryProvider)),
  );
});

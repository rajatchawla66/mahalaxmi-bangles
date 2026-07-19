import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahalaxmi_shared/models/order.dart';
import 'package:mahalaxmi_shared/providers/repository_providers.dart';
import 'package:mahalaxmi_shared/providers/session_provider.dart';

final customerOrdersProvider = FutureProvider<List<Order>>((ref) {
  final session = ref.watch(appSessionProvider);
  final customerId = session.customerId;
  if (customerId == null) {
    return [];
  }
  return ref.read(orderRepositoryProvider).getOrdersByCustomerId(customerId);
});

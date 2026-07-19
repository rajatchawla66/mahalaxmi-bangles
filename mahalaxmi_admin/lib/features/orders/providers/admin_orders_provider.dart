import 'package:riverpod/riverpod.dart';
import 'package:mahalaxmi_shared/models/order.dart';
import 'package:mahalaxmi_shared/providers/repository_providers.dart';

final adminAllOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final repo = ref.read(orderRepositoryProvider);
  final orders = await repo.getOrdersWithItems();
  return orders;
});

final adminOrderDetailProvider = FutureProvider.family<Order?, int>((ref, orderId) async {
  final repo = ref.read(orderRepositoryProvider);
  return await repo.getOrderById(orderId);
});

final adminArchivedOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final repo = ref.read(orderRepositoryProvider);
  return await repo.getArchivedOrders();
});


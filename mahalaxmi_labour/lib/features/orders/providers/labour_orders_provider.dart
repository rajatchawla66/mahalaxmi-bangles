import 'package:riverpod/riverpod.dart';
import 'package:mahalaxmi_shared/models/order.dart';
import 'package:mahalaxmi_shared/providers/repository_providers.dart';

final labourOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final repo = ref.read(orderRepositoryProvider);
  return await repo.getOrdersWithItems();
});

final labourOrderDetailProvider =
    FutureProvider.family<Order?, int>((ref, orderId) async {
  final repo = ref.read(orderRepositoryProvider);
  return await repo.getOrderById(orderId);
});

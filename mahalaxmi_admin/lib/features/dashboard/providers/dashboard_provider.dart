import 'package:riverpod/riverpod.dart';
import 'package:mahalaxmi_shared/models/order.dart';
import 'package:mahalaxmi_shared/providers/repository_providers.dart';

class DashboardStats {
  final int totalOrders;
  final int pendingOrders;
  final int confirmedOrders;
  final int completedOrders;
  final int cancelledOrders;
  final List<Order> recentOrders;
  final bool isLoading;
  final String? error;

  const DashboardStats({
    this.totalOrders = 0,
    this.pendingOrders = 0,
    this.confirmedOrders = 0,
    this.completedOrders = 0,
    this.cancelledOrders = 0,
    this.recentOrders = const [],
    this.isLoading = true,
    this.error,
  });
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final orderRepo = ref.read(orderRepositoryProvider);

  try {
    final orders = await orderRepo.getOrdersWithItems();

    int pending = 0, confirmed = 0, completed = 0, cancelled = 0;
    for (final order in orders) {
      switch (order.status.toLowerCase()) {
        case 'pending':
          pending++;
          break;
        case 'confirmed':
          confirmed++;
          break;
        case 'completed':
          completed++;
          break;
        case 'cancelled':
          cancelled++;
          break;
      }
    }

    final recent = orders.length > 10 ? orders.sublist(0, 10) : orders;

    return DashboardStats(
      totalOrders: orders.length,
      pendingOrders: pending,
      confirmedOrders: confirmed,
      completedOrders: completed,
      cancelledOrders: cancelled,
      recentOrders: recent,
      isLoading: false,
    );
  } catch (e) {
    return DashboardStats(
      isLoading: false,
      error: e.toString(),
    );
  }
});

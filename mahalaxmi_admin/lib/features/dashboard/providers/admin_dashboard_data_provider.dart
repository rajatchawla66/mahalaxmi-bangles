import 'package:riverpod/riverpod.dart';
import 'package:mahalaxmi_shared/models/item.dart';
import 'package:mahalaxmi_shared/models/order.dart';
import 'package:mahalaxmi_shared/models/customer.dart';
import 'package:mahalaxmi_shared/models/cutmail.dart';

import '../../catalogue/providers/admin_catalogue_provider.dart';
import '../../orders/providers/admin_orders_provider.dart';
import '../../customers/providers/admin_customers_provider.dart';
import '../../cutmail/providers/admin_cutmail_provider.dart';

class AdminDashboardData {
  final List<Order> orders;
  final List<CategoryWithStats> categoriesWithStats;
  final List<Customer> customers;
  final List<Cutmail> cutmails;
  final List<Cutmail> pendingCutmails;
  final List<RateItem> missingPriceItems;

  const AdminDashboardData({
    this.orders = const [],
    this.categoriesWithStats = const [],
    this.customers = const [],
    this.cutmails = const [],
    this.pendingCutmails = const [],
    this.missingPriceItems = const [],
  });

  int get totalOrders => orders.length;
  int get pendingOrders => orders.where((o) => o.status.toLowerCase() == 'pending').length;
  int get confirmedOrders => orders.where((o) => o.status.toLowerCase() == 'confirmed').length;
  int get completedOrders => orders.where((o) => o.status.toLowerCase() == 'completed').length;
  int get cancelledOrders => orders.where((o) => o.status.toLowerCase() == 'cancelled').length;
  List<Order> get recentOrders => orders.take(5).toList();

  int get totalItems {
    int count = 0;
    for (final cat in categoriesWithStats) {
      count += cat.totalItems;
    }
    return count;
  }

  int get availableItems {
    int count = 0;
    for (final cat in categoriesWithStats) {
      count += cat.availableItems;
    }
    return count;
  }

  int get totalCategories => categoriesWithStats.length;
  int get unavailableItems => totalItems - availableItems;

  int get totalCustomers => customers.length;
  int get activeCustomers => customers.where((c) => c.isActive).length;
  int get inactiveCustomers => customers.where((c) => !c.isActive).length;

  int get pendingCutmailCount => pendingCutmails.length;
  List<Cutmail> get latestCutmails => cutmails.take(5).toList();

  int get categoriesMissingCover =>
      categoriesWithStats.where((c) => c.category.coverImageUrl == null || c.category.coverImageUrl!.isEmpty).length;
}

final adminDashboardDataProvider = FutureProvider<AdminDashboardData>((ref) async {
  final ordersFuture = ref.read(adminAllOrdersProvider.future);
  final categoriesFuture = ref.read(adminCategoriesWithStatsProvider.future);
  final customersFuture = ref.read(adminCustomersProvider.future);
  final cutmailsFuture = ref.read(adminCutmailsProvider.future);
  final pendingCutmailsFuture = ref.read(adminCutmailsByStatusProvider('pending').future);
  final missingPriceFuture = ref.read(adminMissingPriceItemsProvider.future);

  final results = await Future.wait([
    ordersFuture,
    categoriesFuture,
    customersFuture,
    cutmailsFuture,
    pendingCutmailsFuture,
    missingPriceFuture,
  ]);

  return AdminDashboardData(
    orders: results[0] as List<Order>,
    categoriesWithStats: results[1] as List<CategoryWithStats>,
    customers: results[2] as List<Customer>,
    cutmails: results[3] as List<Cutmail>,
    pendingCutmails: results[4] as List<Cutmail>,
    missingPriceItems: results[5] as List<RateItem>,
  );
});

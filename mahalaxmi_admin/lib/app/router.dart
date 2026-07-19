import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mahalaxmi_shared/providers/session_provider.dart';

import '../features/auth/pages/login_page.dart';
import '../features/dashboard/pages/dashboard_page.dart';
import '../features/orders/pages/orders_page.dart';
import '../features/orders/pages/create_order_page.dart';
import '../features/orders/pages/order_detail_page.dart';
import '../features/catalogue/pages/catalogue_page.dart';
import '../features/catalogue/pages/category_items_page.dart';
import '../features/catalogue/pages/item_edit_page.dart';
import '../features/catalogue/pages/add_item_page.dart';
import '../features/catalogue/pages/missing_price_items_page.dart';
import '../features/customers/pages/customers_page.dart';
import '../features/customers/pages/customer_edit_page.dart';
import '../features/customers/pages/customer_create_page.dart';
import '../features/settings/pages/settings_page.dart';
import '../features/settings/pages/manage_tags_page.dart';
import '../features/settings/pages/manage_categories_page.dart';
import '../features/settings/pages/margin_settings_page.dart';
import '../features/settings/pages/material_master_page.dart';
import '../features/settings/pages/chuda_customization_page.dart';
import '../features/orders/pages/archive_orders_page.dart';
import '../features/cutmail/pages/cutmail_list_page.dart';
import '../features/cutmail/pages/cutmail_detail_page.dart';
import '../features/cost_calc/pages/cost_calculator_list_page.dart';
import '../features/cost_calc/pages/cost_calculator_form_page.dart';
import '../features/cost_calc/pages/trading_cost_form_page.dart';
import '../features/cost_calc/pages/bulk_trading_cost_page.dart';
import '../features/cost_calc/pages/category_records_page.dart';
import '../features/cost_calc/pages/material_settings_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'adminRoot');

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final session = ref.read(appSessionProvider);
      final isLoggedIn = session.isLoggedIn;
      final location = state.matchedLocation;

      if (isLoggedIn && (location == '/' || location == '/login')) {
        return '/dashboard';
      }
      if (!isLoggedIn && location != '/login') {
        return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/orders/create',
        name: 'orderCreate',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateOrderPage(),
      ),
      GoRoute(
        path: '/orders/:orderId',
        name: 'orderDetail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final orderId = int.tryParse(state.pathParameters['orderId'] ?? '') ?? 0;
          return OrderDetailPage(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/catalogue/add',
        name: 'addItem',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final category = state.uri.queryParameters['category'];
          return AddItemPage(initialCategory: category);
        },
      ),
      GoRoute(
        path: '/catalogue/missing-price',
        name: 'missingPriceItems',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MissingPriceItemsPage(),
      ),
      GoRoute(
        path: '/catalogue/:categoryName',
        name: 'categoryItems',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final name = Uri.decodeComponent(state.pathParameters['categoryName'] ?? '');
          return CategoryItemsPage(categoryName: name);
        },
      ),
      GoRoute(
        path: '/catalogue/:categoryName/edit/:itemNumber',
        name: 'itemEdit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final name = Uri.decodeComponent(state.pathParameters['categoryName'] ?? '');
          final itemNumber = Uri.decodeComponent(state.pathParameters['itemNumber'] ?? '');
          return ItemEditPage(categoryName: name, itemNumber: itemNumber);
        },
      ),
      GoRoute(
        path: '/customers',
        name: 'customers',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CustomersPage(),
      ),
      GoRoute(
        path: '/customers/create',
        name: 'customerCreate',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CustomerCreatePage(),
      ),
      GoRoute(
        path: '/customers/:customerId',
        name: 'customerEdit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['customerId'] ?? '') ?? 0;
          return CustomerEditPage(customerId: id);
        },
      ),
      GoRoute(
        path: '/settings/tags',
        name: 'settingsTags',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ManageTagsPage(),
      ),
      GoRoute(
        path: '/settings/categories',
        name: 'settingsCategories',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ManageCategoriesPage(),
      ),
      GoRoute(
        path: '/settings/margin',
        name: 'settingsMargin',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MarginSettingsPage(),
      ),
      GoRoute(
        path: '/settings/materials',
        name: 'settingsMaterials',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MaterialMasterPage(),
      ),
      GoRoute(
        path: '/settings/archive',
        name: 'settingsArchive',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ArchiveOrdersPage(),
      ),
      GoRoute(
        path: '/settings/chuda-customization',
        name: 'settingsChudaCustomization',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ChudaCustomizationPage(),
      ),
      GoRoute(
        path: '/cutmail',
        name: 'cutmailList',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CutmailListPage(),
      ),
      GoRoute(
        path: '/cutmail/:cutmailId',
        name: 'cutmailDetail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['cutmailId'] ?? '';
          return CutmailDetailPage(cutmailId: id);
        },
      ),
      GoRoute(
        path: '/cost-calc/create',
        name: 'costCalcCreate',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final category = state.uri.queryParameters['category'];
          final itemNumber = state.uri.queryParameters['itemNumber'];
          return CostCalculatorFormPage(
            initialItemName: '',
            initialCategory: category,
            initialItemNumber: itemNumber,
          );
        },
      ),
      GoRoute(
        path: '/cost-calc/create/trading',
        name: 'tradingCostCreate',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final category = state.uri.queryParameters['category'];
          final itemNumber = state.uri.queryParameters['itemNumber'];
          return TradingCostFormPage(
            initialCategory: category,
            initialItemNumber: itemNumber,
          );
        },
      ),
      GoRoute(
        path: '/cost-calc/bulk-trading',
        name: 'bulkTradingCost',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final category = state.uri.queryParameters['category'];
          return BulkTradingCostPage(initialCategory: category);
        },
      ),
      GoRoute(
        path: '/cost-calc/edit/:id',
        name: 'costCalcEdit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CostCalculatorFormPage(
            initialItemName: '',
            recordId: id,
          );
        },
      ),
      GoRoute(
        path: '/cost-calc/category/:categoryName',
        name: 'costCalcCategory',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final name = state.pathParameters['categoryName'] ?? '';
          return CategoryRecordsPage(categoryName: name);
        },
      ),
      GoRoute(
        path: '/cost-calc/settings',
        name: 'costCalcSettings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MaterialSettingsPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _AdminShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                name: 'dashboard',
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                name: 'orders',
                builder: (context, state) => const OrdersPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/catalogue',
                name: 'catalogue',
                builder: (context, state) => const CataloguePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cost-calc',
                name: 'costCalc',
                builder: (context, state) => const CostCalculatorListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.listen(appSessionProvider, (_, __) => router.refresh());

  return router;
});

class _AdminShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const _AdminShell({required this.navigationShell});

  @override
  State<_AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<_AdminShell> {
  late StatefulNavigationShell _navigationShell;

  @override
  void initState() {
    super.initState();
    _navigationShell = widget.navigationShell;
  }

  @override
  void didUpdateWidget(_AdminShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _navigationShell = widget.navigationShell;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _navigationShell.currentIndex;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (currentIndex > 0) {
          _navigationShell.goBranch(0);
        } else {
          showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Exit App'),
              content: const Text('Are you sure you want to exit?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Exit'),
                ),
              ],
            ),
          ).then((exit) {
            if (exit == true && context.mounted && !kIsWeb) {
              SystemNavigator.pop();
            }
          });
        }
      },
      child: Scaffold(
        body: _navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            _navigationShell.goBranch(
              index,
              initialLocation: index == _navigationShell.currentIndex,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Catalogue',
            ),
            NavigationDestination(
              icon: Icon(Icons.calculate_outlined),
              selectedIcon: Icon(Icons.calculate),
              label: 'Cost Calc',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

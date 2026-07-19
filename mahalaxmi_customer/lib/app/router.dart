import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mahalaxmi_shared/providers/session_provider.dart';

import '../features/auth/pages/login_page.dart';
import '../features/cart/pages/cart_page.dart';
import '../features/category/pages/category_page.dart';
import '../features/category/pages/item_detail_page.dart';
import '../features/dashboard/pages/dashboard_page.dart';
import '../features/orders/pages/my_orders_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'customerRoot');

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final session = ref.read(appSessionProvider);
      final isLoggedIn = session.isLoggedIn;
      final location = state.matchedLocation;

      if (location == '/') {
        return isLoggedIn ? '/dashboard' : '/login';
      }
      if (isLoggedIn && location == '/login') {
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
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/category/:categoryName',
        name: 'category',
        builder: (context, state) => CategoryPage(
          categoryName: state.pathParameters['categoryName'] ?? '',
        ),
      ),
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) => const CartPage(),
      ),
      GoRoute(
        path: '/my-orders',
        name: 'myOrders',
        builder: (context, state) => const MyOrdersPage(),
      ),
      GoRoute(
        path: '/item/:itemNumber',
        name: 'itemDetail',
        builder: (context, state) => ItemDetailPage(
          itemNumber: state.pathParameters['itemNumber'] ?? '',
        ),
      ),
    ],
  );

  ref.listen(appSessionProvider, (_, __) => router.refresh());

  return router;
});

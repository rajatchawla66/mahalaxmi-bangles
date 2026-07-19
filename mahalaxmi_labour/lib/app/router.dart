import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mahalaxmi_shared/providers/session_provider.dart';

import '../features/auth/pages/login_page.dart';
import '../features/dashboard/pages/dashboard_page.dart';
import '../features/orders/pages/create_order_page.dart';
import '../features/orders/pages/order_detail_page.dart';
import '../features/cutmail/pages/add_cutmail_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'labourRoot');

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
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardPage(),
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
        path: '/cutmail/add',
        name: 'addCutmail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddCutmailPage(),
      ),
    ],
  );

  ref.listen(appSessionProvider, (_, __) => router.refresh());
  return router;
});

class LabourShell extends StatefulWidget {
  final Widget child;

  const LabourShell({super.key, required this.child});

  @override
  State<LabourShell> createState() => _LabourShellState();
}

class _LabourShellState extends State<LabourShell> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
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
          if (exit == true && context.mounted) {
            SystemNavigator.pop();
          }
        });
      },
      child: widget.child,
    );
  }
}

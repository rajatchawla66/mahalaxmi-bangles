import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mahalaxmi_shared/models/app_session.dart';
import 'package:mahalaxmi_shared/models/cart_state.dart';
import 'package:mahalaxmi_shared/providers/cart_provider.dart';
import 'package:mahalaxmi_shared/providers/customer_auth_provider.dart';
import 'package:mahalaxmi_shared/providers/session_provider.dart';
import 'package:mahalaxmi_shared/services/cart_persistence_service.dart';

import 'router.dart';
import 'theme.dart';

class MahalaxmiCustomerApp extends ConsumerStatefulWidget {
  const MahalaxmiCustomerApp({super.key});

  @override
  ConsumerState<MahalaxmiCustomerApp> createState() => _MahalaxmiCustomerAppState();
}

class _MahalaxmiCustomerAppState extends ConsumerState<MahalaxmiCustomerApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(customerAuthControllerProvider).validateActiveSession().then((valid) {
        if (!valid) {
          ref.read(forcedLogoutReasonProvider.notifier).state = 'disabled';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(cartProvider, (CartState? prev, CartState next) {
      final session = ref.read(appSessionProvider);
      if (session.customerId != null) {
        unawaited(CartPersistenceService.save(session.customerId!, next));
      }
    });

    ref.listen(appSessionProvider, (AppSession? prev, AppSession next) {
      final prevId = prev?.customerId;
      final nextId = next.customerId;
      if (prevId != nextId) {
        if (prevId != null) {
          unawaited(CartPersistenceService.save(prevId, ref.read(cartProvider)));
        }
        if (nextId != null) {
          CartPersistenceService.load(nextId).then((items) {
            if (items != null) {
              ref.read(cartProvider.notifier).restoreFrom(items);
            } else if (prevId != null && prevId != nextId) {
              ref.read(cartProvider.notifier).restoreFrom([]);
            }
          });
        }
      }
    });

    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Mahalaxmi Customer',
      theme: customerTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

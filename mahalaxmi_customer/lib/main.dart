import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'package:mahalaxmi_shared/providers/cart_provider.dart';
import 'package:mahalaxmi_shared/providers/customer_auth_provider.dart';
import 'package:mahalaxmi_shared/providers/session_provider.dart';
import 'package:mahalaxmi_shared/services/cart_persistence_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    runApp(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Missing Supabase configuration.\n'
              'Build with --dart-define-from-file=.env',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      ),
    ));
    return;
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  final container = ProviderContainer();
  await container.read(appSessionProvider.notifier).restore();

  final session = container.read(appSessionProvider);
  if (session.isCustomer && session.customerId != null) {
    final saved = await CartPersistenceService.load(session.customerId!);
    if (saved != null && saved.isNotEmpty) {
      container.read(cartProvider.notifier).restoreFrom(saved);
    }
  }

  final valid = await container.read(customerAuthControllerProvider).validateActiveSession();
  if (!valid) {
    container.read(forcedLogoutReasonProvider.notifier).state = 'disabled';
  }

  runApp(UncontrolledProviderScope(
    container: container,
    child: const MahalaxmiCustomerApp(),
  ));
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class MahalaxmiAdminApp extends ConsumerWidget {
  const MahalaxmiAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Mahalaxmi Admin',
      theme: adminTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

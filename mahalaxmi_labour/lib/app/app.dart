import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class MahalaxmiLabourApp extends ConsumerWidget {
  const MahalaxmiLabourApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Mahalaxmi Labour',
      theme: labourTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

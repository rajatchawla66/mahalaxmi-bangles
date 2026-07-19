import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';

class LandingPage extends ConsumerWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Image.asset('assets/watermark.png'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mahalaxmi Bangles',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: kDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Wholesale Bridal Chuda Manufacturer',
                  style: TextStyle(fontSize: 12, color: kMuted),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 1,
                  color: kGold.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Customer Login'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Admin / Staff Login',
                    style: TextStyle(color: kMuted, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mahalaxmi_shared/models/category.dart';
import 'package:mahalaxmi_shared/providers/categories_provider.dart';
import 'package:mahalaxmi_shared/providers/cart_provider.dart';
import 'package:mahalaxmi_shared/providers/customer_auth_provider.dart';
import 'package:mahalaxmi_shared/providers/session_provider.dart';

import '../../../app/theme.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _recordingAccess = false;

  @override
  void initState() {
    super.initState();
    _recordAccess();
  }

  Future<void> _recordAccess() async {
    if (_recordingAccess) return;
    _recordingAccess = true;
    final session = ref.read(appSessionProvider);
    if (session.customerId != null) {
      await ref
          .read(customerAccessServiceProvider)
          .recordCatalogueAccess(session.customerId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(appSessionProvider);
    final categoriesAsync = ref.watch(activeCategoriesProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Exit app?'),
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
              if (kIsWeb) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You can close this browser tab.')),
                );
              } else {
                SystemNavigator.pop();
              }
            }
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(session.customerShopName ?? 'Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          Consumer(
            builder: (_, ref, __) {
              final count = ref.watch(cartItemCountProvider);
              return IconButton(
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count', style: const TextStyle(fontSize: 10, color: Colors.white)),
                  child: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                ),
                onPressed: () => context.push('/cart'),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'myOrders') {
                context.push('/my-orders');
              } else if (value == 'logout') {
                ref.read(appSessionProvider.notifier).logout();
                context.go('/');
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'myOrders',
                child: ListTile(
                  leading: Icon(Icons.receipt_long, color: kMaroon),
                  title: Text('My Orders'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: kMaroon),
                  title: Text('Logout'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) => categories.isEmpty
            ? const Center(
                child: Text(
                  'No categories available',
                  style: TextStyle(fontSize: 14, color: kMuted),
                ),
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(activeCategoriesProvider.future),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) =>
                        _CategoryCard(category: categories[index]),
                  ),
                ),
              ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: kMaroon),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: kMuted),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load categories',
                  style: TextStyle(fontSize: 14, color: kMuted),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(activeCategoriesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  final Category category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push(
        '/category/${Uri.encodeComponent(category.name)}',
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              category.coverImageUrl != null &&
                      category.coverImageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: category.coverImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _cardGradient(category.name),
                      errorWidget: (context, url, error) => _cardGradient(category.name),
                    )
                  : _cardGradient(category.name),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Text(
                  category.name.replaceAll('_', ' '),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardGradient(String name) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kMaroon.withValues(alpha: 0.7),
            kMaroon.withValues(alpha: 0.85),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w300,
          color: Colors.white,
        ),
      ),
    );
  }
}

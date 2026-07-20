import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mahalaxmi_shared/services/ledger_service.dart';
import 'package:mahalaxmi_shared/providers/ledger_providers.dart';

void _showAddOptions(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Single Record'),
            subtitle: const Text('Add one vendor price record'),
            onTap: () {
              Navigator.pop(ctx);
              context.push('/cost-calc/ledger/add');
            },
          ),
          ListTile(
            leading: const Icon(Icons.post_add_outlined),
            title: const Text('Bulk Entry'),
            subtitle: const Text('Add multiple vendor prices at once'),
            onTap: () {
              Navigator.pop(ctx);
              context.push('/cost-calc/ledger/bulk-add');
            },
          ),
        ],
      ),
    ),
  );
}

class LedgerPage extends ConsumerWidget {
  const LedgerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ledger'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Category'),
              Tab(text: 'Vendor'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddOptions(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Record'),
        ),
        body: const TabBarView(
          children: [
            _CategoryTab(),
            _VendorTab(),
          ],
        ),
      ),
    );
  }
}

class _CategoryTab extends ConsumerWidget {
  const _CategoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(ledgerCategoriesProvider);
    final theme = Theme.of(context);

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text('Could not load categories',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('$err',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.refresh(ledgerCategoriesProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (categories) {
        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.book_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text('No categories found',
                    style: theme.textTheme.titleMedium),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(ledgerCategoriesProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  title: Text(category,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                      '/cost-calc/ledger/category/${Uri.encodeComponent(category)}'),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _VendorTab extends ConsumerWidget {
  const _VendorTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorsAsync = ref.watch(ledgerVendorsProvider);
    final theme = Theme.of(context);

    return vendorsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text('Could not load vendors',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('$err',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.refresh(ledgerVendorsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (vendors) {
        final allVendors = [...vendors];
        if (!allVendors.contains('No Vendor')) {
          allVendors.add('No Vendor');
        }

        if (allVendors.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.book_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text('No vendors found',
                    style: theme.textTheme.titleMedium),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(ledgerVendorsProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: allVendors.length,
            itemBuilder: (context, index) {
              final vendor = allVendors[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  title: Text(vendor,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                      '/cost-calc/ledger/vendor/${Uri.encodeComponent(vendor)}'),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

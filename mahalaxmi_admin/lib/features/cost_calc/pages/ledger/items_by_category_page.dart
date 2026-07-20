import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahalaxmi_shared/providers/ledger_providers.dart';

import 'item_ledger_detail_page.dart';
import 'vendor_price_form_page.dart';

class ItemsByCategoryPage extends ConsumerWidget {
  final String categoryName;

  const ItemsByCategoryPage({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(ledgerItemsByCategoryProvider(categoryName));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(categoryName)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const VendorPriceFormPage()),
        ),
        child: const Icon(Icons.add),
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text('Could not load items',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('$err',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      ref.refresh(ledgerItemsByCategoryProvider(categoryName)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No items in this category',
                      style: theme.textTheme.titleMedium),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final marginStr = item.marginPct.toStringAsFixed(0);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ItemLedgerDetailPage(
                        source: item.source,
                        id: item.id,
                        name: item.name,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(
                                item.vendor.isNotEmpty
                                    ? 'Vendor: ${item.vendor}'
                                    : 'Vendor: —',
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${item.costPrice.toStringAsFixed(0)} → ₹${item.sellingPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            Text('$marginStr%',
                                style: TextStyle(
                                  color: item.marginPct >= 0
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

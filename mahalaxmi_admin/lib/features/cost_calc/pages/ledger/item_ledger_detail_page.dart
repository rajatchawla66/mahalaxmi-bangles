import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahalaxmi_shared/providers/ledger_providers.dart';

class ItemLedgerDetailPage extends ConsumerWidget {
  final String source;
  final String id;
  final String name;

  const ItemLedgerDetailPage({
    super.key,
    required this.source,
    required this.id,
    required this.name,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allItemsAsync = ref.watch(allLedgerItemsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: allItemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Error: $err'),
        ),
        data: (allItems) {
          final item = allItems.where((i) => i.id == id).firstOrNull;
          if (item == null) {
            return const Center(child: Text('Item not found'));
          }

          final marginStr = item.marginPct.toStringAsFixed(1);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      item.imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.image, size: 48,
                              color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailRow(label: 'Name', value: item.name),
                        if (item.itemNumber != null)
                          _DetailRow(
                              label: 'Item #', value: item.itemNumber!),
                        if (item.category != null)
                          _DetailRow(
                              label: 'Category', value: item.category!),
                        _DetailRow(
                            label: 'Vendor',
                            value: item.vendor.isNotEmpty
                                ? item.vendor
                                : '—'),
                        const Divider(height: 24),
                        _DetailRow(
                            label: 'Cost Price',
                            value:
                                '₹${item.costPrice.toStringAsFixed(2)}'),
                        _DetailRow(
                            label: 'Selling Price',
                            value:
                                '₹${item.sellingPrice.toStringAsFixed(2)}'),
                        _DetailRow(
                          label: 'Margin',
                          value: '$marginStr%',
                          valueColor: item.marginPct >= 0
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                        if (item.notes != null && item.notes!.isNotEmpty)
                          _DetailRow(label: 'Notes', value: item.notes!),
                        const Divider(height: 24),
                        _DetailRow(
                            label: 'Source',
                            value: item.source == 'rate_list'
                                ? 'Catalogue'
                                : 'One-off Record'),
                      ],
                    ),
                  ),
                ),
                if (item.source == 'rate_list')
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.calculate),
                        label: const Text('View Cost Calculation'),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

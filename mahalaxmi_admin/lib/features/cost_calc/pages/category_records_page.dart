import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/cost_calculations_provider.dart';
import '../widgets/costing_method_dialog.dart';

Color _colorForCategory(String categoryName) {
  switch (categoryName) {
    case 'Chuda':
      return const Color(0xFFE91E63);
    case 'Kaleera':
      return const Color(0xFFFF9800);
    case 'Raw_Material':
      return const Color(0xFF4CAF50);
    case 'Metal_Bangles':
      return const Color(0xFF607D8B);
    case 'Seasonal':
      return const Color(0xFF2196F3);
    case 'Seep Chuda':
      return const Color(0xFF9C27B0);
    default:
      return const Color(0xFF757575);
  }
}

class CategoryRecordsPage extends ConsumerWidget {
  final String categoryName;

  const CategoryRecordsPage({super.key, required this.categoryName});

  String get _displayName {
    if (categoryName == 'uncategorised') return 'Uncategorised';
    try {
      return Uri.decodeComponent(categoryName);
    } catch (_) {
      return categoryName;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(costCalculationsProvider);
    final theme = Theme.of(context);
    final catColor = _colorForCategory(_displayName);

    final filterCategory =
        categoryName == 'uncategorised' ? '' : Uri.decodeComponent(categoryName);

    return Scaffold(
      appBar: AppBar(
        title: Text(_displayName),
      ),
      body: recordsAsync.when(
        data: (records) {
          final filtered = records.where((r) {
            if (filterCategory.isEmpty) return r.category.isEmpty;
            return r.category == filterCategory;
          }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calculate_outlined,
                      size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('No items in this category',
                      style: theme.textTheme.bodyLarge),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final record = filtered[index];
              final isLinked = record.itemNumber != null && record.itemNumber!.isNotEmpty;
              final materialCount = record.materials.length;

              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                clipBehavior: Clip.antiAlias,
                shape: isLinked
                    ? RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                            width: 1),
                      )
                    : null,
                child: InkWell(
                  onTap: () => context.push('/cost-calc/edit/${record.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.calculate,
                              color: catColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(record.itemName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                  ),
                                  _badge(
                                isLinked ? Icons.link : Icons.link_off,
                                isLinked ? 'Linked' : 'Standalone',
                                isLinked
                                    ? const Color(0xFF1565C0)
                                    : Colors.orange,
                              ),
                              if (record.costingType == 'trading') ...[
                                const SizedBox(width: 4),
                                _badge(
                                  Icons.swap_horiz,
                                  'Trading',
                                  const Color(0xFF2196F3),
                                ),
                              ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              if (isLinked)
                                Text(record.itemNumber!,
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    '\u20B9${record.totalCost.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  if (materialCount > 0) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '$materialCount material${materialCount == 1 ? '' : 's'}',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey),
                                      ),
                                    ),
                                  ],
                                  if (record.createdAt != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDate(record.createdAt!),
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.grey),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  context.push(
                                      '/cost-calc/edit/${record.id}');
                                } else if (value == 'delete') {
                                  final confirm =
                                      await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title:
                                          const Text('Delete Record'),
                                      content: Text(
                                          'Delete "${record.itemName}"?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx)
                                                  .pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx)
                                                  .pop(true),
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                theme.colorScheme.error,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    try {
                                      await ref
                                          .read(
                                              costCalculationsRepositoryProvider)
                                          .delete(record.id!);
                                      if (context.mounted) {
                                        ref.invalidate(
                                            costCalculationsProvider);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Record deleted')),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Delete failed: $e')),
                                        );
                                      }
                                    }
                                  }
                                }
                              },
                              icon: const Icon(Icons.more_vert,
                                  size: 20),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit')),
                                const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete')),
                              ],
                            ),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off,
                    size: 64, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text('Failed to load records',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.error)),
                const SizedBox(height: 8),
                Text(e.toString(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final method = await showCostingMethodDialog(context);
          if (method == null) return;
          final categoryParam =
              filterCategory.isNotEmpty ? filterCategory : null;
          final query = categoryParam != null
              ? '?category=${Uri.encodeComponent(categoryParam)}'
              : '';
          if (!context.mounted) return;
          if (method == 'trading') {
            await context.push('/cost-calc/create/trading$query');
          } else {
            await context.push('/cost-calc/create$query');
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _badge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

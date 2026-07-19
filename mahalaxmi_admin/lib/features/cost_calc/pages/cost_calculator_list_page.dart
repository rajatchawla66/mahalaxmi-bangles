import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mahalaxmi_shared/models/category.dart';
import 'package:mahalaxmi_shared/providers/categories_provider.dart';

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

class CostCalculatorListPage extends ConsumerWidget {
  const CostCalculatorListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(activeCategoriesProvider);
    final recordsAsync = ref.watch(costCalculationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cost Calc'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            tooltip: 'Bulk Trading',
            onPressed: () => context.push('/cost-calc/bulk-trading'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(costCalculationsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Material Prices',
            onPressed: () => context.push('/cost-calc/settings'),
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          return recordsAsync.when(
            data: (records) {
              final counts = <String, int>{};
              final linkedCounts = <String, int>{};
              var uncategorised = 0;
              var uncategorisedLinked = 0;
              for (final r in records) {
                final isLinked =
                    r.itemNumber != null && r.itemNumber!.isNotEmpty;
                if (r.category.isEmpty) {
                  uncategorised++;
                  if (isLinked) uncategorisedLinked++;
                } else {
                  counts[r.category] = (counts[r.category] ?? 0) + 1;
                  if (isLinked) {
                    linkedCounts[r.category] =
                        (linkedCounts[r.category] ?? 0) + 1;
                  }
                }
              }
              return _buildList(context, ref, theme, categories, counts,
                  linkedCounts, uncategorised, uncategorisedLinked);
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
                Text('Failed to load categories',
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
          if (method == 'trading') {
            if (!context.mounted) return;
            await context.push('/cost-calc/create/trading');
          } else {
            if (!context.mounted) return;
            await context.push('/cost-calc/create');
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    List<Category> categories,
    Map<String, int> counts,
    Map<String, int> linkedCounts,
    int uncategorised,
    int uncategorisedLinked,
  ) {
    final items = <_CategoryItem>[];
    for (final cat in categories) {
      final count = counts[cat.name] ?? 0;
      final linked = linkedCounts[cat.name] ?? 0;
      items.add(_CategoryItem(
        name: cat.name,
        count: count,
        linkedCount: linked,
        color: _colorForCategory(cat.name),
        icon: _iconForCategory(cat.name),
        isActive: cat.isActive,
        coverImageUrl: cat.coverImageUrl,
      ));
    }
    if (uncategorised > 0) {
      items.add(_CategoryItem(
        name: 'Uncategorised',
        count: uncategorised,
        linkedCount: uncategorisedLinked,
        color: const Color(0xFF9E9E9E),
        icon: Icons.help_outline,
        isActive: true,
      ));
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calculate_outlined,
                size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('No cost calculations yet',
                style: theme.textTheme.bodyLarge),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.refresh(costCalculationsProvider.future),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final catColor = item.color;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: item.count > 0
                  ? () {
                      final path = item.name == 'Uncategorised'
                          ? '/cost-calc/category/uncategorised'
                          : '/cost-calc/category/${Uri.encodeComponent(item.name)}';
                      context.push(path);
                    }
                  : null,
              child: Row(
                children: [
                    _categoryImage(item.coverImageUrl, catColor, item.icon),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.name.replaceAll('_', ' '),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16),
                                ),
                              ),
                              if (!item.isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.orange.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('Inactive',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.orange)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _countChip(
                                'Total',
                                '${item.count}',
                                item.count > 0
                                    ? theme.colorScheme.primary
                                    : Colors.grey,
                              ),
                              if (item.linkedCount > 0) ...[
                                const SizedBox(width: 8),
                                _countChip('Linked', '${item.linkedCount}',
                                    const Color(0xFF1565C0)),
                              ],
                              if (item.count == 0) ...[
                                const SizedBox(width: 8),
                                _countChip('Empty', '0', Colors.grey),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.chevron_right, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _categoryImage(String? url, Color color, IconData icon) {
    return Container(
      width: 54,
      height: 72,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: url != null && url.isNotEmpty
            ? Colors.grey.shade100
            : color.withValues(alpha: 0.12),
      ),
      child: url != null && url.isNotEmpty
          ? Image.network(url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(icon, color: color, size: 28))
          : Icon(icon, color: color, size: 28),
    );
  }

  Widget _countChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$label: $value',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w500, color: color)),
    );
  }
}

IconData _iconForCategory(String categoryName) {
  switch (categoryName) {
    case 'Chuda':
      return Icons.watch;
    case 'Kaleera':
      return Icons.auto_awesome;
    case 'Raw_Material':
      return Icons.inventory_2;
    case 'Metal_Bangles':
      return Icons.circle;
    case 'Seasonal':
      return Icons.ac_unit;
    case 'Seep Chuda':
      return Icons.face;
    default:
      return Icons.category;
  }
}

class _CategoryItem {
  final String name;
  final int count;
  final int linkedCount;
  final Color color;
  final IconData icon;
  final bool isActive;
  final String? coverImageUrl;

  const _CategoryItem({
    required this.name,
    required this.count,
    this.linkedCount = 0,
    required this.color,
    required this.icon,
    this.isActive = true,
    this.coverImageUrl,
  });
}

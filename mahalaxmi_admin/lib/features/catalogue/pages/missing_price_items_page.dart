import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mahalaxmi_shared/models/item.dart';
import '../providers/admin_catalogue_provider.dart';

enum _SortMode {
  itemNumberAsc,
  itemNumberDesc,
  costAsc,
  costDesc,
}

class MissingPriceItemsPage extends ConsumerStatefulWidget {
  const MissingPriceItemsPage({super.key});

  @override
  ConsumerState<MissingPriceItemsPage> createState() => _MissingPriceItemsPageState();
}

class _MissingPriceItemsPageState extends ConsumerState<MissingPriceItemsPage> {
  final _searchController = TextEditingController();
  _SortMode _sortMode = _SortMode.itemNumberAsc;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RateItem> _applyFilter(List<RateItem> items) {
    var result = List<RateItem>.from(items);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((i) {
        return i.itemNumber.toLowerCase().contains(q) ||
            i.category.toLowerCase().contains(q) ||
            (i.subCategory?.toLowerCase().contains(q) ?? false) ||
            i.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }

    switch (_sortMode) {
      case _SortMode.itemNumberAsc:
        result.sort((a, b) => a.itemNumber.compareTo(b.itemNumber));
      case _SortMode.itemNumberDesc:
        result.sort((a, b) => b.itemNumber.compareTo(a.itemNumber));
      case _SortMode.costAsc:
        result.sort((a, b) => a.costPrice.compareTo(b.costPrice));
      case _SortMode.costDesc:
        result.sort((a, b) => b.costPrice.compareTo(a.costPrice));
    }

    return result;
  }

  String _sortLabel(_SortMode mode) {
    switch (mode) {
      case _SortMode.itemNumberAsc: return 'Item ↑';
      case _SortMode.itemNumberDesc: return 'Item ↓';
      case _SortMode.costAsc: return 'Cost ↑';
      case _SortMode.costDesc: return 'Cost ↓';
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(adminMissingPriceItemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Price Not Available')),
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
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.refresh(adminMissingPriceItemsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          final filtered = _applyFilter(items);

          return Column(
            children: [
              // Search + sort bar
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search items or categories...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<_SortMode>(
                      initialValue: _sortMode,
                      icon: const Icon(Icons.sort, size: 20),
                      tooltip: 'Sort',
                      onSelected: (s) => setState(() => _sortMode = s),
                      itemBuilder: (_) => [
                        for (final mode in _SortMode.values)
                          PopupMenuItem(
                            value: mode,
                            child: Text(
                              _sortLabel(mode),
                              style: TextStyle(
                                fontWeight: _sortMode == mode ? FontWeight.w700 : FontWeight.normal,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Results
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty ? Icons.search_off : Icons.check_circle_outline,
                              size: 48, color: _searchQuery.isNotEmpty ? Colors.grey : Colors.green,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty 
                                  ? 'No items match your search' 
                                  : 'All items have selling prices fed!',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.refresh(adminMissingPriceItemsProvider.future),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return _MissingPriceItemCard(item: item);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MissingPriceItemCard extends StatelessWidget {
  final RateItem item;

  const _MissingPriceItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          '/catalogue/${Uri.encodeComponent(item.category)}/edit/${Uri.encodeComponent(item.itemNumber)}',
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              _buildImage(item.imageUrl),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(item.itemNumber,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'No Price',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Category: ${item.category.replaceAll('_', ' ')}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text('CP: ₹${item.costPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(0xFF1565C0),
                            )),
                      ],
                    ),
                    if (item.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(item.tags.join(', '),
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                            overflow: TextOverflow.ellipsis),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String? url) {
    if (url != null && url.isNotEmpty) {
      return Container(
        width: 56, height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade100,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback()),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: 56, height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF1565C0).withValues(alpha: 0.1),
      ),
      child: const Icon(Icons.image_outlined, color: Colors.grey, size: 24),
    );
  }
}

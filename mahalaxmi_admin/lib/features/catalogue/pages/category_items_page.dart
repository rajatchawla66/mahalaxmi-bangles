import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mahalaxmi_shared/models/item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/share_photo_service.dart';
import '../providers/admin_catalogue_provider.dart';
import '../../cost_calc/providers/cost_calculations_provider.dart';

enum _AvailabilityFilter { all, available, hidden }

enum _SortMode {
  recentlyAdded,
  oldestFirst,
  nameAsc,
  nameDesc,
  priceAsc,
  priceDesc,
}

class CategoryItemsPage extends ConsumerStatefulWidget {
  final String categoryName;

  const CategoryItemsPage({super.key, required this.categoryName});

  @override
  ConsumerState<CategoryItemsPage> createState() => _CategoryItemsPageState();
}

class _CategoryItemsPageState extends ConsumerState<CategoryItemsPage> {
  final _searchController = TextEditingController();
  _AvailabilityFilter _filter = _AvailabilityFilter.all;
  _SortMode _sortMode = _SortMode.recentlyAdded;
  String _searchQuery = '';
  bool _selectionMode = false;
  final Set<String> _selectedItemNumbers = {};
  bool _shareInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadSavedSort();
  }

  Future<void> _loadSavedSort() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('category_sort_mode');
    if (saved != null) {
      final parsed = _SortMode.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => _SortMode.recentlyAdded,
      );
      if (mounted) setState(() => _sortMode = parsed);
    }
  }

  Future<void> _saveSort(_SortMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('category_sort_mode', mode.name);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RateItem> _applyFilter(List<RateItem> items) {
    var result = List<RateItem>.from(items);

    if (_filter == _AvailabilityFilter.available) {
      result = result.where((i) => i.isAvailable).toList();
    } else if (_filter == _AvailabilityFilter.hidden) {
      result = result.where((i) => !i.isAvailable).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((i) {
        return i.itemNumber.toLowerCase().contains(q) ||
            (i.subCategory?.toLowerCase().contains(q) ?? false) ||
            i.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }

    switch (_sortMode) {
      case _SortMode.recentlyAdded:
        result.sort((a, b) {
          final aTime = a.createdAt ?? DateTime(2000);
          final bTime = b.createdAt ?? DateTime(2000);
          return bTime.compareTo(aTime);
        });
      case _SortMode.oldestFirst:
        result.sort((a, b) {
          final aTime = a.createdAt ?? DateTime(2000);
          final bTime = b.createdAt ?? DateTime(2000);
          return aTime.compareTo(bTime);
        });
      case _SortMode.nameAsc:
        result.sort((a, b) => a.itemNumber.compareTo(b.itemNumber));
      case _SortMode.nameDesc:
        result.sort((a, b) => b.itemNumber.compareTo(a.itemNumber));
      case _SortMode.priceAsc:
        result.sort((a, b) => a.sellingPrice.compareTo(b.sellingPrice));
      case _SortMode.priceDesc:
        result.sort((a, b) => b.sellingPrice.compareTo(a.sellingPrice));
    }

    return result;
  }

  List<PopupMenuEntry<_SortMode>> _buildSortSection(String title, List<_SortMode> modes) {
    return [
      PopupMenuItem<_SortMode>(
        enabled: false,
        height: 24,
        child: Text(title,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
      ),
      ...modes.map((mode) => PopupMenuItem(
            value: mode,
            child: Text(
              _sortLabel(mode),
              style: TextStyle(
                fontWeight: _sortMode == mode ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          )),
    ];
  }

  String _sortLabel(_SortMode mode) {
    switch (mode) {
      case _SortMode.recentlyAdded: return 'Recently Added';
      case _SortMode.oldestFirst: return 'Oldest First';
      case _SortMode.nameAsc: return 'Name (A–Z)';
      case _SortMode.nameDesc: return 'Name (Z–A)';
      case _SortMode.priceAsc: return 'Price (Low→High)';
      case _SortMode.priceDesc: return 'Price (High→Low)';
    }
  }

  void _toggleSelection(String itemNumber) {
    setState(() {
      if (_selectedItemNumbers.contains(itemNumber)) {
        _selectedItemNumbers.remove(itemNumber);
      } else {
        _selectedItemNumbers.add(itemNumber);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedItemNumbers.clear();
    });
  }

  Future<bool> _warnBeforeShare(List<RateItem> selectedItems) async {
    final zeroPrice = selectedItems.where((i) => i.sellingPrice <= 0).toList();
    final hidden = selectedItems.where((i) => !i.isAvailable).toList();

    if (zeroPrice.isEmpty && hidden.isEmpty) return true;

    final messages = <String>[];
    if (zeroPrice.isNotEmpty) {
      messages.add('${zeroPrice.length} item(s) have no price set. Price will show as "Price not set".');
    }
    if (hidden.isNotEmpty) {
      messages.add('${hidden.length} item(s) are marked as hidden/unavailable.');
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Share Photos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Some selected items have warnings:'),
            const SizedBox(height: 12),
            for (final msg in messages)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber, size: 18, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _sharePhotos() async {
    final allItems = await ref.read(adminCategoryItemsProvider(widget.categoryName).future);
    final selectedItems = allItems.where((i) => _selectedItemNumbers.contains(i.itemNumber)).toList();

    if (selectedItems.isEmpty) return;

    final proceed = await _warnBeforeShare(selectedItems);
    if (!proceed) return;
    if (!mounted) return;

    setState(() => _shareInProgress = true);

    final progressNotifier = ValueNotifier<int>(0);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Generating Photos'),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 16),
              ValueListenableBuilder<int>(
                valueListenable: progressNotifier,
                builder: (ctx, current, _) => Text(
                  'Preparing $current of ${selectedItems.length} photos...',
                ),
              ),
            ],
          ),
        );
      },
    );

    try {
      final result = await SharePhotoService.generate(
        items: selectedItems,
        onProgress: (current, total) {
          progressNotifier.value = current;
        },
      );

      if (!mounted) return;

      if (result.allSkipped) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate any photos. Check network connection.')),
        );
        setState(() => _shareInProgress = false);
        return;
      }

      Navigator.of(context).pop();

      if (result.skippedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generated ${result.successCount} of ${selectedItems.length} photos. Skipped: ${result.skippedItemNumbers.join(', ')}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }

      if (!mounted) return;

      // Share using platform-appropriate method
      final successfulItems = selectedItems
          .where((i) => !result.skippedItemNumbers.contains(i.itemNumber))
          .toList();
      final fileNames = successfulItems
          .map((item) => SharePhotoService.fileNameForItem(item))
          .toList();
      await SharePhotoService.shareBytes(
        bytesList: result.generatedBytes,
        fileNames: fileNames,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating photos: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _shareInProgress = false);
        _exitSelectionMode();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(adminCategoryItemsProvider(widget.categoryName));
    final displayName = widget.categoryName.replaceAll('_', ' ');

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectionMode ? '$displayName (Select)' : displayName),
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(
              _selectionMode ? Icons.checklist : Icons.checklist_outlined,
              color: _selectionMode ? Colors.amber : null,
            ),
            tooltip: _selectionMode ? 'Exit select mode' : 'Select photos to share',
            onPressed: () {
              setState(() {
                if (_selectionMode) {
                  _exitSelectionMode();
                } else {
                  _selectionMode = true;
                }
              });
            },
          ),
        ],
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
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.refresh(adminCategoryItemsProvider(widget.categoryName)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          final filtered = _applyFilter(items);
          final costedItems = ref.watch(costCalculatedItemNumbersProvider).valueOrNull ?? {};

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search items...',
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
                      icon: Icon(
                        Icons.sort,
                        size: 20,
                        color: _sortMode != _SortMode.recentlyAdded ? Colors.blue.shade700 : null,
                      ),
                      tooltip: 'Sort',
                      onSelected: (s) {
                        setState(() => _sortMode = s);
                        _saveSort(s);
                      },
                      itemBuilder: (_) => [
                        ..._buildSortSection('Date Added', [
                          _SortMode.recentlyAdded,
                          _SortMode.oldestFirst,
                        ]),
                        const PopupMenuDivider(),
                        ..._buildSortSection('Name', [
                          _SortMode.nameAsc,
                          _SortMode.nameDesc,
                        ]),
                        const PopupMenuDivider(),
                        ..._buildSortSection('Selling Price', [
                          _SortMode.priceAsc,
                          _SortMode.priceDesc,
                        ]),
                      ],
                    ),
                    PopupMenuButton<_AvailabilityFilter>(
                      initialValue: _filter,
                      icon: Icon(
                        _filter == _AvailabilityFilter.all ? Icons.filter_list : Icons.filter_alt,
                        size: 20,
                        color: _filter != _AvailabilityFilter.all ? Colors.blue.shade700 : null,
                      ),
                      tooltip: 'Filter by availability',
                      onSelected: (f) => setState(() => _filter = f),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: _AvailabilityFilter.all,
                          child: Text('All Items (${items.length})',
                              style: TextStyle(fontWeight: _filter == _AvailabilityFilter.all ? FontWeight.w700 : FontWeight.normal)),
                        ),
                        PopupMenuItem(
                          value: _AvailabilityFilter.available,
                          child: Row(
                            children: [
                              Icon(Icons.visibility, size: 18, color: Colors.green.shade600),
                              const SizedBox(width: 8),
                              Text('In Stock (${items.where((i) => i.isAvailable).length})',
                                  style: TextStyle(fontWeight: _filter == _AvailabilityFilter.available ? FontWeight.w700 : FontWeight.normal)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: _AvailabilityFilter.hidden,
                          child: Row(
                            children: [
                              Icon(Icons.visibility_off, size: 18, color: Colors.orange.shade700),
                              const SizedBox(width: 8),
                              Text('Hidden (${items.where((i) => !i.isAvailable).length})',
                                  style: TextStyle(fontWeight: _filter == _AvailabilityFilter.hidden ? FontWeight.w700 : FontWeight.normal)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty ? Icons.search_off : Icons.inventory_2_outlined,
                              size: 48, color: Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty ? 'No items match your search' : 'No items in this category',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                          onRefresh: () async {
                            await ref.refresh(adminCategoryItemsProvider(widget.categoryName).future);
                            ref.invalidate(costCalculatedItemNumbersProvider);
                          },
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final hasCostCalc = costedItems.contains(item.itemNumber);
                            return _ItemCard(
                              item: item,
                              categoryName: widget.categoryName,
                              selectionMode: _selectionMode,
                              isSelected: _selectedItemNumbers.contains(item.itemNumber),
                              onToggleSelection: _selectionMode ? () => _toggleSelection(item.itemNumber) : null,
                              hasCostCalc: hasCostCalc,
                            );
                          },
                        ),
                      ),
              ),
              if (_selectionMode) _buildBottomBar(items),
            ],
          );
        },
      ),
      floatingActionButton: _selectionMode
          ? null
          : FloatingActionButton(
              heroTag: 'category_add',
              onPressed: () => context.push('/catalogue/add?category=${Uri.encodeComponent(widget.categoryName)}'),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildBottomBar(List<RateItem> allItems) {
    final selectedCount = _selectedItemNumbers.length;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                '$selectedCount selected',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: () {
                  final visibleItems = _applyFilter(allItems);
                  setState(() {
                    if (_selectedItemNumbers.length == visibleItems.length) {
                      _selectedItemNumbers.clear();
                    } else {
                      _selectedItemNumbers.addAll(visibleItems.map((i) => i.itemNumber));
                    }
                  });
                },
                child: Text(
                  _selectedItemNumbers.length == _applyFilter(allItems).length ? 'Clear' : 'Select all',
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: selectedCount == 0 || _shareInProgress ? null : _sharePhotos,
                icon: _shareInProgress
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.share, size: 18),
                label: Text(_shareInProgress ? 'Generating...' : 'Share Photos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final RateItem item;
  final String categoryName;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback? onToggleSelection;
  final bool hasCostCalc;

  const _ItemCard({
    required this.item,
    required this.categoryName,
    this.selectionMode = false,
    this.isSelected = false,
    this.onToggleSelection,
    this.hasCostCalc = false,
  });

  @override
  Widget build(BuildContext context) {
    final loss = item.costPrice > 0 && item.sellingPrice > 0 && item.sellingPrice < item.costPrice;
    final margin = item.costPrice > 0
        ? ((item.sellingPrice - item.costPrice) / item.costPrice * 100)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      clipBehavior: Clip.antiAlias,
      shape: isSelected
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF1565C0), width: 2),
            )
          : null,
      child: InkWell(
        onTap: selectionMode ? onToggleSelection : () => context.push(
          '/catalogue/${Uri.encodeComponent(categoryName)}/edit/${Uri.encodeComponent(item.itemNumber)}',
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              if (selectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => onToggleSelection?.call(),
                  ),
                ),
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: !item.isAvailable
                                    ? Colors.red.withValues(alpha: 0.15)
                                    : item.sellingPrice == 0
                                        ? Colors.orange.withValues(alpha: 0.15)
                                        : const Color(0xFF2E7D32).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                !item.isAvailable
                                    ? 'Hidden'
                                    : item.sellingPrice == 0
                                        ? 'No Price'
                                        : 'Available',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: !item.isAvailable
                                      ? Colors.red
                                      : item.sellingPrice == 0
                                          ? Colors.orange
                                          : const Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                            if (hasCostCalc) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.calculate, size: 11, color: Color(0xFF1565C0)),
                                    SizedBox(width: 2),
                                    Text('Costed',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1565C0),
                                        )),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (item.subCategory != null && item.subCategory!.isNotEmpty)
                      Text(item.subCategory!.replaceAll('_', ' '),
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text('\u20b9${item.sellingPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: loss ? Colors.red : const Color(0xFF1565C0),
                            )),
                        if (item.costPrice > 0) ...[
                          const SizedBox(width: 6),
                          Text('CP: \u20b9${item.costPrice.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                        if (margin > 0 && item.sellingPrice > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('${margin.toStringAsFixed(0)}%',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
                          ),
                        ],
                        if (loss) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('LOSS',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.red)),
                          ),
                        ],
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
              if (!selectionMode)
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

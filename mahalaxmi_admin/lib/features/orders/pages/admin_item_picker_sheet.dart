import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahalaxmi_shared/mahalaxmi_shared.dart';

class AdminItemPickerSheet extends ConsumerStatefulWidget {
  const AdminItemPickerSheet({super.key});

  @override
  ConsumerState<AdminItemPickerSheet> createState() => _AdminItemPickerSheetState();
}

class _AdminItemPickerSheetState extends ConsumerState<AdminItemPickerSheet> {
  List<Category>? _categories;
  List<RateItem>? _allItems;
  List<RateItem>? _displayItems;
  String? _selectedCategory;
  bool _loadingCats = true;
  bool _loadingItems = false;
  bool _showUnavailable = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCats = true);
    try {
      final cats = await ref.read(categoryRepositoryProvider).getCategories(activeOnly: false);
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _loadingCats = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCats = false);
    }
  }

  Future<void> _loadItems(String categoryName) async {
    setState(() {
      _selectedCategory = categoryName;
      _loadingItems = true;
      _searchCtrl.clear();
    });
    try {
      final allItems = await ref.read(itemRepositoryProvider).getAllItems();
      if (!mounted) return;
      final filtered = allItems.where((i) => i.category == categoryName).toList();
      setState(() {
        _allItems = filtered;
        _displayItems = filtered;
        _loadingItems = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingItems = false);
    }
  }

  void _applyFilter() {
    if (_allItems == null) return;
    final query = _searchCtrl.text.trim().toLowerCase();
    var items = _allItems!;

    if (!_showUnavailable) {
      items = items.where((i) => i.isAvailable && i.sellingPrice > 0).toList();
    }

    if (query.isNotEmpty) {
      items = items.where((i) =>
        i.itemNumber.toLowerCase().contains(query) ||
        (i.subCategory?.toLowerCase().contains(query) ?? false) ||
        i.tags.any((t) => t.toLowerCase().contains(query))
      ).toList();
    }

    setState(() => _displayItems = items);
  }

  Future<void> _showItemForm(RateItem item) async {
    if (!item.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This item is unavailable and cannot be added'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final isChuda = item.category.trim().toLowerCase() == 'chuda';

    List<ChudaCustomizationOption> pattiOpts = [];
    List<ChudaCustomizationOption> colorOpts = [];
    List<ChudaCustomizationOption> boxOpts = [];
    ChudaCustomizationOption? defaultPatti;
    ChudaCustomizationOption? defaultColor;
    ChudaCustomizationOption? defaultBox;

    if (isChuda) {
      try {
        final all = await ref.read(chudaCustomizationRepositoryProvider).getActiveOptions();
        pattiOpts = all.where((o) => o.groupType == 'patti').toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        colorOpts = all.where((o) => o.groupType == 'color').toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        boxOpts = all.where((o) => o.groupType == 'box').toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        defaultPatti = pattiOpts.isEmpty ? null
            : (pattiOpts.firstWhere((o) => o.isDefault, orElse: () => pattiOpts.first));
        defaultColor = colorOpts.isEmpty ? null
            : (colorOpts.firstWhere((o) => o.isDefault, orElse: () => colorOpts.first));
        defaultBox = boxOpts.isEmpty ? null
            : (boxOpts.firstWhere((o) => o.isDefault, orElse: () => boxOpts.first));
      } catch (_) {}
    }

    if (!mounted) return;

    final qtyCtrl = TextEditingController();
    final colorCtrl = TextEditingController(text: '');
    int size22 = 0, size24 = 0, size26 = 0, size28 = 0, size210 = 0, size212 = 0;
    var selPatti = defaultPatti;
    var selColor = defaultColor;
    var selBox = defaultBox;
    var customColorText = '';

    double customTotal() => ((selPatti?.priceDifference ?? 0) +
            (selColor?.priceDifference ?? 0) + (selBox?.priceDifference ?? 0))
        .toDouble();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final total = customTotal();
          final finalPrice = item.sellingPrice + total;

          return AlertDialog(
            title: Text(item.itemNumber, style: const TextStyle(fontSize: 16)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('₹${item.sellingPrice.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1565C0))),
                      if (total > 0) ...[
                        const SizedBox(width: 8),
                        Text('+ ₹${total.toStringAsFixed(0)} = ₹${finalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                      const Spacer(),
                      if (item.isAvailable && item.sellingPrice <= 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                          child: const Text('NO PRICE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.orange)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (item.hasSizes) ...[
                    const Text('Sizes:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    _sizeField('2.2', size22, (v) => setDialogState(() => size22 = v)),
                    _sizeField('2.4', size24, (v) => setDialogState(() => size24 = v)),
                    _sizeField('2.6', size26, (v) => setDialogState(() => size26 = v)),
                    _sizeField('2.8', size28, (v) => setDialogState(() => size28 = v)),
                    _sizeField('2.10', size210, (v) => setDialogState(() => size210 = v)),
                    _sizeField('2.12', size212, (v) => setDialogState(() => size212 = v)),
                  ] else ...[
                    TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],

                  if (item.hasColor && !isChuda) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: colorCtrl,
                      decoration: InputDecoration(
                        labelText: 'Color',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],

                  if (isChuda) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    const Text('Chooda Customisation',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF800020))),
                    const SizedBox(height: 8),
                    if (pattiOpts.isEmpty && colorOpts.isEmpty && boxOpts.isEmpty)
                      const Text('No customisation options available. Please configure in Settings.',
                          style: TextStyle(fontSize: 12, color: Colors.red)),
                    if (pattiOpts.isNotEmpty) ...[
                      const Text('Patti', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      _buildChudaChips(pattiOpts, selPatti, (v) => setDialogState(() => selPatti = v)),
                    ],
                    if (colorOpts.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text('Patti Color', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      _buildChudaChips(colorOpts, selColor, (v) => setDialogState(() { selColor = v; if (v?.name != 'Custom') customColorText = ''; })),
                      if (selColor?.name == 'Custom') ...[
                        const SizedBox(height: 6),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Enter custom patti color',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            isDense: true,
                          ),
                          onChanged: (v) => customColorText = v,
                        ),
                      ],
                    ],
                    if (boxOpts.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text('Box', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      _buildChudaChips(boxOpts, selBox, (v) => setDialogState(() => selBox = v)),
                    ],
                    if (total > 0) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Text('Final price: ',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            Text('₹${finalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1565C0))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  if (isChuda && (selPatti == null || selColor == null || selBox == null)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Select all customisation options'), behavior: SnackBarBehavior.floating),
                    );
                    return;
                  }
                  if (selColor?.name == 'Custom' && customColorText.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter custom patti color text'), behavior: SnackBarBehavior.floating),
                    );
                    return;
                  }

                  ChudaCustomizationSnapshot? customization;
                  double unitPrice = item.sellingPrice;

                  if (isChuda) {
                    final pattiDiff = (selPatti?.priceDifference ?? 0).toDouble();
                    final colorDiff = (selColor?.priceDifference ?? 0).toDouble();
                    final boxDiff = (selBox?.priceDifference ?? 0).toDouble();
                    customization = ChudaCustomizationSnapshot(
                      pattiName: selPatti!.name,
                      pattiPriceDiff: pattiDiff,
                      colorName: selColor!.name,
                      colorPriceDiff: colorDiff,
                      customColorText: selColor!.name == 'Custom' ? customColorText.trim() : null,
                      boxName: selBox!.name,
                      boxPriceDiff: boxDiff,
                      totalDifference: pattiDiff + colorDiff + boxDiff,
                    );
                    unitPrice = item.sellingPrice + (pattiDiff + colorDiff + boxDiff);
                  }

                  final cartItem = CartItem(
                    itemNumber: item.itemNumber,
                    category: item.category,
                    hasSizes: item.hasSizes,
                    hasColor: item.hasColor,
                    qty22: size22,
                    qty24: size24,
                    qty26: size26,
                    qty28: size28,
                    qty210: size210,
                    qty212: size212,
                    quantity: double.tryParse(qtyCtrl.text.trim()) ?? 1,
                    color: isChuda ? null : (colorCtrl.text.trim().isEmpty ? null : colorCtrl.text.trim()),
                    unitPrice: unitPrice,
                    customization: customization,
                  );
                  Navigator.pop(ctx);
                  Navigator.pop(context, cartItem);
                },
                child: const Text('Add to Order'),
              ),
            ],
          );
        },
      ),
    );
    qtyCtrl.dispose();
    colorCtrl.dispose();
  }

  Widget _buildChudaChips(
    List<ChudaCustomizationOption> options,
    ChudaCustomizationOption? selected,
    ValueChanged<ChudaCustomizationOption?> onSelected,
  ) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: options.map((opt) {
        final isSel = selected?.id == opt.id;
        String label = opt.name;
        if (opt.priceDifference > 0) {
          label += ' (+₹${opt.priceDifference.toStringAsFixed(0)})';
        } else if (opt.priceDifference < 0) {
          label += ' (-₹${opt.priceDifference.abs().toStringAsFixed(0)})';
        }
        return ChoiceChip(
          label: Text(label, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : null)),
          selected: isSel,
          selectedColor: const Color(0xFF800020),
          onSelected: (v) => onSelected(v ? opt : null),
        );
      }).toList(),
    );
  }

  Widget _sizeField(String label, int value, void Function(int) onChanged) {
    return Row(
      children: [
        SizedBox(width: 40, child: Text(label, style: const TextStyle(fontSize: 13))),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        SizedBox(width: 36, child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 20),
          onPressed: () => onChanged(value + 1),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isInsideCategory = _selectedCategory != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text(
                    isInsideCategory ? 'Select Item' : 'Select Category',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            if (isInsideCategory)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextButton.icon(
                  onPressed: () => setState(() { _selectedCategory = null; _allItems = null; _displayItems = null; _searchCtrl.clear(); }),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: Text(_selectedCategory!.replaceAll('_', ' ')),
                ),
              ),

            if (isInsideCategory) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () { _searchCtrl.clear(); _applyFilter(); },
                          )
                        : null,
                  ),
                  onChanged: (_) => _applyFilter(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Text('Show unavailable', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    Switch(
                      value: _showUnavailable,
                      onChanged: (v) { setState(() => _showUnavailable = v); _applyFilter(); },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
            ],

            Expanded(
              child: _loadingCats || _loadingItems
                  ? const Center(child: CircularProgressIndicator())
                  : !isInsideCategory
                      ? _buildCategoryGrid(scrollController)
                      : _buildItemsList(scrollController),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryGrid(ScrollController scrollController) {
    final cats = _categories ?? [];
    if (cats.isEmpty) {
      return const Center(child: Text('No categories', style: TextStyle(color: Colors.grey)));
    }
    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.85,
      ),
      itemCount: cats.length,
      itemBuilder: (context, index) {
        final cat = cats[index];
        final displayName = cat.name.replaceAll('_', ' ');
        return InkWell(
          onTap: () => _loadItems(cat.name),
          borderRadius: BorderRadius.circular(12),
          child: Card(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: cat.coverImageUrl != null && cat.coverImageUrl!.isNotEmpty
                      ? Image.network(cat.coverImageUrl!, width: 54, height: 72, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.category, size: 24, color: Colors.grey))
                      : const Icon(Icons.category, size: 24, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(displayName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemsList(ScrollController scrollController) {
    final items = _displayItems ?? [];
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text(_searchCtrl.text.isNotEmpty ? 'No items match your search' : 'No available items in this category',
                style: const TextStyle(color: Colors.grey)),
            if (!_showUnavailable) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () { setState(() => _showUnavailable = true); _applyFilter(); },
                child: const Text('Show unavailable items', style: TextStyle(fontSize: 12)),
              ),
            ],
          ],
        ),
      );
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: item.imageUrl.isNotEmpty
                  ? Image.network(item.imageUrl, width: 44, height: 55, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, size: 24, color: Colors.grey))
                  : const Icon(Icons.image_outlined, size: 24, color: Colors.grey),
            ),
            title: Row(
              children: [
                Expanded(child: Text(item.itemNumber, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                if (!item.isAvailable)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                    child: const Text('Hidden', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.red)),
                  ),
              ],
            ),
            subtitle: Row(
              children: [
                Text('₹${item.sellingPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1565C0))),
                if (item.sellingPrice <= 0) ...[
                  const SizedBox(width: 6),
                  const Text('(no price)', style: TextStyle(fontSize: 10, color: Colors.orange)),
                ],
              ],
            ),
            trailing: FilledButton.tonalIcon(
              onPressed: !item.isAvailable ? null : () => _showItemForm(item),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ),
        );
      },
    );
  }
}

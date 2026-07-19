import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mahalaxmi_shared/mahalaxmi_shared.dart';

import '../providers/labour_orders_provider.dart';

class CreateOrderPage extends ConsumerStatefulWidget {
  const CreateOrderPage({super.key});

  @override
  ConsumerState<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends ConsumerState<CreateOrderPage> {
  final _customerNameCtrl = TextEditingController();
  final _customerMobileCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final List<_LineItem> _lines = [];
  String? _error;
  bool _placing = false;

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerMobileCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openItemPicker() async {
    final result = await showModalBottomSheet<CartItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _LabourItemPickerSheet(),
    );

    if (result == null || !mounted) return;

    // Check for duplicate
    final existingIndex = _lines.indexWhere((l) =>
        l.item.itemNumber == result.itemNumber &&
        l.item.color == result.color);
    if (existingIndex >= 0) {
      final existing = _lines[existingIndex];
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Duplicate Item'),
          content: Text(
            '${result.itemNumber} already exists.\n'
            'Existing: ${_describeItem(existing.item)}\n'
            'New: ${_describeItem(result)}',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, 'separate'),
                child: const Text('Add Separate')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, 'cancel'),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, 'merge'),
                child: const Text('Merge')),
          ],
        ),
      );

      if (action == 'merge') {
        setState(() {
          final existingItem = _lines[existingIndex].item;
          if (result.hasSizes) {
            _lines[existingIndex] = _LineItem(existingItem.copyWith(
              qty22: existingItem.qty22 + result.qty22,
              qty24: existingItem.qty24 + result.qty24,
              qty26: existingItem.qty26 + result.qty26,
              qty28: existingItem.qty28 + result.qty28,
              qty210: existingItem.qty210 + result.qty210,
              qty212: existingItem.qty212 + result.qty212,
            ));
          } else {
            _lines[existingIndex] = _LineItem(existingItem.copyWith(
              quantity: existingItem.quantity + result.quantity,
            ));
          }
        });
      } else if (action == 'separate') {
        setState(() => _lines.add(_LineItem(result)));
      }
    } else {
      setState(() => _lines.add(_LineItem(result)));
    }
  }

  String _describeItem(CartItem item) {
    if (item.hasSizes) {
      final parts = <String>[];
      if (item.qty22 > 0) parts.add('2.2x${item.qty22}');
      if (item.qty24 > 0) parts.add('2.4x${item.qty24}');
      if (item.qty26 > 0) parts.add('2.6x${item.qty26}');
      if (item.qty28 > 0) parts.add('2.8x${item.qty28}');
      if (item.qty210 > 0) parts.add('2.10x${item.qty210}');
      if (item.qty212 > 0) parts.add('2.12x${item.qty212}');
      return parts.isEmpty ? '0 sizes' : parts.join(', ');
    }
    return 'Qty: ${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 2)}';
  }

  Future<bool> _validate() async {
    if (_customerNameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter a customer name');
      return false;
    }
    if (_lines.isEmpty) {
      setState(() => _error = 'Add at least one item');
      return false;
    }
    for (final line in _lines) {
      final item = line.item;
      if (item.hasSizes && item.totalSizeQty == 0) {
        setState(
            () => _error = '${item.itemNumber}: select at least one size');
        return false;
      }
      if (!item.hasSizes && item.quantity <= 0) {
        setState(
            () => _error = '${item.itemNumber}: quantity must be > 0');
        return false;
      }
    }
    setState(() => _error = null);
    return true;
  }

  Future<void> _placeOrder() async {
    if (!await _validate()) return;
    if (!mounted) return;

    setState(() => _placing = true);
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(orderRepositoryProvider);

    try {
      final header = <String, dynamic>{
        'customer_name': _customerNameCtrl.text.trim(),
        'order_date': DateTime.now().toIso8601String().split('T').first,
        'customer_mobile': _customerMobileCtrl.text.trim().isEmpty
            ? null
            : _customerMobileCtrl.text.trim(),
        'source': 'admin',
        'status': 'pending',
        'total_amount': 0,
      };

      final created = await repo.insertOrderHeader(header);
      final orderId = created['order_id'] as int?;
      if (orderId == null) throw Exception('No order_id returned');

      final rows = _lines.map((line) {
        final item = line.item;
        return <String, dynamic>{
          'order_id': orderId,
          'item_number': item.itemNumber,
          'category': item.category,
          'qty_2_2': item.qty22,
          'qty_2_4': item.qty24,
          'qty_2_6': item.qty26,
          'qty_2_8': item.qty28,
          'qty_2_10': item.qty210,
          'qty_2_12': item.qty212,
          'quantity': item.quantity.toInt(),
          'color': item.color,
          'unit_price': item.unitPrice,
        };
      }).toList();

      await repo.insertOrderItems(rows);
      if (!mounted) return;

      // ignore: unused_result
      ref.refresh(labourOrdersProvider);

      _showSuccessDialog(orderId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Order failed: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  void _showSuccessDialog(int orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle,
            color: Color(0xFF2E7D32), size: 48),
        title: const Text('Order Created'),
        content: Text('Order #$orderId has been placed successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/dashboard');
            },
            child: const Text('Back to Dashboard'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/orders/$orderId');
            },
            child: const Text('View Order'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Create Order')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            // Customer info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Customer',
                        style:
                            TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customerNameCtrl,
                      decoration: InputDecoration(
                        hintText: 'Customer name',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customerMobileCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Mobile (optional)',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Error
            if (_error != null)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: Colors.red),
                      onPressed: () => setState(() => _error = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

            // Items
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Items',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        const Spacer(),
                        Text('${_lines.length} item${_lines.length == 1 ? '' : 's'}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_lines.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.shopping_cart_outlined,
                                  size: 40, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text('No items added yet',
                                  style:
                                      TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._lines.map((line) => _lineItemCard(line)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _placing ? null : _openItemPicker,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Browse Catalogue'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed:
                  _placing || _lines.isEmpty ? null : _placeOrder,
              icon: _placing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline),
              label: Text(_placing ? 'Placing Order...' : 'Place Order'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _lineItemCard(_LineItem line) {
    final item = line.item;
    final qty = item.hasSizes ? item.totalSizeQty : item.quantity.toInt();

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.itemNumber,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  Row(
                    children: [
                      Text('x$qty',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                      if (item.color != null && item.color!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(item.color!,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (action) {
                if (action == 'remove') {
                  setState(() => _lines.removeWhere(
                      (l) => l.item.itemNumber == item.itemNumber));
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'remove',
                    child: Text('Remove',
                        style: TextStyle(color: Colors.red))),
              ],
              icon: const Icon(Icons.more_vert, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineItem {
  final CartItem item;
  const _LineItem(this.item);
}

// --- Labour Item Picker (simplified) ---

class _LabourItemPickerSheet extends ConsumerStatefulWidget {
  const _LabourItemPickerSheet();

  @override
  ConsumerState<_LabourItemPickerSheet> createState() =>
      _LabourItemPickerSheetState();
}

class _LabourItemPickerSheetState
    extends ConsumerState<_LabourItemPickerSheet> {
  List<Category>? _categories;
  List<RateItem>? _allItems;
  List<RateItem>? _displayItems;
  String? _selectedCategory;
  bool _loadingCats = true;
  bool _loadingItems = false;
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
      final cats =
          await ref.read(categoryRepositoryProvider).getCategories(activeOnly: false);
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
    var items = _allItems!.where((i) => i.isAvailable).toList();
    if (query.isNotEmpty) {
      items = items
          .where((i) =>
              i.itemNumber.toLowerCase().contains(query) ||
              (i.subCategory?.toLowerCase().contains(query) ?? false) ||
              i.tags.any((t) => t.toLowerCase().contains(query)))
          .toList();
    }
    setState(() => _displayItems = items);
  }

  Future<void> _showItemForm(RateItem item) async {
    if (!item.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Item is unavailable'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final qtyCtrl = TextEditingController();
    final colorCtrl = TextEditingController();
    int size22 = 0, size24 = 0, size26 = 0,
        size28 = 0, size210 = 0, size212 = 0;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(item.itemNumber, style: const TextStyle(fontSize: 16)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.hasSizes) ...[
                    const Text('Sizes:',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    _sizeField(
                        '2.2', size22, (v) => setDialogState(() => size22 = v)),
                    _sizeField(
                        '2.4', size24, (v) => setDialogState(() => size24 = v)),
                    _sizeField(
                        '2.6', size26, (v) => setDialogState(() => size26 = v)),
                    _sizeField(
                        '2.8', size28, (v) => setDialogState(() => size28 = v)),
                    _sizeField('2.10', size210,
                        (v) => setDialogState(() => size210 = v)),
                    _sizeField('2.12', size212,
                        (v) => setDialogState(() => size212 = v)),
                  ] else ...[
                    TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                  if (item.hasColor) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: colorCtrl,
                      decoration: InputDecoration(
                        labelText: 'Color',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
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
                    color: colorCtrl.text.trim().isEmpty
                        ? null
                        : colorCtrl.text.trim(),
                    unitPrice: item.sellingPrice,
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

  Widget _sizeField(String label, int value, void Function(int) onChanged) {
    return Row(
      children: [
        SizedBox(width: 40,
            child: Text(label, style: const TextStyle(fontSize: 13))),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        SizedBox(
            width: 36,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700))),
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
                    style:
                        const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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
                  onPressed: () => setState(() {
                    _selectedCategory = null;
                    _allItems = null;
                    _displayItems = null;
                    _searchCtrl.clear();
                  }),
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
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    isDense: true,
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _applyFilter();
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => _applyFilter(),
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
      return const Center(
          child: Text('No categories', style: TextStyle(color: Colors.grey)));
    }
    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: cats.length,
      itemBuilder: (context, index) {
        final cat = cats[index];
        return InkWell(
          onTap: () => _loadItems(cat.name),
          borderRadius: BorderRadius.circular(12),
          child: Card(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: cat.coverImageUrl != null &&
                          cat.coverImageUrl!.isNotEmpty
                      ? Image.network(
                          cat.coverImageUrl!,
                          width: 54,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.category, size: 24, color: Colors.grey))
                      : const Icon(Icons.category, size: 24, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    cat.name.replaceAll('_', ' '),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
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
            const Icon(Icons.inventory_2_outlined,
                size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              _searchCtrl.text.isNotEmpty
                  ? 'No items match your search'
                  : 'No available items in this category',
              style: const TextStyle(color: Colors.grey),
            ),
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
                  ? Image.network(item.imageUrl,
                      width: 44,
                      height: 55,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image_outlined,
                              size: 24, color: Colors.grey))
                  : const Icon(Icons.image_outlined,
                      size: 24, color: Colors.grey),
            ),
            title: Text(item.itemNumber,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            trailing: FilledButton.tonalIcon(
              onPressed: () => _showItemForm(item),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ),
        );
      },
    );
  }
}

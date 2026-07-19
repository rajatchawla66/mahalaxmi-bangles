import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mahalaxmi_shared/mahalaxmi_shared.dart';
import '../providers/admin_order_create_provider.dart';
import '../providers/admin_orders_provider.dart';
import '../../customers/providers/admin_customers_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import 'admin_item_picker_sheet.dart';

class CreateOrderPage extends ConsumerStatefulWidget {
  const CreateOrderPage({super.key});

  @override
  ConsumerState<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends ConsumerState<CreateOrderPage> {
  final _mobileCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  bool _showSuggestions = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final state = ref.read(adminOrderCreateProvider);
    _mobileCtrl.text = state.customerMobile;
    _searchCtrl.text = state.customerName;
  }

  @override
  void dispose() {
    _mobileCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearCustomer() {
    ref.read(adminOrderCreateProvider.notifier).selectCustomer(null);
    _searchCtrl.clear();
    _mobileCtrl.clear();
    setState(() => _showSuggestions = false);
  }

  void _onCustomerSelected(Customer c) {
    ref.read(adminOrderCreateProvider.notifier).selectCustomer(c);
    _mobileCtrl.text = c.mobile;
    _searchCtrl.text = c.shopName;
    setState(() => _showSuggestions = false);
  }

  Future<void> _openItemPicker() async {
    final result = await showModalBottomSheet<CartItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AdminItemPickerSheet(),
    );

    if (result == null || !mounted) return;

    final notifier = ref.read(adminOrderCreateProvider.notifier);

    // Check duplicate variant
    final matchingId = ref.read(adminOrderCreateProvider).findMatchingLineId(result);
    if (matchingId != null) {
      final existing = ref.read(adminOrderCreateProvider).lines.firstWhere((l) => l.id == matchingId);
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Duplicate Item'),
          content: Text(
            '${result.itemNumber} already exists in the order.\n\n'
            'Existing: ${_describeItem(existing.item)}\n'
            'New: ${_describeItem(result)}',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, 'separate'), child: const Text('Add Separate')),
            TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, 'merge'), child: const Text('Merge Quantities')),
          ],
        ),
      );

      if (action == 'merge') {
        notifier.mergeIntoLine(matchingId, result);
      } else if (action == 'separate') {
        notifier.addLine(result);
      }
    } else {
      notifier.addLine(result);
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
    final desc = 'Qty: ${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 2)}';
    if (item.color != null && item.color!.isNotEmpty) return '$desc, ${item.color}';
    return desc;
  }

  Future<void> _editLine(CartLine line) async {
    final item = line.item;
    final isChuda = item.category.trim().toLowerCase() == 'chuda';

    List<ChudaCustomizationOption> pattiOpts = [];
    List<ChudaCustomizationOption> colorOpts = [];
    List<ChudaCustomizationOption> boxOpts = [];
    if (isChuda) {
      try {
        final all = await ref.read(chudaCustomizationRepositoryProvider).getAllOptions();
        pattiOpts = all.where((o) => o.groupType == 'patti' && o.isActive).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        colorOpts = all.where((o) => o.groupType == 'color' && o.isActive).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        boxOpts = all.where((o) => o.groupType == 'box' && o.isActive).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      } catch (_) {}
    }

    final qtyCtrl = TextEditingController(text: item.hasSizes ? '' : item.quantity.toString());
    final colorCtrl = TextEditingController(text: item.color ?? '');
    int size22 = item.qty22, size24 = item.qty24, size26 = item.qty26,
        size28 = item.qty28, size210 = item.qty210, size212 = item.qty212;

    // Reconstruct selected options from snapshot
    ChudaCustomizationOption? selPatti;
    ChudaCustomizationOption? selColor;
    ChudaCustomizationOption? selBox;
    var customColorText = '';

    final editBasePrice = isChuda && item.customization != null
        ? (item.unitPrice - item.customization!.totalDifference)
        : item.unitPrice;

    if (isChuda && item.customization != null) {
      final c = item.customization!;
      selPatti = pattiOpts.where((o) => o.name == c.pattiName).firstOrNull;
      selColor = colorOpts.where((o) => o.name == c.colorName).firstOrNull;
      selBox = boxOpts.where((o) => o.name == c.boxName).firstOrNull;
      customColorText = c.customColorText ?? '';
    } else if (isChuda) {
      selPatti = pattiOpts.isEmpty ? null
          : (pattiOpts.firstWhere((o) => o.isDefault, orElse: () => pattiOpts.first));
      selColor = colorOpts.isEmpty ? null
          : (colorOpts.firstWhere((o) => o.isDefault, orElse: () => colorOpts.first));
      selBox = boxOpts.isEmpty ? null
          : (boxOpts.firstWhere((o) => o.isDefault, orElse: () => boxOpts.first));
    }

    double customTotal() => ((selPatti?.priceDifference ?? 0) +
            (selColor?.priceDifference ?? 0) + (selBox?.priceDifference ?? 0))
        .toDouble();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final total = customTotal();

          return AlertDialog(
            title: Text(item.itemNumber, style: const TextStyle(fontSize: 16)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Base price: ₹${editBasePrice.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (total > 0)
                    Text('Customisation: +₹${total.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
                  Text('Final: ₹${(editBasePrice + total).toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1565C0))),
                  const SizedBox(height: 12),

                  if (item.hasSizes) ...[
                    const Text('Sizes:', style: TextStyle(fontWeight: FontWeight.w600)),
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
                    const SizedBox(height: 8),
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
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF800020))),
                    const SizedBox(height: 8),
                    if (pattiOpts.isEmpty && colorOpts.isEmpty && boxOpts.isEmpty)
                      const Text('Options not loaded. Save and re-open to edit.',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    if (pattiOpts.isNotEmpty) ...[
                      const Text('Patti', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      _editChudaChips(pattiOpts, selPatti, (v) => setDialogState(() => selPatti = v)),
                    ],
                    if (colorOpts.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Patti Color', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      _editChudaChips(colorOpts, selColor, (v) => setDialogState(() { selColor = v; if (v?.name != 'Custom') customColorText = ''; })),
                      if (selColor?.name == 'Custom') ...[
                        const SizedBox(height: 6),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Enter custom patti color',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            isDense: true,
                          ),
                          controller: TextEditingController(text: customColorText),
                          onChanged: (v) => customColorText = v,
                        ),
                      ],
                    ],
                    if (boxOpts.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Box', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      _editChudaChips(boxOpts, selBox, (v) => setDialogState(() => selBox = v)),
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
                  double finalPrice = editBasePrice;

                  if (isChuda) {
                    final pd = (selPatti?.priceDifference ?? 0).toDouble();
                    final cd = (selColor?.priceDifference ?? 0).toDouble();
                    final bd = (selBox?.priceDifference ?? 0).toDouble();
                    customization = ChudaCustomizationSnapshot(
                      pattiName: selPatti!.name,
                      pattiPriceDiff: pd,
                      colorName: selColor!.name,
                      colorPriceDiff: cd,
                      customColorText: selColor!.name == 'Custom' ? customColorText.trim() : null,
                      boxName: selBox!.name,
                      boxPriceDiff: bd,
                      totalDifference: pd + cd + bd,
                    );
                    finalPrice = editBasePrice + pd + cd + bd;
                  }

                  final updated = item.copyWith(
                    qty22: size22, qty24: size24, qty26: size26, qty28: size28,
                    qty210: size210, qty212: size212,
                    quantity: double.tryParse(qtyCtrl.text.trim()) ?? item.quantity,
                    color: isChuda ? null : (colorCtrl.text.trim().isEmpty ? null : colorCtrl.text.trim()),
                    unitPrice: finalPrice,
                    customization: customization,
                  );
                  Navigator.pop(ctx);
                  ref.read(adminOrderCreateProvider.notifier).updateLine(line.id, updated);
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _editChudaChips(
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

  Future<bool> _validate() async {
    final state = ref.read(adminOrderCreateProvider);

    if (state.lines.isEmpty) {
      setState(() => _error = 'Add at least one item to the order');
      return false;
    }

    final name = _searchCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a customer name');
      return false;
    }

    for (final line in state.lines) {
      final item = line.item;
      if (item.hasSizes && item.totalSizeQty == 0) {
        setState(() => _error = '${item.itemNumber}: select at least one size');
        return false;
      }
      if (!item.hasSizes && item.quantity <= 0) {
        setState(() => _error = '${item.itemNumber}: quantity must be greater than 0');
        return false;
      }
    }

    // Check for stale unavailable items (re-fetch from DB)
    try {
      final allItems = await ref.read(itemRepositoryProvider).getAllItems();
      for (final line in state.lines) {
        final dbItem = allItems.where((i) => i.itemNumber == line.item.itemNumber).firstOrNull;
        if (dbItem == null) {
          setState(() => _error = '${line.item.itemNumber}: item no longer exists');
          return false;
        }
        if (!dbItem.isAvailable) {
          setState(() => _error = '${line.item.itemNumber}: item is no longer available');
          return false;
        }
      }
    } catch (e) {
      setState(() => _error = 'Could not verify items: $e');
      return false;
    }

    setState(() => _error = null);
    return true;
  }

  Future<void> _placeOrder() async {
    final valid = await _validate();
    if (!valid) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final state = ref.read(adminOrderCreateProvider);
    final name = _searchCtrl.text.trim();
    final mobile = _mobileCtrl.text.trim();
    final repo = ref.read(orderRepositoryProvider);
    ref.read(adminOrderCreateProvider.notifier).setPlacing(true);
    setState(() => _error = null);

    try {
      final header = <String, dynamic>{
        'customer_name': name,
        'order_date': DateTime.now().toIso8601String().split('T').first,
        'customer_mobile': mobile.isEmpty ? null : mobile,
        if (state.selectedCustomer?.id != null) 'customer_id': state.selectedCustomer!.id,
        'source': 'admin',
        'status': 'pending',
        'total_amount': state.totalAmount,
      };

      final created = await repo.insertOrderHeader(header);
      final orderId = created['order_id'] as int?;
      if (orderId == null) throw Exception('No order_id returned');

      final rows = state.lines.map((line) {
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
          'unit': item.unit,
          'color': item.color,
          'notes': item.notes,
          'unit_price': item.unitPrice,
          'customization': item.customization?.toJson(),
        };
      }).toList();

      await repo.insertOrderItems(rows);
      if (!mounted) return;

      ref.read(adminOrderCreateProvider.notifier).reset();
      // ignore: unused_result
      ref.refresh(adminAllOrdersProvider);
      // ignore: unused_result
      ref.refresh(dashboardStatsProvider);

      _showSuccessDialog(orderId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Order failed: $e');
      messenger.showSnackBar(
        SnackBar(content: Text('Failed: $e'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) ref.read(adminOrderCreateProvider.notifier).setPlacing(false);
    }
  }

  void _showSuccessDialog(int orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 48),
        title: const Text('Order Created'),
        content: Text('Order #$orderId has been placed successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/orders');
            },
            child: const Text('Back to Orders'),
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
    final state = ref.watch(adminOrderCreateProvider);
    final customersAsync = ref.watch(adminCustomersProvider);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Create Order')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            // Customer section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Customer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 8),

                    if (state.selectedCustomer != null) ...[
                      // Selected customer display
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.15),
                              child: Text(
                                state.selectedCustomer!.shopName.isNotEmpty
                                    ? state.selectedCustomer!.shopName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1565C0)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(state.selectedCustomer!.shopName,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  if (state.selectedCustomer!.mobile.isNotEmpty)
                                    Text(state.selectedCustomer!.mobile,
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _clearCustomer,
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text('Change', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Search + Mobile fields
                      TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search customer or type name...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (v) {
                          setState(() => _showSuggestions = v.isNotEmpty);
                          ref.read(adminOrderCreateProvider.notifier).setCustomerName(v);
                        },
                      ),
                      if (_showSuggestions)
                        customersAsync.when(
                          data: (customers) {
                            final filtered = customers.where((c) =>
                              c.shopName.toLowerCase().contains(_searchCtrl.text.toLowerCase())).toList();
                            if (filtered.isEmpty) return const SizedBox.shrink();
                            return Container(
                              constraints: const BoxConstraints(maxHeight: 200),
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: filtered.length,
                                itemBuilder: (context, i) {
                                  final c = filtered[i];
                                  return ListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.1),
                                      child: Text(c.shopName.isNotEmpty ? c.shopName[0].toUpperCase() : '?',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1565C0))),
                                    ),
                                    title: Text(c.shopName, style: const TextStyle(fontSize: 13)),
                                    subtitle: Text(c.mobile.isNotEmpty ? c.mobile : 'No mobile',
                                        style: const TextStyle(fontSize: 11)),
                                    onTap: () => _onCustomerSelected(c),
                                  );
                                },
                              ),
                            );
                          },
                          error: (_, __) => const SizedBox.shrink(),
                          loading: () => const SizedBox.shrink(),
                        ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _mobileCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Mobile (optional)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (v) => ref.read(adminOrderCreateProvider.notifier).setCustomerMobile(v),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Error banner
            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: Colors.red),
                      onPressed: () => setState(() => _error = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

            // Items section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Items', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        const Spacer(),
                        Text('${state.itemCount} item${state.itemCount == 1 ? '' : 's'}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (state.lines.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.shopping_cart_outlined, size: 40, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text('No items added yet', style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...state.lines.map((line) => _lineItemCard(line)),

                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: state.placing ? null : _openItemPicker,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Browse Catalogue'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Total
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const Spacer(),
                    Text('₹${state.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Color(0xFF1565C0))),
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
              onPressed: state.placing || state.lines.isEmpty ? null : _placeOrder,
              icon: state.placing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline),
              label: Text(state.placing ? 'Placing Order...' : 'Place Order'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _lineItemCard(CartLine line) {
    final item = line.item;
    final qty = item.hasSizes ? item.totalSizeQty : item.quantity.toInt();
    final lineTotal = (item.hasSizes ? item.totalSizeQty.toDouble() : item.quantity) * item.unitPrice;

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
                  Text(item.itemNumber, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Row(
                    children: [
                      Text('x$qty', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      if (item.color != null && item.color!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: _colorFromName(item.color!), shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300))),
                        const SizedBox(width: 3),
                        Text(item.color!, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text('₹${lineTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              onSelected: (action) {
                if (action == 'edit') _editLine(line);
                if (action == 'remove') ref.read(adminOrderCreateProvider.notifier).removeLine(line.id);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'remove', child: Text('Remove', style: TextStyle(color: Colors.red))),
              ],
              icon: const Icon(Icons.more_vert, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorFromName(String name) {
    const colors = [
      Colors.red, Colors.blue, Colors.green, Colors.amber, Colors.purple,
      Colors.orange, Colors.teal, Colors.pink, Colors.indigo, Colors.lime,
    ];
    return colors[name.hashCode % colors.length];
  }
}

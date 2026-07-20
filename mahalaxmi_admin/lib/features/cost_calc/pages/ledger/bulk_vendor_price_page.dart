import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mahalaxmi_shared/providers/categories_provider.dart';
import 'package:mahalaxmi_shared/providers/repository_providers.dart';
import 'package:mahalaxmi_shared/providers/vendor_price_providers.dart';
import 'package:mahalaxmi_shared/providers/vendor_providers.dart';

class _RowData {
  final TextEditingController nameCtrl;
  final TextEditingController costPriceCtrl;
  final TextEditingController sellingPriceCtrl;
  final TextEditingController notesCtrl;

  _RowData()
      : nameCtrl = TextEditingController(),
        costPriceCtrl = TextEditingController(),
        sellingPriceCtrl = TextEditingController(),
        notesCtrl = TextEditingController();

  void dispose() {
    nameCtrl.dispose();
    costPriceCtrl.dispose();
    sellingPriceCtrl.dispose();
    notesCtrl.dispose();
  }
}

class BulkVendorPricePage extends ConsumerStatefulWidget {
  const BulkVendorPricePage({super.key});

  @override
  ConsumerState<BulkVendorPricePage> createState() =>
      _BulkVendorPricePageState();
}

class _BulkVendorPricePageState extends ConsumerState<BulkVendorPricePage> {
  final _formKey = GlobalKey<FormState>();
  final _rows = <_RowData>[];
  String? _vendorName;
  String? _categoryName;
  bool _autoCalc = true;
  String _marginType = 'percent';
  double _marginValue = 15;
  bool _saving = false;
  int _savedCount = 0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showCountDialog());
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _showCountDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('How many items?'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. 20',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              final count = int.tryParse(ctrl.text.trim());
              if (count == null || count <= 0 || count > 500) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Enter a valid number (1-500)')),
                );
                return;
              }
              Navigator.of(ctx).pop();
              setState(() {
                for (final row in _rows) row.dispose();
                _rows.clear();
                for (int i = 0; i < count; i++) {
                  _rows.add(_RowData());
                }
              });
            },
            child: const Text('Generate Rows'),
          ),
        ],
      ),
    );
  }

  void _addRow() {
    setState(() => _rows.add(_RowData()));
  }

  void _removeRow(int index) {
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
    });
  }

  void _recalcForRow(int index) {
    if (!_autoCalc) return;
    final cost = double.tryParse(_rows[index].costPriceCtrl.text.trim());
    if (cost == null || cost <= 0) return;
    double selling;
    if (_marginType == 'percent') {
      selling = cost * (1 + _marginValue / 100);
    } else {
      selling = cost + _marginValue;
    }
    _rows[index].sellingPriceCtrl.text = selling.toStringAsFixed(2);
  }

  Future<void> _saveAll() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vendorName == null) {
      _showError('Select a vendor');
      return;
    }
    if (_categoryName == null) {
      _showError('Select a category');
      return;
    }

    final validRows = <int>[];
    for (int i = 0; i < _rows.length; i++) {
      final name = _rows[i].nameCtrl.text.trim();
      final cost = double.tryParse(_rows[i].costPriceCtrl.text.trim());
      final sp = double.tryParse(_rows[i].sellingPriceCtrl.text.trim());
      if (name.isEmpty || cost == null || cost <= 0 || sp == null || sp <= 0) continue;
      validRows.add(i);
    }

    if (validRows.isEmpty) {
      _showError('No valid rows to save');
      return;
    }

    setState(() {
      _saving = true;
      _savedCount = 0;
      _totalCount = validRows.length;
    });

    final repo = ref.read(vendorPriceRepositoryProvider);
    final errors = <String>[];

    for (int idx = 0; idx < validRows.length; idx++) {
      final i = validRows[idx];
      final name = _rows[i].nameCtrl.text.trim();
      final costPrice = double.tryParse(_rows[i].costPriceCtrl.text.trim()) ?? 0;
      final sellingPrice = double.tryParse(_rows[i].sellingPriceCtrl.text.trim()) ?? 0;
      final notes = _rows[i].notesCtrl.text.trim();

      try {
        await repo.add({
          'item_name': name,
          'vendor_name': _vendorName,
          'category': _categoryName,
          'cost_price': costPrice,
          'selling_price': sellingPrice,
          'margin_type': _marginType,
          'margin_value': _marginValue,
          if (notes.isNotEmpty) 'notes': notes,
        });
      } catch (e) {
        errors.add('$name: $e');
      }

      if (mounted) {
        setState(() => _savedCount = idx + 1);
      }
    }

    if (!mounted) return;

    ref.invalidate(vendorPriceRepositoryProvider);
    ref.invalidate(allVendorPricesProvider);

    setState(() => _saving = false);

    if (errors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All ${validRows.length} records saved'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved ${validRows.length - errors.length}/${validRows.length}. Errors: ${errors.first}'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vendorsAsync = ref.watch(vendorNamesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Vendor Prices'),
        actions: [
          if (_rows.isNotEmpty && !_saving)
            TextButton(
              onPressed: _showCountDialog,
              child: const Text('Reset'),
            ),
        ],
      ),
      body: _rows.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.table_rows_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('Tap + to start entering items', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                children: [
                  // Vendor selector
                  vendorsAsync.when(
                    loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator())),
                    error: (err, _) => Text('Error: $err', style: const TextStyle(color: Colors.red)),
                    data: (vendors) => DropdownButtonFormField<String>(
                      value: _vendorName,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Vendor *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: vendors.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                      onChanged: (v) => setState(() => _vendorName = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Category
                  ref.watch(activeCategoriesProvider).when(
                    loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator())),
                    error: (err, _) => Text('Error: $err', style: const TextStyle(color: Colors.red)),
                    data: (cats) {
                      final names = cats.map((c) => c.name).toList();
                      return DropdownButtonFormField<String>(
                        value: _categoryName,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        items: names.map((n) => DropdownMenuItem(
                          value: n,
                          child: Text(n.replaceAll('_', ' ')),
                        )).toList(),
                        onChanged: (v) => setState(() => _categoryName = v),
                        validator: (v) => v == null ? 'Required' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Header row
                  Row(
                    children: [
                      const Expanded(flex: 3, child: SizedBox()),
                      Expanded(
                        flex: 2,
                        child: Text('Cost Price', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade700)),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 2,
                        child: Text('Sell Price', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade700)),
                      ),
                      const SizedBox(width: 28),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Item rows
                  ...List.generate(_rows.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _rows[i].nameCtrl,
                              decoration: InputDecoration(
                                hintText: 'Item ${i + 1}',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                isDense: true,
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Req' : null,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _rows[i].costPriceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: '₹',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                isDense: true,
                              ),
                              onChanged: (_) {
                                setState(() => _recalcForRow(i));
                              },
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return null;
                                final val = double.tryParse(v.trim());
                                if (val == null || val <= 0) return 'Inv';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _rows[i].sellingPriceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: '₹',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                isDense: true,
                              ),
                              enabled: !_autoCalc,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return null;
                                final val = double.tryParse(v.trim());
                                if (val == null || val <= 0) return 'Inv';
                                return null;
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            onPressed: _rows.length > 1 ? () => _removeRow(i) : null,
                          ),
                        ],
                      ),
                    );
                  }),

                  // Add row button
                  OutlinedButton.icon(
                    onPressed: _addRow,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Row'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Margin settings
                  const Text('Selling Price Calculation', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Auto-calc Selling Price'),
                    subtitle: const Text('Based on margin below'),
                    value: _autoCalc,
                    onChanged: (v) {
                      setState(() {
                        _autoCalc = v;
                        if (v) {
                          for (int i = 0; i < _rows.length; i++) {
                            _recalcForRow(i);
                          }
                        }
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 4),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'percent', label: Text('%')),
                      ButtonSegment(value: 'flat', label: Text('Flat ₹')),
                    ],
                    selected: {_marginType},
                    onSelectionChanged: (v) {
                      setState(() => _marginType = v.first);
                      for (int i = 0; i < _rows.length; i++) {
                        _recalcForRow(i);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  if (_marginType == 'percent')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Margin: ${_marginValue.toStringAsFixed(0)}%'),
                        Slider(
                          value: _marginValue.clamp(0, 200),
                          min: 0,
                          max: 200,
                          divisions: 200,
                          label: '${_marginValue.toStringAsFixed(0)}%',
                          onChanged: (v) {
                            setState(() => _marginValue = v);
                            for (int i = 0; i < _rows.length; i++) {
                              _recalcForRow(i);
                            }
                          },
                        ),
                      ],
                    )
                  else
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Flat Margin (₹)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixText: '₹ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) {
                        setState(() => _marginValue = double.tryParse(v) ?? 0);
                        for (int i = 0; i < _rows.length; i++) {
                          _recalcForRow(i);
                        }
                      },
                    ),
                  const SizedBox(height: 16),

                  // Preview summary
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Preview: ${_rows.length} items',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 8),
                        ..._rows.map((row) {
                          final name = row.nameCtrl.text.trim();
                          final cost = double.tryParse(row.costPriceCtrl.text.trim());
                          final sp = double.tryParse(row.sellingPriceCtrl.text.trim());
                          if (name.isEmpty || cost == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Row(
                              children: [
                                Expanded(child: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                                Text('₹${cost.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 8),
                                Text('→', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                const SizedBox(width: 8),
                                Text('₹${sp?.toStringAsFixed(0) ?? '?'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: sp != null ? theme.colorScheme.primary : Colors.grey,
                                    )),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _rows.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _saving
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LinearProgressIndicator(value: _totalCount > 0 ? _savedCount / _totalCount : 0),
                          const SizedBox(height: 4),
                          Text('Saving $_savedCount of $_totalCount...',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      )
                    : FilledButton.icon(
                        onPressed: _saveAll,
                        icon: const Icon(Icons.save),
                        label: Text('Save All ${_rows.length} Records'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
              ),
            )
          : null,
    );
  }
}

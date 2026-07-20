import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mahalaxmi_shared/providers/categories_provider.dart';
import 'package:mahalaxmi_shared/providers/vendor_providers.dart';
import 'package:mahalaxmi_shared/repositories/vendor_price_repository.dart';
import 'package:mahalaxmi_shared/providers/repository_providers.dart';

class VendorPriceFormPage extends ConsumerStatefulWidget {
  final String? editId;

  const VendorPriceFormPage({super.key, this.editId});

  @override
  ConsumerState<VendorPriceFormPage> createState() =>
      _VendorPriceFormPageState();
}

class _VendorPriceFormPageState extends ConsumerState<VendorPriceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _notesController = TextEditingController();
  String _marginType = 'percent';
  double _marginValue = 0;
  bool _autoCalc = true;
  bool _saving = false;
  String? _vendorName;
  String? _categoryName;

  @override
  void dispose() {
    _nameController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _recalcSellingPrice() {
    if (!_autoCalc) return;
    final cost = double.tryParse(_costPriceController.text) ?? 0;
    if (cost <= 0) return;
    double selling;
    if (_marginType == 'percent') {
      selling = cost * (1 + _marginValue / 100);
    } else {
      selling = cost + _marginValue;
    }
    _sellingPriceController.text = selling.toStringAsFixed(2);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vendorName == null || _vendorName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vendor')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final costPrice =
          double.tryParse(_costPriceController.text) ?? 0;
      final sellingPrice =
          double.tryParse(_sellingPriceController.text) ?? 0;

      final payload = <String, dynamic>{
        'item_name': _nameController.text.trim(),
        'category': _categoryName,
        'vendor_name': _vendorName,
        'cost_price': costPrice,
        'margin_type': _marginType,
        'margin_value': _marginValue,
        'selling_price': sellingPrice,
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      };

      if (widget.editId != null) {
        await ref
            .read(vendorPriceRepositoryProvider)
            .update(widget.editId!, payload);
      } else {
        await ref
            .read(vendorPriceRepositoryProvider)
            .add(payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record saved')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendorsAsync = ref.watch(vendorNamesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editId != null ? 'Edit Record' : 'Add Record'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save',
                    style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            ref.watch(activeCategoriesProvider).when(
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => Text('Error: $err'),
              data: (cats) {
                final names = cats.map((c) => c.name).toList();
                return DropdownButtonFormField<String>(
                  value: _categoryName,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                  ),
                  items: names.map((n) {
                    return DropdownMenuItem(value: n, child: Text(n.replaceAll('_', ' ')));
                  }).toList(),
                  onChanged: (v) => setState(() => _categoryName = v),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                );
              },
            ),
            const SizedBox(height: 16),
            vendorsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => Text('Error: $err'),
              data: (vendors) {
                return DropdownButtonFormField<String>(
                  value: _vendorName,
                  decoration: const InputDecoration(
                    labelText: 'Vendor *',
                    border: OutlineInputBorder(),
                  ),
                  items: vendors.map((v) {
                    return DropdownMenuItem(value: v, child: Text(v));
                  }).toList(),
                  onChanged: (v) => setState(() => _vendorName = v),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                );
              },
            ),
            const SizedBox(height: 24),
            const Text('Pricing',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _costPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Cost Price *',
                      border: OutlineInputBorder(),
                      prefixText: '₹ ',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _recalcSellingPrice(),
                    validator: (v) {
                      final val = double.tryParse(v ?? '');
                      if (val == null || val <= 0) return 'Enter valid price';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sellingPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Selling Price *',
                      border: OutlineInputBorder(),
                      prefixText: '₹ ',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    enabled: !_autoCalc,
                    validator: (v) {
                      final val = double.tryParse(v ?? '');
                      if (val == null || val <= 0) return 'Enter valid price';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Auto-calc Selling Price'),
              subtitle: const Text('Based on margin below'),
              value: _autoCalc,
              onChanged: (v) => setState(() => _autoCalc = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            Text('Margin Type',
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 4),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'percent', label: Text('%')),
                ButtonSegment(value: 'flat', label: Text('Flat ₹')),
              ],
              selected: {_marginType},
              onSelectionChanged: (v) {
                setState(() => _marginType = v.first);
                _recalcSellingPrice();
              },
            ),
            const SizedBox(height: 8),
            if (_marginType == 'percent')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Margin: ${_marginValue.toStringAsFixed(0)}%'),
                  Slider(
                    value: _marginValue,
                    min: 0,
                    max: 200,
                    divisions: 200,
                    label: '${_marginValue.toStringAsFixed(0)}%',
                    onChanged: (v) {
                      setState(() => _marginValue = v);
                      _recalcSellingPrice();
                    },
                  ),
                ],
              )
            else
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Flat Margin (₹)',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) {
                  setState(() =>
                      _marginValue = double.tryParse(v) ?? 0);
                  _recalcSellingPrice();
                },
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                hintText: 'Optional',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}

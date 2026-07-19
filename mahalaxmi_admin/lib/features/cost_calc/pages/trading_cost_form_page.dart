import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mahalaxmi_shared/mahalaxmi_shared.dart';

import '../../catalogue/providers/admin_catalogue_provider.dart';
import '../providers/cost_calculations_provider.dart';
import '../providers/trading_margin_settings_provider.dart';
import '../repository/cost_calculations_repository.dart';

double _roundToNearest5(double val) {
  return (val / 5).round() * 5.0;
}

class TradingCostFormPage extends ConsumerStatefulWidget {
  final String? initialCategory;
  final String? initialItemNumber;

  const TradingCostFormPage({
    super.key,
    this.initialCategory,
    this.initialItemNumber,
  });

  @override
  ConsumerState<TradingCostFormPage> createState() =>
      _TradingCostFormPageState();
}

class _TradingCostFormPageState extends ConsumerState<TradingCostFormPage> {
  final _itemSearchController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _flatMarginController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  RateItem? _selectedItem;
  String? _customName;
  bool _searching = false;
  bool _saving = false;

  double? _calculatedSellingPrice;
  double _marginPercent = 15;

  @override
  void initState() {
    super.initState();
    if (widget.initialItemNumber != null) {
      _itemSearchController.text = widget.initialItemNumber!;
      _searchItem(widget.initialItemNumber!);
    }
    _costPriceController.addListener(_recalc);
    _flatMarginController.addListener(() {
      _recalc();
      final flat = double.tryParse(_flatMarginController.text);
      if (flat != null) {
        ref.read(tradingMarginSettingsProvider.notifier).setFlatAmount(flat);
      }
    });
    _marginPercent = ref.read(tradingMarginSettingsProvider).marginPercent;
    _flatMarginController.text = ref.read(tradingMarginSettingsProvider).flatAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _itemSearchController.dispose();
    _costPriceController.dispose();
    _flatMarginController.dispose();
    super.dispose();
  }

  void _recalc() {
    final costPrice = double.tryParse(_costPriceController.text) ?? 0;
    if (costPrice <= 0) {
      setState(() => _calculatedSellingPrice = null);
      return;
    }
    final settings = ref.read(tradingMarginSettingsProvider);
    if (settings.marginType == 'flat') {
      final flat = double.tryParse(_flatMarginController.text) ?? 0;
      setState(() => _calculatedSellingPrice = costPrice + flat);
    } else {
      final sp = costPrice * (1 + _marginPercent / 100);
      setState(() => _calculatedSellingPrice = _roundToNearest5(sp));
    }
  }

  double get _effectiveSellingPrice {
    final costPrice = double.tryParse(_costPriceController.text) ?? 0;
    if (costPrice <= 0) return 0;
    final settings = ref.read(tradingMarginSettingsProvider);
    if (settings.marginType == 'flat') {
      final flat = double.tryParse(_flatMarginController.text) ?? 0;
      return costPrice + flat;
    } else {
      final sp = costPrice * (1 + _marginPercent / 100);
      return _roundToNearest5(sp);
    }
  }

  Future<void> _searchItem(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _searching = true);
    try {
      final repo = ref.read(itemRepositoryProvider);
      final all = await repo.getAllItems();
      final exact = all.where((i) {
        final q = query.trim().toLowerCase();
        return i.itemNumber.toLowerCase() == q;
      }).toList();
      if (exact.isNotEmpty) {
        setState(() {
          _selectedItem = exact.first;
          _customName = null;
          _costPriceController.text = exact.first.costPrice > 0
              ? exact.first.costPrice.toStringAsFixed(2)
              : '';
        });
      } else {
        setState(() {
          _selectedItem = null;
          _customName = query.trim();
        });
      }
    } catch (_) {
      setState(() => _selectedItem = null);
    }
    setState(() => _searching = false);
  }

  Future<void> _quickCreateItem(String itemName) async {
    final categories = ref.read(activeCategoriesProvider).valueOrNull ?? [];
    final initialCategory = widget.initialCategory ?? '';
    String? category = initialCategory;

    if (category.isEmpty && categories.isNotEmpty) {
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Select Category'),
          children: categories
              .map((c) => SimpleDialogOption(
                    onPressed: () => Navigator.of(ctx).pop(c.name),
                    child: Text(c.name.replaceAll('_', ' ')),
                  ))
              .toList(),
        ),
      );
      if (result == null) return;
      category = result;
    }

    if (category == null || category.isEmpty) return;

    try {
      final repo = ref.read(itemRepositoryProvider);
      await repo.addRateItem({
        'item_number': itemName,
        'category': category,
        'selling_price': 0,
        'cost_price': 0,
        'is_available': true,
        'available_sizes': [],
      });
      if (!mounted) return;
      await _searchItem(itemName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created "$itemName" in ${category!}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final costPrice = double.tryParse(_costPriceController.text) ?? 0;
    final sellingPrice = _effectiveSellingPrice;
    if (costPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid cost price')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final itemNumber =
          _selectedItem?.itemNumber ?? _customName ?? '';
      final session = ref.read(appSessionProvider);
      final category = widget.initialCategory ?? (_selectedItem?.category ?? '');

      final itemRepo = ref.read(itemRepositoryProvider);
      final existing = await itemRepo.getItemByNumber(itemNumber);
      if (existing == null) {
        await itemRepo.addRateItem({
          'item_number': itemNumber,
          'category': category,
          'selling_price': 0,
          'cost_price': 0,
          'is_available': true,
          'available_sizes': [],
        });
      }
      await itemRepo.updateRateItem(itemNumber, {
        'cost_price': costPrice,
        if (sellingPrice > 0) 'selling_price': sellingPrice,
      });

      final calcRepo = ref.read(costCalculationsRepositoryProvider);
      final calc = CostCalculation(
        itemName: itemNumber,
        itemNumber: itemNumber,
        category: category,
        costingType: 'trading',
        materials: {},
        totalCost: costPrice,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: session.username ?? 'admin',
        updatedBy: session.username ?? 'admin',
      );
      await calcRepo.create(calc);

      if (mounted) {
        ref.invalidate(costCalculationsProvider);
        ref.invalidate(costCalculatedItemNumbersProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trading cost saved')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final marginSettings = ref.watch(tradingMarginSettingsProvider);
    final costPrice = double.tryParse(_costPriceController.text) ?? 0;
    final sp = _calculatedSellingPrice;

    return Scaffold(
      appBar: AppBar(title: const Text('Trading Cost')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _itemSearchController,
              decoration: InputDecoration(
                labelText: 'Item Number / Name',
                hintText: 'Search or type item name',
                prefixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : const Icon(Icons.search),
                suffixIcon: _selectedItem != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _selectedItem = null;
                            _customName = null;
                            _itemSearchController.clear();
                            _costPriceController.clear();
                            _calculatedSellingPrice = null;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onFieldSubmitted: _searchItem,
              onChanged: (v) {
                if (v.length >= 2) _searchItem(v);
              },
            ),
            if (_selectedItem != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 16, color: Color(0xFF1565C0)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Linked to: ${_selectedItem!.itemNumber}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    Text(_selectedItem!.category,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
            if (_customName != null && _selectedItem == null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '"$_customName" not in catalogue',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _quickCreateItem(_customName!),
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text('Add to catalogue'),
              ),
            ],
            const SizedBox(height: 20),

            // Cost Price
            TextFormField(
              controller: _costPriceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Cost Price (₹)',
                prefixText: '₹ ',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final val = double.tryParse(v);
                if (val == null || val <= 0) return 'Enter a valid price';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Margin Type Selector
            const Text('Selling Price Calculation',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'flat', label: Text('₹ Flat')),
                ButtonSegment(value: 'percent', label: Text('% Margin')),
              ],
              selected: {marginSettings.marginType},
              onSelectionChanged: (v) {
                ref
                    .read(tradingMarginSettingsProvider.notifier)
                    .setMarginType(v.first);
                _recalc();
              },
            ),
            const SizedBox(height: 14),

            // Flat Margin Input
            if (marginSettings.marginType == 'flat') ...[
              TextFormField(
                controller: _flatMarginController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Flat Margin (₹)',
                  hintText: 'e.g. 50',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],

            // % Margin Slider
            if (marginSettings.marginType == 'percent') ...[
              Row(
                children: [
                  Text('${_marginPercent.round()}%',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  Expanded(
                    child: Slider(
                      value: _marginPercent,
                      min: 0,
                      max: 100,
                      divisions: 40,
                      label: '${_marginPercent.round()}%',
                      onChanged: (v) {
                        setState(() => _marginPercent = v);
                        ref
                            .read(tradingMarginSettingsProvider.notifier)
                            .setMarginPercent(v);
                        _recalc();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text('${_marginPercent.round()}%',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600])),
                  ),
                ],
              ),
            ],

            // Selling Price Result Card
            const SizedBox(height: 16),
            if (sp != null && costPrice > 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Cost Price',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[700])),
                        Text('\u20B9${costPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          marginSettings.marginType == 'flat'
                              ? 'Flat Margin'
                              : 'Margin (${_marginPercent.round()}%)',
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                        Text(
                          marginSettings.marginType == 'flat'
                              ? '\u20B9${(double.tryParse(_flatMarginController.text) ?? 0).toStringAsFixed(2)}'
                              : '\u20B9${(costPrice * _marginPercent / 100).toStringAsFixed(2)}',
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Selling Price',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        Text('\u20B9${sp.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: theme.colorScheme.primary,
                            )),
                      ],
                    ),
                    if (marginSettings.marginType == 'percent')
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text('rounded to nearest ₹5',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[500])),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            if (costPrice <= 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: Colors.grey[500]),
                    const SizedBox(width: 8),
                    Text('Enter a cost price to calculate selling price',
                        style: TextStyle(color: Colors.grey[500])),
                  ],
                ),
              ),

            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Save Trading Cost'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

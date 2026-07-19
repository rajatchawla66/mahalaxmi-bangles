import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mahalaxmi_shared/mahalaxmi_shared.dart';

import '../../catalogue/providers/admin_catalogue_provider.dart';
import '../../cost_calc/providers/cost_calculations_provider.dart';
import '../../cost_calc/providers/trading_margin_settings_provider.dart';
import '../../cost_calc/repository/cost_calculations_repository.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/crop_image_dialog.dart';

class _RowData {
  final TextEditingController itemNumberCtrl;
  final TextEditingController costPriceCtrl;
  Uint8List? imageBytes;

  _RowData() : itemNumberCtrl = TextEditingController(), costPriceCtrl = TextEditingController();

  void dispose() {
    itemNumberCtrl.dispose();
    costPriceCtrl.dispose();
  }
}

class BulkTradingCostPage extends ConsumerStatefulWidget {
  final String? initialCategory;

  const BulkTradingCostPage({super.key, this.initialCategory});

  @override
  ConsumerState<BulkTradingCostPage> createState() => _BulkTradingCostPageState();
}

class _BulkTradingCostPageState extends ConsumerState<BulkTradingCostPage> {
  final _formKey = GlobalKey<FormState>();
  final _rows = <_RowData>[];
  String? _selectedCategory;
  String _marginType = 'percent';
  double _marginPercent = 15;
  double _flatMargin = 0;
  bool _saving = false;
  int _savedCount = 0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    final settings = ref.read(tradingMarginSettingsProvider);
    _marginType = settings.marginType;
    _marginPercent = settings.marginPercent;
    _flatMargin = settings.flatAmount;
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
            hintText: 'e.g. 40',
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

  double _computeSellingPrice(double costPrice) {
    if (costPrice <= 0) return 0;
    if (_marginType == 'flat') {
      return costPrice + _flatMargin;
    } else {
      return (costPrice * (1 + _marginPercent / 100) / 5).round() * 5.0;
    }
  }

  static const _filePickerChannel = MethodChannel('com.example.mahalaxmi_admin/file_picker');

  Future<void> _processImageBytes(int rowIndex, Uint8List rawBytes) async {
    if (!mounted) return;
    final cropped = await showDialog<Uint8List>(
      context: context,
      builder: (_) => CropImageDialog(
        imageBytes: rawBytes,
        aspectRatio: ImagePolicy.productAspectRatio,
      ),
    );
    if (cropped != null && mounted) {
      final processed = ImageProcessor.processImage(
        bytes: cropped,
        targetWidth: ImagePolicy.productOutputWidth,
        targetHeight: ImagePolicy.productOutputHeight,
        jpegQuality: ImagePolicy.productJpegQuality,
      );
      if (processed != null) {
        setState(() => _rows[rowIndex].imageBytes = processed);
      }
    }
  }

  void _pickImageForRow(int index) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                final image = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (image != null) {
                  final rawBytes = await image.readAsBytes();
                  await _processImageBytes(index, rawBytes);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('Browse Files'),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final bytes = await _filePickerChannel.invokeMethod<Uint8List>('pickImage');
                  if (bytes != null) {
                    await _processImageBytes(index, bytes);
                  }
                } catch (e) {
                  if (mounted) _showError('Could not open file picker: $e');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAll() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showError('Select a category');
      return;
    }

    final validRows = <int>[];
    for (int i = 0; i < _rows.length; i++) {
      final itemNo = _rows[i].itemNumberCtrl.text.trim();
      final cost = double.tryParse(_rows[i].costPriceCtrl.text.trim());
      if (itemNo.isEmpty || cost == null || cost <= 0) continue;
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

    final itemRepo = ref.read(itemRepositoryProvider);
    final calcRepo = ref.read(costCalculationsRepositoryProvider);
    final session = ref.read(appSessionProvider);
    final errors = <String>[];

    for (int idx = 0; idx < validRows.length; idx++) {
      final i = validRows[idx];
      final itemNumber = _rows[i].itemNumberCtrl.text.trim();
      final costPrice = double.tryParse(_rows[i].costPriceCtrl.text.trim()) ?? 0;
      final sellingPrice = _computeSellingPrice(costPrice);

      try {
        String imageUrl = '';
        if (_rows[i].imageBytes != null) {
          imageUrl = await StorageService.uploadProductImage(_rows[i].imageBytes!, itemNumber, 'jpg');
        }
        await itemRepo.addRateItem({
          'item_number': itemNumber,
          'category': _selectedCategory!,
          'selling_price': 0,
          'cost_price': 0,
          'is_available': false,
          'available_sizes': [],
          if (imageUrl.isNotEmpty) 'image_url': imageUrl,
        });
        await itemRepo.updateRateItem(itemNumber, {
          'cost_price': costPrice,
          if (sellingPrice > 0) 'selling_price': sellingPrice,
        });
        final calc = CostCalculation(
          itemName: itemNumber,
          itemNumber: itemNumber,
          category: _selectedCategory!,
          costingType: 'trading',
          materials: {},
          totalCost: costPrice,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: session.username ?? 'admin',
          updatedBy: session.username ?? 'admin',
        );
        await calcRepo.create(calc);
      } catch (e) {
        errors.add('$itemNumber: $e');
      }

      if (mounted) {
        setState(() => _savedCount = idx + 1);
      }
    }

    if (!mounted) return;

    ref.invalidate(costCalculationsProvider);
    ref.invalidate(costCalculatedItemNumbersProvider);
    ref.invalidate(adminCategoriesWithStatsProvider);
    if (_selectedCategory != null) {
      ref.invalidate(adminCategoryItemsProvider(_selectedCategory!));
    }

    setState(() => _saving = false);

    if (errors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All ${validRows.length} items saved'),
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
    final catsAsync = ref.watch(activeCategoriesProvider);
    final marginSettings = ref.watch(tradingMarginSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Trading Cost'),
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
                  // Category selector
                  catsAsync.when(
                    loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator())),
                    error: (err, _) => Text('Error: $err', style: const TextStyle(color: Colors.red)),
                    data: (cats) {
                      final names = cats.map((c) => c.name).toList();
                      return DropdownButtonFormField<String>(
                        value: _selectedCategory != null && names.contains(_selectedCategory) ? _selectedCategory : null,
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
                        onChanged: (v) => setState(() => _selectedCategory = v),
                        validator: (v) => v == null ? 'Required' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Header row
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text('Item Number', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade700)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('Cost Price', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade700)),
                      ),
                      const SizedBox(width: 36),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Item rows
                  ...List.generate(_rows.length, (i) {
                    final row = _rows[i];
                    final cost = double.tryParse(row.costPriceCtrl.text.trim());
                    final sp = cost != null ? _computeSellingPrice(cost) : null;
                    final hasImage = row.imageBytes != null;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => _pickImageForRow(i),
                            child: Container(
                              width: 40,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: hasImage ? Colors.transparent : Colors.grey.shade100,
                                border: Border.all(color: Colors.grey.shade300, width: 1),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: hasImage
                                  ? Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.memory(row.imageBytes!, fit: BoxFit.cover),
                                        Positioned(
                                          top: 2,
                                          right: 2,
                                          child: GestureDetector(
                                            onTap: () => setState(() => row.imageBytes = null),
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              padding: const EdgeInsets.all(2),
                                              child: const Icon(Icons.close, size: 12, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Icon(Icons.camera_alt_outlined, size: 20, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: row.itemNumberCtrl,
                              decoration: InputDecoration(
                                hintText: 'Item ${i + 1}',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                isDense: true,
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Req' : null,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: row.costPriceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: '₹',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return null;
                                final val = double.tryParse(v.trim());
                                if (val == null || val <= 0) return 'Inv';
                                return null;
                              },
                            ),
                          ),
                          if (sp != null && sp > 0)
                            SizedBox(
                              width: 36,
                              child: Center(
                                child: Text('₹${sp.toStringAsFixed(0)}',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                              ),
                            )
                          else
                            const SizedBox(width: 36),
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

                  // Margin type selector
                  const Text('Selling Price Calculation', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'flat', label: Text('₹ Flat')),
                      ButtonSegment(value: 'percent', label: Text('% Margin')),
                    ],
                    selected: {_marginType},
                    onSelectionChanged: (v) {
                      setState(() => _marginType = v.first);
                      ref.read(tradingMarginSettingsProvider.notifier).setMarginType(v.first);
                    },
                  ),
                  const SizedBox(height: 12),

                  if (_marginType == 'flat')
                    TextFormField(
                      initialValue: _flatMargin > 0 ? _flatMargin.toStringAsFixed(0) : '',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Flat Margin (₹)',
                        hintText: 'e.g. 50',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (v) {
                        setState(() => _flatMargin = double.tryParse(v) ?? 0);
                        ref.read(tradingMarginSettingsProvider.notifier).setFlatAmount(_flatMargin);
                      },
                    ),

                  if (_marginType == 'percent')
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: _marginPercent.clamp(0, 40),
                                min: 0,
                                max: 40,
                                divisions: 40,
                                label: '${_marginPercent.toStringAsFixed(1)}%',
                                onChanged: (v) {
                                  setState(() => _marginPercent = v);
                                  ref.read(tradingMarginSettingsProvider.notifier).setMarginPercent(v);
                                },
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: TextButton(
                                onPressed: () async {
                                  final ctrl = TextEditingController(text: _marginPercent.toStringAsFixed(1));
                                  final result = await showDialog<String>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Margin %'),
                                      content: TextField(
                                        controller: ctrl,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        autofocus: true,
                                        decoration: InputDecoration(
                                          suffixText: '%',
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.pop(ctx, ctrl.text),
                                          child: const Text('Set'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (result != null) {
                                    final v = double.tryParse(result);
                                    if (v != null && v >= 0) {
                                      setState(() => _marginPercent = v);
                                      ref.read(tradingMarginSettingsProvider.notifier).setMarginPercent(v);
                                    }
                                  }
                                },
                                child: Text(
                                  '${_marginPercent.toStringAsFixed(1)}%',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
                          final itemNo = row.itemNumberCtrl.text.trim();
                          final cost = double.tryParse(row.costPriceCtrl.text.trim());
                          final sp = cost != null ? _computeSellingPrice(cost) : null;
                          if (itemNo.isEmpty || cost == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Row(
                              children: [
                                Expanded(child: Text(itemNo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
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
                        label: Text('Save All ${_rows.length} Items'),
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

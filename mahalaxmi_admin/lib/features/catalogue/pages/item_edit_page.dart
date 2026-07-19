import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mahalaxmi_shared/constants/size_charts.dart';
import 'package:mahalaxmi_shared/mahalaxmi_shared.dart';
import '../providers/admin_catalogue_provider.dart';
import '../../cost_calc/providers/cost_calculations_provider.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/crop_image_dialog.dart';
import '../../cost_calc/widgets/costing_method_dialog.dart';

class ItemEditPage extends ConsumerStatefulWidget {
  final String categoryName;
  final String itemNumber;

  const ItemEditPage({
    super.key,
    required this.categoryName,
    required this.itemNumber,
  });

  @override
  ConsumerState<ItemEditPage> createState() => _ItemEditPageState();
}

class _ItemEditPageState extends ConsumerState<ItemEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _marginPercentController = TextEditingController();
  final _sellingPriceFocusNode = FocusNode();

  List<String> _selectedTags = [];
  List<String> _availableSizes = [];
  bool _isAvailable = true;
  bool _hasSizes = false;
  bool _hasColor = false;
  bool _saving = false;
  bool _autoCalc = true;
  String? _error;
  bool _initialized = false;
  Uint8List? _newImageBytes;
  bool _imageChanged = false;

  List<String> get _currentCategorySizeChart {
    final cats = ref.read(adminCategoriesWithStatsProvider).asData?.value ?? [];
    final cat = cats.where((c) => c.category.name == widget.categoryName).firstOrNull?.category;
    return getSizeChartForCategory(cat ?? widget.categoryName);
  }

  @override
  void initState() {
    super.initState();
    _costPriceController.addListener(_onCostOrMarginChanged);
    _marginPercentController.addListener(_onCostOrMarginChanged);
    _sellingPriceFocusNode.addListener(() {
      if (_sellingPriceFocusNode.hasFocus) {
        setState(() {
          _autoCalc = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    _costPriceController.dispose();
    _marginPercentController.dispose();
    _sellingPriceFocusNode.dispose();
    super.dispose();
  }

  void _initFromItem(RateItem item) {
    if (_initialized) return;
    _initialized = true;

    // Calculate margin% from actual prices so auto-calc doesn't overwrite selling price
    final calcMargin = (item.costPrice > 0 && item.sellingPrice > 0)
        ? ((item.sellingPrice - item.costPrice) / item.costPrice * 100)
        : item.marginPercent;
    _marginPercentController.text = calcMargin.toStringAsFixed(1);

    _priceController.text = item.sellingPrice.toStringAsFixed(2);
    _costPriceController.text = item.costPrice.toStringAsFixed(2);
    _selectedTags = List.from(item.tags);
    _isAvailable = item.isAvailable;
    _hasSizes = item.hasSizes;
    _hasColor = item.hasColor;
    if (item.availableSizes != null) {
      _availableSizes = List.from(item.availableSizes!);
    } else {
      _availableSizes = List.from(_currentCategorySizeChart);
    }
  }

  void _onCostOrMarginChanged() {
    if (!_autoCalc) return;
    _updateSellingPrice();
  }

  void _updateSellingPrice() {
    final costPrice = double.tryParse(_costPriceController.text.trim()) ?? 0;
    final marginPercent = double.tryParse(_marginPercentController.text.trim()) ?? 0;
    if (costPrice > 0) {
      final sp = costPrice * (1 + marginPercent / 100);
      _priceController.text = sp.toStringAsFixed(2);
    }
  }

  Future<bool> _confirmZeroPrice() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Price is zero'),
        content: const Text(
          'Items with selling price ₹0.00 are hidden from the customer app. '
          'Only admins will see this item. Continue?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Set price'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);

    final newPrice = double.tryParse(_priceController.text.trim()) ?? 0;
    if (newPrice < 0) {
      setState(() => _error = 'Enter a valid non-negative price');
      return;
    }

    if (newPrice == 0 && _isAvailable) {
      final proceed = await _confirmZeroPrice();
      if (!proceed) return;
    }

    final newTags = List<String>.from(_selectedTags);
    final costPrice = double.tryParse(_costPriceController.text.trim()) ?? 0;
    final marginPercent = double.tryParse(_marginPercentController.text.trim()) ?? 0;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = ref.read(itemRepositoryProvider);

      String? uploadedUrl;
      if (_imageChanged) {
        if (_newImageBytes != null) {
          uploadedUrl = await StorageService.uploadProductImage(_newImageBytes!, widget.itemNumber, 'jpg');
        } else {
          uploadedUrl = '';
        }
      }

      await repo.updateRateItem(widget.itemNumber, {
        'selling_price': newPrice,
        'cost_price': costPrice,
        'margin_percent': marginPercent,
        'is_available': _isAvailable,
        'has_sizes': _hasSizes,
        'has_color': _hasColor,
        'tags': newTags,
        if (_imageChanged) 'image_url': uploadedUrl,
        if (_hasSizes && _currentCategorySizeChart.isNotEmpty)
          'available_sizes': _availableSizes.isEmpty ? null : _availableSizes,
      });

      // Update local state with saved values so the form reflects server state
      _priceController.text = newPrice.toStringAsFixed(2);
      _costPriceController.text = costPrice.toStringAsFixed(2);
      _marginPercentController.text = marginPercent.toStringAsFixed(1);
      _selectedTags = List.from(newTags);

      // ignore: unused_result
      ref.refresh(adminCategoryItemsProvider(widget.categoryName));
      // ignore: unused_result
      ref.refresh(adminCategoriesWithStatsProvider);

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Item updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Save failed: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('Are you sure you want to permanently delete item "${widget.itemNumber}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = ref.read(itemRepositoryProvider);
      await repo.deleteRateItem(widget.itemNumber);

      // ignore: unused_result
      ref.refresh(adminCategoryItemsProvider(widget.categoryName));
      // ignore: unused_result
      ref.refresh(adminCategoriesWithStatsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item deleted'), behavior: SnackBarBehavior.floating),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Delete failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmToggleAvailability(bool newValue) async {
    if (newValue == _isAvailable) return;

    final willShow = newValue;
    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    final hiddenByPrice = willShow && price == 0;

    final content = !willShow
        ? 'This item will no longer be visible to customers.'
        : hiddenByPrice
            ? 'This item is set to available, but the selling price is ₹0. '
              'It will remain hidden from customers until a price is set.'
            : 'This item will become visible to customers.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${willShow ? 'Show' : 'Hide'} Item?'),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(willShow ? 'Show' : 'Hide'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isAvailable = newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(adminCategoryItemsProvider(widget.categoryName));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemNumber),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete Item',
            onPressed: _saving ? null : _delete,
          ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: itemAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (items) {
          final item = items.where((i) => i.itemNumber == widget.itemNumber).firstOrNull;
          if (item == null) {
            return const Center(child: Text('Item not found'));
          }

          _initFromItem(item);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Product Image Section with 4:5 Crop support
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Item Picture', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 12),
                        if (_imageChanged && _newImageBytes != null) ...[
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              AspectRatio(
                                aspectRatio: ImagePolicy.productAspectRatio,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    _newImageBytes!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => setState(() {
                                  _newImageBytes = null;
                                  _imageChanged = true;
                                }),
                                icon: const Icon(Icons.cancel, color: Colors.red),
                              ),
                            ],
                          ),
                        ] else if (!_imageChanged && item.imageUrl.isNotEmpty) ...[
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              AspectRatio(
                                aspectRatio: ImagePolicy.productAspectRatio,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 48),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => setState(() {
                                  _newImageBytes = null;
                                  _imageChanged = true;
                                }),
                                icon: const Icon(Icons.delete, color: Colors.red),
                              ),
                            ],
                          ),
                        ] else ...[
                          Container(
                            height: 150,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_outlined, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('No image set', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final image = await ImagePicker().pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              final rawBytes = await image.readAsBytes();
                              if (!mounted) return;
                              final cropped = await showDialog<Uint8List>(
                                context: context,
                                builder: (_) => CropImageDialog(
                                  imageBytes: rawBytes,
                                  aspectRatio: ImagePolicy.productAspectRatio,
                                ),
                              );
                              if (cropped != null) {
                                final processed = ImageProcessor.processImage(
                                  bytes: cropped,
                                  targetWidth: ImagePolicy.productOutputWidth,
                                  targetHeight: ImagePolicy.productOutputHeight,
                                  jpegQuality: ImagePolicy.productJpegQuality,
                                );
                                if (processed != null) {
                                  setState(() {
                                    _newImageBytes = processed;
                                    _imageChanged = true;
                                  });
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.image_outlined),
                          label: Text(item.imageUrl.isNotEmpty ? 'Change Image' : 'Select Image'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Availability switch
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    title: const Text('Available to customers'),
                    subtitle: Text(_isAvailable
                        ? (item.sellingPrice == 0
                            ? 'Available but price is ₹0 — hidden from customers'
                            : 'Item is visible in catalogue')
                        : 'Item is hidden from customers'),
                    value: _isAvailable,
                    onChanged: _confirmToggleAvailability,
                  ),
                ),
                const SizedBox(height: 8),

                // Pricing Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pricing', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 12),

                        // Cost Price
                        TextFormField(
                          controller: _costPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Cost Price (optional, to be added later)',
                            prefixText: '₹ ',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Margin
                        TextFormField(
                          controller: _marginPercentController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Margin %',
                            suffixText: '%',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Selling Price
                        TextFormField(
                          controller: _priceController,
                          focusNode: _sellingPriceFocusNode,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Selling Price (optional)',
                            prefixText: '₹ ',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final val = double.tryParse(v.trim());
                            if (val == null || val < 0) return 'Must be a valid positive number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              _autoCalc ? Icons.link : Icons.link_off,
                              size: 16,
                              color: _autoCalc ? Colors.green.shade700 : Colors.orange.shade700,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _autoCalc
                                    ? 'Linked to Cost & Margin'
                                    : 'Manual override active',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _autoCalc ? Colors.green.shade700 : Colors.orange.shade700,
                                ),
                              ),
                            ),
                            if (!_autoCalc)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _autoCalc = true;
                                    _updateSellingPrice();
                                  });
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Reset to Margin'),
                              ),
                          ],
                        ),
                        if (_isAvailable &&
                            (double.tryParse(_priceController.text.trim()) ?? 0) == 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.visibility_off, size: 14, color: Colors.orange.shade700),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Price ₹0 hides this item from customers',
                                  style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Cost Calculation Card
                _buildCostCalcCard(item),
                const SizedBox(height: 8),

                // Tags Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tags', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 8),
                        if (_selectedTags.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text('No tags selected', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: _selectedTags.map((tag) => InputChip(
                                label: Text(tag, style: const TextStyle(fontSize: 13)),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () => setState(() => _selectedTags.remove(tag)),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              )).toList(),
                            ),
                          ),
                        ref.watch(activeTagMasterProvider).when(
                          loading: () => const SizedBox(height: 20, child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
                          error: (err, _) => Text('Error: $err', style: const TextStyle(fontSize: 12, color: Colors.red)),
                          data: (allTags) {
                            final available = allTags.where((t) => !_selectedTags.contains(t.name)).toList();
                            if (available.isEmpty) return const SizedBox.shrink();
                            return DropdownButton<String>(
                              value: null,
                              isExpanded: true,
                              hint: const Text('Add a tag...'),
                              items: available.map((t) => DropdownMenuItem(
                                value: t.name,
                                child: Text(t.displayName),
                              )).toList(),
                              onChanged: (tagName) {
                                if (tagName != null) {
                                  setState(() => _selectedTags.add(tagName));
                                }
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Attributes Card (Has Sizes, Has Colors)
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Has Sizes'),
                        value: _hasSizes,
                        onChanged: (v) {
                          setState(() {
                            _hasSizes = v;
                            if (!v) _availableSizes = [];
                          });
                        },
                      ),
                      if (_hasSizes && _currentCategorySizeChart.isNotEmpty) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Available Sizes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text('Uncheck sizes that are not available for this item.', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: _currentCategorySizeChart.map((sz) {
                                  final checked = _availableSizes.contains(sz);
                                  return FilterChip(
                                    label: Text(sz, style: TextStyle(fontSize: 13, color: checked ? Colors.white : Colors.grey.shade700)),
                                    selected: checked,
                                    selectedColor: const Color(0xFF800000),
                                    checkmarkColor: Colors.white,
                                    backgroundColor: Colors.grey.shade100,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _availableSizes.add(sz);
                                        } else {
                                          _availableSizes.remove(sz);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Has Color'),
                        value: _hasColor,
                        onChanged: (v) => setState(() => _hasColor = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Read-only Attributes Info Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Item Details', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 8),
                        _attrRow('Item Number', item.itemNumber),
                        _attrRow('Category', item.category.replaceAll('_', ' ')),
                        if (item.subCategory != null && item.subCategory!.isNotEmpty)
                          _attrRow('Sub Category', item.subCategory!),
                        _attrRow('Status', item.status),
                      ],
                    ),
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],

                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _delete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Delete Item', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCostCalcCard(RateItem item) {
    final theme = Theme.of(context);
    final recordsAsync = ref.watch(costCalculationsProvider);
    final records = recordsAsync.valueOrNull ?? [];
    final calc = records.where((r) =>
        r.itemNumber != null &&
        r.itemNumber!.isNotEmpty &&
        r.itemNumber == item.itemNumber).toList();
    final hasCostCalc = calc.isNotEmpty;
    final record = calc.isNotEmpty ? calc.first : null;
    final costingType = record?.costingType ?? 'manufacturing';

    Widget _badge(IconData icon, String label, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calculate, size: 20, color: Color(0xFF1565C0)),
                const SizedBox(width: 8),
                const Text('Cost Calculation',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const Spacer(),
                if (hasCostCalc) ...[
                  const SizedBox(width: 4),
                  _badge(
                    Icons.check_circle,
                    'Costed',
                    const Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 4),
                  _badge(
                    costingType == 'trading'
                        ? Icons.swap_horiz
                        : Icons.build,
                    costingType == 'trading' ? 'Trading' : 'Manufacturing',
                    costingType == 'trading'
                        ? const Color(0xFF2196F3)
                        : const Color(0xFFE91E63),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            if (hasCostCalc) ...[
              Text('\u20B9${record!.totalCost.toStringAsFixed(0)}',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary)),
              const SizedBox(height: 4),
              if (costingType == 'trading') ...[
                Text('Selling: \u20B9${item.sellingPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
              if (costingType == 'manufacturing') ...[
                Text(
                  '${record.materials.length} material${record.materials.length == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
              if (record.updatedAt != null) ...[
                const SizedBox(height: 2),
                Text('Updated ${_formatDate(record.updatedAt!)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ] else ...[
              Text('No cost calculation recorded',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade500)),
            ],
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () async {
                final basePath = hasCostCalc
                    ? (costingType == 'trading'
                        ? '/cost-calc/create/trading'
                        : '/cost-calc/create')
                    : null;
                if (basePath != null) {
                  if (!context.mounted) return;
                  context.push(
                    '$basePath?itemNumber=${Uri.encodeComponent(item.itemNumber)}&category=${Uri.encodeComponent(item.category)}',
                  );
                  return;
                }
                final method = await showCostingMethodDialog(context);
                if (method == null || !context.mounted) return;
                context.push(
                  '/cost-calc/create${method == 'trading' ? '/trading' : ''}?itemNumber=${Uri.encodeComponent(item.itemNumber)}&category=${Uri.encodeComponent(item.category)}',
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text(hasCostCalc ? 'Recalculate' : 'Calculate Cost'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attrRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

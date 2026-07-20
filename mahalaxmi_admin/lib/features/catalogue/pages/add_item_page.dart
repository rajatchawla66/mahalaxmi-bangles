import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mahalaxmi_shared/constants/size_charts.dart';
import 'package:mahalaxmi_shared/mahalaxmi_shared.dart';
import '../../../widgets/crop_image_dialog.dart';
import '../providers/admin_catalogue_provider.dart';
import '../../cost_calc/providers/cost_calculations_provider.dart';
import '../../../services/storage_service.dart';

class AddItemPage extends ConsumerStatefulWidget {
  final String? initialCategory;

  const AddItemPage({super.key, this.initialCategory});

  @override
  ConsumerState<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends ConsumerState<AddItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _itemNumberController = TextEditingController();
  final _subCategoryController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _marginPercentController = TextEditingController();
  final _sellingPriceFocusNode = FocusNode();

  String? _selectedCategory;
  List<String> _availableSizes = [];
  final List<String> _selectedTags = [];
  String? _vendorName;
  bool _isAvailable = true;
  bool _hasSizes = false;
  bool _hasColor = false;
  bool _saving = false;
  Uint8List? _pickedImageBytes;
  String _pricingMode = 'skip';
  String _costingType = 'trading';
  final _flatMarginController = TextEditingController();
  String _marginType = 'percent';
  double? _fullCalcSellingPrice;
  double _sliderMarginPercent = 30.0;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    if (widget.initialCategory != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final sizes = _currentCategorySizeChart;
          if (sizes.isNotEmpty) {
            setState(() {
              _availableSizes = List.from(sizes);
              _hasSizes = true;
            });
          }
        }
      });
    }
    _loadDefaultMargin();
    _costPriceController.addListener(_onCostOrMarginChanged);
    _marginPercentController.addListener(_onCostOrMarginChanged);
    _flatMarginController.addListener(_onCostOrMarginChanged);
  }

  Future<void> _processImageBytes(Uint8List rawBytes) async {
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
        setState(() => _pickedImageBytes = processed);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      final rawBytes = await image.readAsBytes();
      await _processImageBytes(rawBytes);
    }
  }

  static const _filePickerChannel = MethodChannel('com.example.mahalaxmi_admin/file_picker');

  Future<void> _pickFromFiles() async {
    try {
      final bytes = await _filePickerChannel.invokeMethod<Uint8List>('pickImage');
      if (bytes != null) {
        await _processImageBytes(bytes);
      }
    } catch (e) {
      if (mounted) {
        _showError('Could not open file picker: $e');
      }
    }
  }

  void _loadDefaultMargin() {
    ref.read(defaultMarginProvider.future).then((margin) {
      if (mounted) {
        setState(() {
          _sliderMarginPercent = margin;
          _marginPercentController.text = margin.toStringAsFixed(1);
        });
      }
    });
  }

  void _onCostOrMarginChanged() {
    if (_pricingMode == 'full' && _costingType == 'trading') {
      _recalcFullTrading();
    }
  }

  double _roundToNearest5(double val) {
    return (val / 5).round() * 5.0;
  }

  void _recalcFullTrading() {
    final costPrice = double.tryParse(_costPriceController.text.trim()) ?? 0;
    if (costPrice <= 0) {
      setState(() => _fullCalcSellingPrice = null);
      return;
    }
    if (_marginType == 'flat') {
      final flat = double.tryParse(_flatMarginController.text) ?? 0;
      setState(() => _fullCalcSellingPrice = costPrice + flat);
    } else {
      final marginPct = double.tryParse(_marginPercentController.text.trim()) ?? 0;
      setState(() => _fullCalcSellingPrice = _roundToNearest5(costPrice * (1 + marginPct / 100)));
    }
  }

  Widget _buildPricingSection() {
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
            const Text('Pricing (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _pricingMode,
              decoration: InputDecoration(
                labelText: 'Pricing Mode',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'skip', child: Text('Skip — no pricing yet')),
                DropdownMenuItem(value: 'cost_only', child: Text('Cost price only')),
                DropdownMenuItem(value: 'sell_only', child: Text('Selling price only')),
                DropdownMenuItem(value: 'full', child: Text('Full costing (Cost Calc style)')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _pricingMode = v);
              },
            ),
            const SizedBox(height: 16),
            if (_pricingMode == 'skip')
              Text('Pricing can be added later from the catalogue.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600))
            else if (_pricingMode == 'cost_only')
              TextFormField(
                controller: _costPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Cost Price',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              )
            else if (_pricingMode == 'sell_only')
              TextFormField(
                controller: _sellingPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Selling Price',
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
              )
            else if (_pricingMode == 'full')
              _buildFullCostingContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildFullCostingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ChoiceChip(
              label: const Text('Trading'),
              selected: _costingType == 'trading',
              onSelected: (_) => setState(() => _costingType = 'trading'),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Manufactured'),
              selected: _costingType == 'manufacturing',
              onSelected: (_) => setState(() => _costingType = 'manufacturing'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_costingType == 'trading') ...[
          TextFormField(
            controller: _costPriceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Cost Price',
              prefixText: '₹ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'flat', label: Text('₹ Flat')),
              ButtonSegment(value: 'percent', label: Text('% Margin')),
            ],
            selected: {_marginType},
            onSelectionChanged: (v) => setState(() => _marginType = v.first),
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(height: 12),
          if (_marginType == 'flat')
            TextFormField(
              controller: _flatMarginController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Flat Margin',
                prefixText: '₹ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            )
          else ...[
            Row(
              children: [
                const Text('Margin: ', style: TextStyle(fontSize: 13)),
                Expanded(
                  child: Slider(
                    value: _sliderMarginPercent,
                    min: 0,
                    max: 100,
                    divisions: 40,
                    label: '${_sliderMarginPercent.round()}%',
                    onChanged: (v) {
                      setState(() {
                        _sliderMarginPercent = v;
                        _marginPercentController.text = v.toStringAsFixed(1);
                      });
                    },
                  ),
                ),
                Text('${_sliderMarginPercent.round()}%',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          if (_fullCalcSellingPrice != null && _fullCalcSellingPrice! > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _resultRow(
                      'Cost Price',
                      _costPriceController.text.isNotEmpty
                          ? '₹ ${double.tryParse(_costPriceController.text)?.toStringAsFixed(0) ?? '0'}'
                          : '₹ 0'),
                  const SizedBox(height: 4),
                  _resultRow(
                      'Margin',
                      _marginType == 'flat'
                          ? '₹ ${_flatMarginController.text.isEmpty ? '0' : _flatMarginController.text}'
                          : '${_sliderMarginPercent.round()}%'),
                  const Divider(height: 16),
                  _resultRow('Selling Price',
                      '₹ ${_fullCalcSellingPrice!.toStringAsFixed(0)}',
                      bold: true),
                  Text('rounded to nearest ₹5',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
        ] else ...[
          TextFormField(
            controller: _costPriceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Cost Price',
              prefixText: '₹ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          Text('Detailed material breakdown can be added from the Cost Calc tab.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ],
    );
  }

  Widget _resultRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        Text(value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              fontSize: bold ? 16 : 13,
              color: bold ? const Color(0xFF800000) : Colors.black87,
            )),
      ],
    );
  }

  List<String> get _currentCategorySizeChart {
    if (_selectedCategory == null) return [];
    final cats = ref.read(adminCategoriesWithStatsProvider).asData?.value ?? [];
    final cat = cats.where((c) => c.category.name == _selectedCategory).firstOrNull?.category;
    return getSizeChartForCategory(cat ?? _selectedCategory!);
  }

  @override
  void dispose() {
    _itemNumberController.dispose();
    _subCategoryController.dispose();
    _sellingPriceController.dispose();
    _costPriceController.dispose();
    _marginPercentController.dispose();
    _flatMarginController.dispose();
    _sellingPriceFocusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final itemNumber = _itemNumberController.text.trim();
    if (itemNumber.isEmpty) {
      _showError('Item name is required');
      return;
    }

    if (_selectedCategory == null) {
      _showError('Category is required');
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(itemRepositoryProvider);
      double sellingPrice = 0;
      double costPrice = 0;
      double marginPercent = 0;

      switch (_pricingMode) {
        case 'skip':
          break;
        case 'cost_only':
          costPrice = double.tryParse(_costPriceController.text.trim()) ?? 0;
          break;
        case 'sell_only':
          sellingPrice = double.tryParse(_sellingPriceController.text.trim()) ?? 0;
          break;
        case 'full':
          if (_costingType == 'trading') {
            costPrice = double.tryParse(_costPriceController.text.trim()) ?? 0;
            sellingPrice = _fullCalcSellingPrice ?? 0;
            marginPercent = _marginType == 'percent'
                ? double.tryParse(_marginPercentController.text.trim()) ?? 0
                : 0;
          } else {
            costPrice = double.tryParse(_costPriceController.text.trim()) ?? 0;
          }
          break;
      }

      final subCategory = _subCategoryController.text.trim();

      String imageUrl = '';
      if (_pickedImageBytes != null) {
        imageUrl = await StorageService.uploadProductImage(_pickedImageBytes!, itemNumber, 'jpg');
      }

      await repo.addRateItem({
        'item_number': itemNumber,
        'category': _selectedCategory!,
        'sub_category': subCategory.isNotEmpty ? subCategory : null,
        'selling_price': sellingPrice,
        'cost_price': costPrice,
        'margin_percent': marginPercent,
        'tags': _selectedTags,
        'vendor': _vendorName,
        'is_available': _isAvailable,
        'has_sizes': _hasSizes,
        'has_color': _hasColor,
        'status': 'new',
        'image_url': imageUrl,
        if (_hasSizes && _currentCategorySizeChart.isNotEmpty)
          'available_sizes': _availableSizes.isEmpty ? null : _availableSizes,
      });

      // ignore: unused_result
      ref.refresh(adminCategoriesWithStatsProvider);
      if (_selectedCategory != null) {
        // ignore: unused_result
        ref.refresh(adminCategoryItemsProvider(_selectedCategory!));
      }
      // ignore: unused_result
      ref.invalidate(allRateItemsProvider);

      if (_pricingMode == 'full') {
        try {
          final session = ref.read(appSessionProvider);
          final calcRepo = ref.read(costCalculationsRepositoryProvider);
          final calc = CostCalculation(
            itemName: itemNumber,
            itemNumber: itemNumber,
            category: _selectedCategory!,
            subCategory: subCategory.isNotEmpty ? subCategory : null,
            costingType: _costingType,
            materials: {},
            totalCost: costPrice,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: session.username ?? 'admin',
            updatedBy: session.username ?? 'admin',
          );
          await calcRepo.create(calc);
          ref.invalidate(costCalculatedItemNumbersProvider);
        } catch (_) {
          // Cost calc record is non-critical; item was saved successfully
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item added'), behavior: SnackBarBehavior.floating),
      );
      context.pop();
    } catch (e) {
      _showError('Failed to add item: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
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
    final catsAsync = ref.watch(adminCategoriesWithStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Item'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Name
              TextFormField(
                controller: _itemNumberController,
                decoration: InputDecoration(
                  labelText: 'Item Name *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Category
              catsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error: $err', style: const TextStyle(color: Colors.red)),
                data: (cats) {
                  final categoryNames = cats.map((c) => c.category.name).toList();
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Category *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: categoryNames.map((n) => DropdownMenuItem(
                      value: n,
                      child: Text(n.replaceAll('_', ' ')),
                    )).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedCategory = v;
                        final cat = cats.where((c) => c.category.name == v).firstOrNull?.category;
                        final sizes = getSizeChartForCategory(cat ?? v ?? '');
                        _availableSizes = List.from(sizes);
                        if (sizes.isNotEmpty) _hasSizes = true;
                        _subCategoryController.clear();
                      });
                    },
                    validator: (v) => v == null ? 'Required' : null,
                  );
                },
              ),
              const SizedBox(height: 12),

              // Sub-category
              if (_selectedCategory != null)
                catsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (cats) {
                    final cat = cats.where((c) => c.category.name == _selectedCategory).firstOrNull;
                    if (cat == null || !cat.category.hasSubcategories) return const SizedBox.shrink();
                    final subs = cat.category.subCategoryList;
                    if (subs.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _subCategoryController.text.isNotEmpty ? _subCategoryController.text : null,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Sub Category',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          items: subs.map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s),
                          )).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              _subCategoryController.text = v;
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                ),

              // Item Picture (Optional)
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
                      const Text('Item Picture (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 12),
                      if (_pickedImageBytes != null) ...[
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            AspectRatio(
                              aspectRatio: ImagePolicy.productAspectRatio,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  _pickedImageBytes!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _pickedImageBytes = null),
                              icon: const Icon(Icons.cancel, color: Colors.red),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickFromGallery(),
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('Gallery'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickFromFiles(),
                                icon: const Icon(Icons.folder_open_outlined),
                                label: const Text('Browse Files'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Pricing Details
              _buildPricingSection(),
              const SizedBox(height: 12),

              // Tags
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

              // Vendor
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
                      const Text('Vendor', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      ref.watch(vendorNamesProvider).when(
                        loading: () => const SizedBox(height: 20, child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
                        error: (err, _) => Text('Error: $err', style: const TextStyle(fontSize: 12, color: Colors.red)),
                        data: (vendors) {
                          final allVendors = ['' /* None */, ...vendors];
                          return DropdownButtonFormField<String>(
                            value: _vendorName,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              hintText: 'Select vendor...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            items: allVendors.map((v) => DropdownMenuItem(
                              value: v.isEmpty ? null : v,
                              child: Text(v.isEmpty ? 'None' : v),
                            )).toList(),
                            onChanged: (v) => setState(() => _vendorName = v),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Availability
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: const Text('Available to customers'),
                  value: _isAvailable,
                  onChanged: (v) => setState(() => _isAvailable = v),
                ),
              ),
              const SizedBox(height: 4),

              // Has Sizes
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
                  ],
                ),
              ),
              const SizedBox(height: 4),

              // Has Color
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: const Text('Has Color'),
                  value: _hasColor,
                  onChanged: (v) => setState(() => _hasColor = v),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

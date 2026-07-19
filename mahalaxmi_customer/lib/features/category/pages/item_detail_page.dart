import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mahalaxmi_shared/constants/size_charts.dart';
import 'package:mahalaxmi_shared/models/cart_item.dart';
import 'package:mahalaxmi_shared/models/cart_state.dart';
import 'package:mahalaxmi_shared/providers/cart_provider.dart';
import 'package:mahalaxmi_shared/providers/items_provider.dart';
import 'package:mahalaxmi_shared/mahalaxmi_shared.dart';
import '../../../app/theme.dart';
import '../../../core/error_messages.dart';
import '../../../widgets/watermarked_product_image.dart';

String _priceLabel(double diff) {
  if (diff == 0) return 'Included';
  if (diff > 0) return '+₹${diff.toStringAsFixed(0)}';
  return '-₹${diff.abs().toStringAsFixed(0)}';
}

ChudaCustomizationOption? _findDefault(List<ChudaCustomizationOption> opts) {
  for (final o in opts) {
    if (o.isDefault) return o;
  }
  return opts.isNotEmpty ? opts.first : null;
}

class ItemDetailPage extends ConsumerStatefulWidget {
  final String itemNumber;

  const ItemDetailPage({super.key, required this.itemNumber});

  @override
  ConsumerState<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends ConsumerState<ItemDetailPage> {
  String? _selectedColor;
  bool _isCustomColor = false;
  final _customColorCtrl = TextEditingController();
  Map<String, int> _sizeQtys = {};
  List<String> _sizeChart = [];
  Set<String> _availableSizes = {};
  String? _lastCategory;
  int _qty = 1;
  bool _adding = false;
  ScaffoldMessengerState? _messenger;

  ChudaCustomizationOption? _selectedPatti;
  ChudaCustomizationOption? _selectedColorOpt;
  ChudaCustomizationOption? _selectedBox;
  String? _customColorText;
  final _customChudaColorCtrl = TextEditingController();
  double _customisationTotal = 0;
  bool _chudaDefaultsLoaded = false;
  bool _isCustomisationExpanded = false;

  @override
  void dispose() {
    _customColorCtrl.dispose();
    _customChudaColorCtrl.dispose();
    _clearSnackbars();
    super.dispose();
  }

  void _clearSnackbars() {
    _messenger?.clearSnackBars();
  }

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(itemByNumberProvider(widget.itemNumber));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemNumber),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            _clearSnackbars();
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
      ),
      body: itemAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: kMuted),
                const SizedBox(height: 16),
                Text('Could not load item', style: TextStyle(color: kMuted, fontSize: 16)),
                const SizedBox(height: 4),
                Text(CustomerErrorMessages.fromError(err), style: TextStyle(color: kMuted, fontSize: 13), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        data: (item) {
          if (item == null) {
            return const Center(child: Text('Item not found', style: TextStyle(color: kMuted)));
          }
          return _buildContent(item);
        },
      ),
    );
  }

  Widget _buildContent(dynamic item) {
    final hasSizes = item.hasSizes as bool;
    final hasColor = item.hasColor as bool;
    final unitPrice = (item.sellingPrice as num).toDouble();
    final tags = (item.tags as List).where((t) => t.toString().isNotEmpty).toList();
    final category = item.category as String;
    final isChuda = category.trim().toLowerCase() == 'chuda';
    if (_lastCategory != category) {
      _lastCategory = category;
      _chudaDefaultsLoaded = false;
      _isCustomisationExpanded = false;
      final cats = ref.read(activeCategoriesProvider).asData?.value ?? [];
      final cat = cats.where((c) => c.name == category).firstOrNull;
      _sizeChart = getSizeChartForCategory(cat ?? category);
      _sizeQtys = {for (final s in _sizeChart) s: 0};
      final raw = item.availableSizes as List?;
      if (raw != null) {
        _availableSizes = raw.map((e) => e.toString()).toSet();
      } else {
        _availableSizes = _sizeChart.toSet();
      }
    }

    if (isChuda && !_chudaDefaultsLoaded) {
      _customisationTotal = 0;
      _customColorText = null;
      _customChudaColorCtrl.clear();
      final pattiOpts = ref.read(chudaPattiOptionsProvider);
      final colorOpts = ref.read(chudaColorOptionsProvider);
      final boxOpts = ref.read(chudaBoxOptionsProvider);
      if (pattiOpts.isNotEmpty || colorOpts.isNotEmpty || boxOpts.isNotEmpty) {
        _selectedPatti = _findDefault(pattiOpts);
        _selectedColorOpt = _findDefault(colorOpts);
        _selectedBox = _findDefault(boxOpts);
        _updateCustomisationTotal();
        _chudaDefaultsLoaded = true;
      }
    }
    final finalUnitPrice = unitPrice + _customisationTotal;
    final totalQty = hasSizes
        ? _sizeQtys.values.fold(0, (a, b) => a + b)
        : _qty;
    final lineTotal = calculateLineTotal(
      CartItem(
        itemNumber: item.itemNumber,
        category: item.category,
        hasSizes: hasSizes,
        hasColor: hasColor,
        qty22: _sizeQtys['2.2'] ?? 0,
        qty24: _sizeQtys['2.4'] ?? 0,
        qty26: _sizeQtys['2.6'] ?? 0,
        qty28: _sizeQtys['2.8'] ?? 0,
        qty210: _sizeQtys['2.10'] ?? 0,
        qty212: _sizeQtys['2.12'] ?? 0,
        quantity: hasSizes ? 0 : _qty.toDouble(),
        unitPrice: finalUnitPrice,
      ),
      item.category,
      finalUnitPrice,
    );

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImage(item),
                const SizedBox(height: 16),
                _buildInfoCard(item, unitPrice, tags),
                if (hasColor && !isChuda) ...[
                  const SizedBox(height: 12),
                  _buildColorSection(),
                ],
                const SizedBox(height: 12),
                _buildQuantitySection(hasSizes),
                const SizedBox(height: 12),
                _buildSummaryCard(totalQty, lineTotal),
                if (isChuda) ...[
                  const SizedBox(height: 12),
                  _buildChudaCustomizationCollapsible(unitPrice),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        _buildBottomBar(item, hasSizes, hasColor, totalQty, lineTotal),
      ],
    );
  }

  Widget _buildImage(dynamic item) {
    final imageUrl = item.imageUrl as String? ?? '';
    return GestureDetector(
      onTap: imageUrl.isNotEmpty
          ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FullScreenImageViewer(imageUrl: imageUrl),
                ),
              )
          : null,
      child: AspectRatio(
        aspectRatio: ImagePolicy.productAspectRatio,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: imageUrl.isNotEmpty
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover, errorWidget: (_, __, ___) => _imageFallback(item.itemNumber)),
                    const WatermarkOverlay(),
                  ],
                )
              : _imageFallback(item.itemNumber),
        ),
      ),
    );
  }

  Widget _imageFallback(String label) {
    return Container(
      color: kMaroon,
      alignment: Alignment.center,
      child: Text(
        (label.isNotEmpty ? label[0] : '?').toUpperCase(),
        style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w300, color: Colors.white54),
      ),
    );
  }

  Widget _buildInfoCard(dynamic item, double unitPrice, List tags) {
    final cat = (item.category as String).replaceAll('_', ' ');
    final subcategory = item.subCategory as String?;
    final breadcrumb = subcategory != null && subcategory.isNotEmpty
        ? '$cat > $subcategory'
        : cat;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0D5C0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.itemNumber, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kDark)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kMaroon.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(breadcrumb, style: const TextStyle(fontSize: 11, color: kMaroon, fontWeight: FontWeight.w500)),
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: tags.map<Widget>((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kCream,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE0D5C0)),
                      ),
                      child: Text('$t', style: const TextStyle(fontSize: 10, color: kMuted)),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${unitPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
              const Text('/set', style: TextStyle(fontSize: 12, color: kMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0D5C0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Colour', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kDark)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedColor,
            decoration: InputDecoration(
              filled: true,
              fillColor: kCream,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
            hint: const Text('Select colour', style: TextStyle(fontSize: 14, color: kMuted)),
            isExpanded: true,
            items: kColorOptions.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
            onChanged: (v) {
              setState(() {
                _selectedColor = v;
                _isCustomColor = v == 'Custom';
                if (!_isCustomColor) _customColorCtrl.clear();
              });
            },
          ),
          if (_isCustomColor) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _customColorCtrl,
              decoration: InputDecoration(
                hintText: 'Enter custom colour',
                filled: true,
                fillColor: kCream,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChudaCustomizationCollapsible(double unitPrice) {
    return Consumer(builder: (context, ref, _) {
      final pattiOpts = ref.watch(chudaPattiOptionsProvider);
      final colorOpts = ref.watch(chudaColorOptionsProvider);
      final boxOpts = ref.watch(chudaBoxOptionsProvider);

      if (pattiOpts.isEmpty && colorOpts.isEmpty && boxOpts.isEmpty) {
        return const SizedBox.shrink();
      }

      if (!_chudaDefaultsLoaded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_chudaDefaultsLoaded) {
            setState(() {
              if (_selectedPatti == null) _selectedPatti = _findDefault(pattiOpts);
              if (_selectedColorOpt == null) _selectedColorOpt = _findDefault(colorOpts);
              if (_selectedBox == null) _selectedBox = _findDefault(boxOpts);
              _updateCustomisationTotal();
              _chudaDefaultsLoaded = true;
            });
          }
        });
      }

      final pattiLabel = _selectedPatti?.name ?? '';
      final colorLabel = _selectedColorOpt?.name ?? '';
      final boxLabel = _selectedBox?.name ?? '';
      final summaryParts = [pattiLabel, colorLabel, boxLabel].where((s) => s.isNotEmpty).toList();
      final isZeroDiff = _customisationTotal == 0;
      final finalPrice = unitPrice + _customisationTotal;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0D5C0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _isCustomisationExpanded = !_isCustomisationExpanded),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Text('Customize Chooda',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kDark)),
                    const Spacer(),
                    Icon(
                      _isCustomisationExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: kMaroon,
                    ),
                  ],
                ),
              ),
            ),
            if (!_isCustomisationExpanded && summaryParts.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Patti: ${summaryParts[0]}  •  Color: ${summaryParts.length > 1 ? summaryParts[1] : ''}  •  Box: ${summaryParts.length > 2 ? summaryParts[2] : ''}',
                  style: TextStyle(fontSize: 12, color: kMuted.withValues(alpha: 0.8))),
              Text(
                isZeroDiff ? 'Included' : 'Customisation: +₹${_customisationTotal.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isZeroDiff ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ),
            ],
            if (_isCustomisationExpanded) ...[
              const SizedBox(height: 4),
              Text('Select patti, color, and box type',
                  style: TextStyle(fontSize: 11, color: kMuted.withValues(alpha: 0.7))),
              const SizedBox(height: 12),
              if (pattiOpts.isNotEmpty) _buildChipGroup('Patti', pattiOpts, _selectedPatti,
                  (v) => setState(() { _selectedPatti = v; _updateCustomisationTotal(); })),
              if (colorOpts.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildChipGroup('Patti Color', colorOpts, _selectedColorOpt,
                    (v) => setState(() { _selectedColorOpt = v; if (v?.name != 'Custom') { _customColorText = null; _customChudaColorCtrl.clear(); } _updateCustomisationTotal(); })),
                if (_selectedColorOpt?.name == 'Custom') ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _customChudaColorCtrl,
                    decoration: InputDecoration(
                      hintText: 'Enter custom patti color',
                      filled: true,
                      fillColor: kCream,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (v) => _customColorText = v.trim().isEmpty ? null : v.trim(),
                  ),
                ],
              ],
              if (boxOpts.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildChipGroup('Box', boxOpts, _selectedBox,
                    (v) => setState(() { _selectedBox = v; _updateCustomisationTotal(); })),
              ],
              const SizedBox(height: 12),
              _buildCustomisationSummary(unitPrice, finalPrice),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildChipGroup(
    String label,
    List<ChudaCustomizationOption> options,
    ChudaCustomizationOption? selected,
    ValueChanged<ChudaCustomizationOption?> onSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kDark)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: options.map((opt) {
            final isSelected = selected?.id == opt.id;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    opt.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : kDark,
                    ),
                  ),
                  if (opt.priceDifference != 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      _priceLabel(opt.priceDifference),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? Colors.white.withValues(alpha: 0.85) : kMuted,
                      ),
                    ),
                  ],
                ],
              ),
              selected: isSelected,
              selectedColor: kMaroon,
              backgroundColor: kCream,
              side: BorderSide(color: isSelected ? kMaroon : const Color(0xFFE0D5C0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onSelected: (v) => onSelected(v ? opt : null),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomisationSummary(double basePrice, double finalPrice) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0D5C0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Base Price', style: TextStyle(fontSize: 13, color: kMuted)),
              Text('₹${basePrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kDark)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Customization', style: TextStyle(fontSize: 13, color: kMuted)),
              Text('+₹${_customisationTotal.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange.shade700)),
            ],
          ),
          const Divider(height: 12, color: Color(0xFFE0D5C0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Final Price', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kDark)),
              Text('₹${finalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
            ],
          ),
        ],
      ),
    );
  }

  void _updateCustomisationTotal() {
    final pattiDiff = _selectedPatti?.priceDifference ?? 0;
    final colorDiff = _selectedColorOpt?.priceDifference ?? 0;
    final boxDiff = _selectedBox?.priceDifference ?? 0;
    _customisationTotal = (pattiDiff + colorDiff + boxDiff).toDouble();
  }

  Widget _buildQuantitySection(bool hasSizes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0D5C0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hasSizes ? 'Select Quantity' : 'Quantity', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kDark)),
          const SizedBox(height: 12),
          if (hasSizes) ...[
            ..._sizeChart.map((sz) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _buildStepper(sz),
            )),
            if (_availableSizes.length != _sizeChart.length && _availableSizes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Sizes not listed are currently unavailable', style: TextStyle(fontSize: 11, color: kMuted.withValues(alpha: 0.7)),),
              ),
          ]
          else
            _buildStepper('Qty'),
        ],
      ),
    );
  }

  Widget _buildStepper(String label) {
    final isSize = label != 'Qty';
    final isAvailable = !isSize || _availableSizes.contains(label);
    final value = isSize ? (_sizeQtys[label] ?? 0) : _qty;

    void setValue(int v) {
      setState(() {
        if (v >= 0) {
          if (isSize) {
            _sizeQtys[label] = v;
          } else {
            _qty = v;
          }
        }
      });
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: isSize ? BoxDecoration(
        border: Border(bottom: BorderSide(color: isAvailable ? const Color(0xFFF0EBE0) : const Color(0xFFE0D5C0))),
      ) : null,
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isAvailable ? kDark : kMuted)),
          ),
          if (!isAvailable)
            Text('Not available', style: TextStyle(fontSize: 11, color: kMuted.withValues(alpha: 0.6)))
          else ...[
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              iconSize: 22,
              color: kMaroon,
              onPressed: () => setValue(value - 1),
            ),
            SizedBox(
              width: 32,
              child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              iconSize: 22,
              color: kMaroon,
              onPressed: () => setValue(value + 1),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int totalQty, double lineTotal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0D5C0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Sets', style: TextStyle(fontSize: 14, color: kMuted)),
              Text('$totalQty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kDark)),
            ],
          ),
          const Divider(height: 16, color: Color(0xFFE0D5C0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Estimated Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kDark)),
              Text('₹${lineTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Quantities can be updated before placing order', style: TextStyle(fontSize: 10, color: kMuted, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildBottomBar(dynamic item, bool hasSizes, bool hasColor, int totalQty, double lineTotal) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: const Color(0xFFE0D5C0))),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$totalQty sets', style: const TextStyle(fontSize: 13, color: kMuted, fontWeight: FontWeight.w500)),
                  Text('₹${lineTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
                ],
              ),
            ),
            Flexible(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _adding ? null : () => _addToCart(item),
                  icon: _adding
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.add_shopping_cart, size: 18),
                  label: Text(_adding ? 'Adding...' : 'Add to Cart'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kMaroon,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _ensureChudaDefaultsReady() async {
    if (_chudaDefaultsLoaded) return true;
    try {
      final all = await ref.read(chudaCustomizationOptionsProvider.future);
      final pattiOpts = all.where((o) => o.groupType == 'patti' && o.isActive).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final colorOpts = all.where((o) => o.groupType == 'color' && o.isActive).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final boxOpts = all.where((o) => o.groupType == 'box' && o.isActive).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      if (mounted) {
        setState(() {
          if (_selectedPatti == null) _selectedPatti = _findDefault(pattiOpts);
          if (_selectedColorOpt == null) _selectedColorOpt = _findDefault(colorOpts);
          if (_selectedBox == null) _selectedBox = _findDefault(boxOpts);
          _updateCustomisationTotal();
          _chudaDefaultsLoaded = true;
        });
      }
      return true;
    } catch (_) {
      if (mounted) {
        _showError('Could not load Chooda customisation options. Please try again.');
      }
      return false;
    }
  }

  Future<void> _addToCart(dynamic item) async {
    final hasSizes = item.hasSizes as bool;
    final hasColor = item.hasColor as bool;
    final basePrice = (item.sellingPrice as num).toDouble();
    final category = item.category as String? ?? '';
    final isChuda = category.trim().toLowerCase() == 'chuda';
    final unitPrice = basePrice + _customisationTotal;

    if (hasColor && !isChuda) {
      final color = _selectedColor;
      if (color == null || color.isEmpty) {
        _showError('Please select a colour');
        return;
      }
      if (color == 'Custom' && _customColorCtrl.text.trim().isEmpty) {
        _showError('Please enter a custom colour');
        return;
      }
    }

    if (isChuda) {
      setState(() => _adding = true);
      final ready = await _ensureChudaDefaultsReady();
      if (!ready) {
        setState(() => _adding = false);
        return;
      }
      if (_selectedPatti == null) {
        _showError('Please select a patti type');
        setState(() => _adding = false);
        return;
      }
      if (_selectedColorOpt == null) {
        _showError('Please select a patti color');
        setState(() => _adding = false);
        return;
      }
      if (_selectedColorOpt!.name == 'Custom' && (_customColorText == null || _customColorText!.isEmpty)) {
        _showError('Please enter a custom patti color');
        setState(() => _adding = false);
        return;
      }
      if (_selectedBox == null) {
        _showError('Please select a box type');
        setState(() => _adding = false);
        return;
      }
    }

    if (hasSizes) {
      final hasUnavailableQty = _sizeQtys.entries.any((e) => e.value > 0 && !_availableSizes.contains(e.key));
      if (hasUnavailableQty) {
        _showError('Selected size is not available');
        return;
      }
      final total = _sizeQtys.values.fold(0, (a, b) => a + b);
      if (total <= 0) {
        _showError('Please enter quantity for at least one size');
        return;
      }
    } else if (_qty < 1) {
      _showError('Quantity must be at least 1');
      return;
    }

    final colorValue = _selectedColor == 'Custom'
        ? _customColorCtrl.text.trim()
        : _selectedColor;

    ChudaCustomizationSnapshot? customization;
    if (isChuda) {
      final pattiDiff = (_selectedPatti?.priceDifference ?? 0).toDouble();
      final colorDiff = (_selectedColorOpt?.priceDifference ?? 0).toDouble();
      final boxDiff = (_selectedBox?.priceDifference ?? 0).toDouble();
      customization = ChudaCustomizationSnapshot(
        pattiName: _selectedPatti!.name,
        pattiPriceDiff: pattiDiff,
        colorName: _selectedColorOpt!.name,
        colorPriceDiff: colorDiff,
        customColorText: _selectedColorOpt!.name == 'Custom' ? _customColorText : null,
        boxName: _selectedBox!.name,
        boxPriceDiff: boxDiff,
        totalDifference: pattiDiff + colorDiff + boxDiff,
      );
    } else {
      customization = null;
    }

    final cartItem = CartItem(
      itemNumber: item.itemNumber,
      category: item.category,
      hasSizes: hasSizes,
      hasColor: hasColor,
      qty22: _sizeQtys['2.2'] ?? 0,
      qty24: _sizeQtys['2.4'] ?? 0,
      qty26: _sizeQtys['2.6'] ?? 0,
      qty28: _sizeQtys['2.8'] ?? 0,
      qty210: _sizeQtys['2.10'] ?? 0,
      qty212: _sizeQtys['2.12'] ?? 0,
      quantity: hasSizes ? 0 : _qty.toDouble(),
      color: !isChuda ? colorValue : null,
      unitPrice: unitPrice,
      customization: customization,
    );

    if (!isChuda) setState(() => _adding = true);

    final result = ref.read(cartProvider.notifier).addItem(cartItem, item.category);

    setState(() => _adding = false);

    if (result is CartAddSuccess) {
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final router = GoRouter.of(context);
      _messenger = messenger;
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: result.merged
              ? Text('${item.itemNumber} — quantity updated in cart')
              : Text('${item.itemNumber} — added to cart'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2E7D32),
          margin: const EdgeInsets.only(bottom: 88, left: 12, right: 12),
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () {
              _clearSnackbars();
              router.push('/cart');
            },
          ),
        ),
      );
    } else if (result is CartValidationError) {
      _showError(result.message);
    } else if (result is CartMutationError) {
      _showError(result.message);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    _messenger = ScaffoldMessenger.of(context);
    _clearSnackbars();
    _messenger!.showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade700,
      ),
            );
    }
  }
class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 5.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: Colors.white54),
                ),
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
                ),
              ),
            ),
          ),
          const WatermarkOverlay(),
        ],
      ),
    );
  }
}

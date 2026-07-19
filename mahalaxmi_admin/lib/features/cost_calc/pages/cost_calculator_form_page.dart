import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mahalaxmi_shared/constants/material_config.dart';
import 'package:mahalaxmi_shared/models/cost_calculation.dart';
import 'package:mahalaxmi_shared/models/item.dart';
import 'package:mahalaxmi_shared/providers/categories_provider.dart';
import 'package:mahalaxmi_shared/providers/repository_providers.dart';
import 'package:mahalaxmi_shared/providers/session_provider.dart';

import '../providers/cost_calculations_provider.dart';
import '../providers/material_settings_provider.dart';
import '../widgets/manual_qty_tile.dart';
import '../widgets/preset_chips_tile.dart';
import '../widgets/qty_card_tile.dart';
import '../widgets/qty_picker_tile.dart';
import '../widgets/qty_slider_tile.dart';
import '../widgets/toggle_choice_tile.dart';

class _SelectedItem {
  final String label;
  final double price;
  final double qty;
  final double total;
  _SelectedItem({
    required this.label,
    required this.price,
    required this.qty,
    required this.total,
  });
}

class _MaterialTotal {
  final double costPrice;
  final double sellingPrice;
  _MaterialTotal({required this.costPrice, required this.sellingPrice});
}

class _MaterialState {
  double price;
  double qty;
  bool selected;
  String? selectedToggle;

  _MaterialState({
    this.price = 0,
    this.qty = 1,
    this.selected = false,
  });
}

class CostCalculatorFormPage extends ConsumerStatefulWidget {
  final String initialItemName;
  final String? recordId;
  final String? initialCategory;
  final String? initialItemNumber;

  const CostCalculatorFormPage({
    super.key,
    required this.initialItemName,
    this.recordId,
    this.initialCategory,
    this.initialItemNumber,
  });

  @override
  ConsumerState<CostCalculatorFormPage> createState() =>
      _CostCalculatorFormPageState();
}

class _CostCalculatorFormPageState
    extends ConsumerState<CostCalculatorFormPage> {
  late final TextEditingController _nameController;
  final Map<String, _MaterialState> _materials = {};
  bool _saving = false;
  Map<String, dynamic> _currentSettings = {};
  bool _includeMisc = false;
  int _currentStep = 0;
  String? _selectedCategory;
  String? _selectedSubCategory;
  List<String> _subCategoryOptions = [];
  CostCalculation? _existingRecord;
  String? _selectedItemNumber;
  String? _selectedItemImageUrl;
  List<RateItem> _searchResults = [];
  bool _isSearching = false;
  bool _itemSelected = false;

  static const _steps = [
    'Item Name',
    'Kadda',
    'Chudi',
    'Nihar',
    'Patti',
    'Box & Bangdi',
    'Misc Items',
    'Summary',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialItemName);
    _nameController.addListener(_onNameChanged);
    _selectedItemNumber = widget.initialItemNumber;
    _initMaterials();
  }

  void _onNameChanged() {
    if (_currentStep == 0 && !_itemSelected) setState(() {});
  }

  Future<void> _searchItems(String query) async {
    if (query.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final repo = ref.read(itemRepositoryProvider);
      final allItems = await repo.getAllItems();
      final q = query.trim().toLowerCase();
      setState(() {
        _searchResults = allItems.where((item) {
          return item.itemNumber.toLowerCase().contains(q) ||
              item.category.toLowerCase().contains(q) ||
              (item.subCategory?.toLowerCase().contains(q) ?? false) ||
              item.tags.any((t) => t.toLowerCase().contains(q));
        }).take(20).toList();
        _isSearching = false;
      });
    } catch (_) {
      setState(() => _isSearching = false);
    }
  }

  void _selectItem(RateItem item) {
    setState(() {
      _itemSelected = true;
      _selectedItemNumber = item.itemNumber;
      _selectedItemImageUrl = item.imageUrl;
      _nameController.text = item.itemNumber;
      _selectedCategory = item.category;
      _selectedSubCategory = item.subCategory;
      if (_selectedCategory != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final cats = ref.read(activeCategoriesProvider).valueOrNull ?? [];
          try {
            final cat = cats.firstWhere((c) => c.name == _selectedCategory);
            _subCategoryOptions = cat.subCategoryList;
          } catch (_) {}
          if (mounted) setState(() {});
        });
      }
      _searchResults = [];
    });
  }

  Future<void> _quickCreateItem() async {
    final itemName = _nameController.text.trim();
    if (itemName.isEmpty) return;

    final categories = ref.read(activeCategoriesProvider).valueOrNull ?? [];
    final initialCategory = _selectedCategory ?? widget.initialCategory ?? '';

    String? chosenCategory;
    if (initialCategory.isNotEmpty) {
      chosenCategory = initialCategory;
    } else if (categories.isNotEmpty) {
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
      chosenCategory = result;
    }

    if (chosenCategory == null || chosenCategory.isEmpty) return;

    try {
      final repo = ref.read(itemRepositoryProvider);
      await repo.addRateItem({
        'item_number': itemName,
        'category': chosenCategory,
        'selling_price': 0,
        'cost_price': 0,
        'is_available': true,
        'available_sizes': [],
      });
      if (!mounted) return;
      _loadItemByNumber(itemName);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created "$itemName" in $chosenCategory')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create item: $e')),
      );
    }
  }

  void _initMaterials() {
    for (final config in materialConfigs) {
      _materials[config.id] = _MaterialState(
        price: 0,
        qty: config.defaultQty,
        selected: false,
      );
    }
    if (widget.recordId == null) {
      _materials['nihar']!.selected = true;
      _materials['box']!.price = 90;
      final patti = _materials['patti']!;
      patti.selected = true;
      patti.selectedToggle = 'gol';
      _selectedCategory = widget.initialCategory;
      if (widget.initialItemNumber != null) {
        _loadItemByNumber(widget.initialItemNumber!);
      }
    } else {
      _loadExistingRecord();
    }
  }

  Future<void> _loadItemByNumber(String itemNumber) async {
    try {
      final repo = ref.read(itemRepositoryProvider);
      final item = await repo.getItemByNumber(itemNumber);
      if (item != null && mounted) {
        _selectItem(item);
      }
    } catch (_) {}
  }

  Future<void> _loadExistingRecord() async {
    try {
      final repo = ref.read(costCalculationsRepositoryProvider);
      final record = await repo.getById(widget.recordId!);
      if (record == null || !mounted) return;
      _existingRecord = record;
      _selectedCategory = record.category;
      _selectedSubCategory = record.subCategory;
      _nameController.text = record.itemName;
      _selectedItemNumber = record.itemNumber;
      _itemSelected = record.itemNumber != null;

      for (final config in materialConfigs) {
        final state = _materials[config.id]!;
        if (config.shape == MaterialShape.toggleChoice) {
          for (final opt in config.toggleOptions!) {
            final key = '${config.id}_${opt.id}';
            if (record.materials.containsKey(key)) {
              state.selected = true;
              state.selectedToggle = opt.id;
              if (config.group != null) _includeMisc = true;
              break;
            }
          }
        } else {
          if (record.materials.containsKey(config.id)) {
            final entry = record.materials[config.id] as Map<String, dynamic>;
            state.selected = true;
            state.price = (entry['price'] as num).toDouble();
            state.qty = (entry['qty'] as num).toDouble();
            if (config.group != null) _includeMisc = true;
          }
        }
      }
      setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  double _settingsValue(String key) {
    final val = _currentSettings[key];
    if (val is num) return val.toDouble();
    return 0;
  }

  double _priceForConfig(MaterialConfig config, _MaterialState state) {
    if (config.shape == MaterialShape.toggleChoice &&
        state.selectedToggle != null) {
      final opt = config.toggleOptions!
          .firstWhere((o) => o.id == state.selectedToggle);
      return _settingsValue(opt.settingsKey);
    }
    if (config.hasFixedPrice) {
      return _settingsValue(config.settingsKey!);
    }
    return state.price;
  }

  bool _isSelected(MaterialConfig config, _MaterialState state) {
    if (config.shape == MaterialShape.toggleChoice) {
      return state.selectedToggle != null;
    }
    if (config.hasFixedPrice) {
      return state.selected;
    }
    return state.price > 0;
  }

  double _computeTotal() {
    double total = 0;
    for (final config in materialConfigs) {
      final state = _materials[config.id]!;
      if (_isSelected(config, state)) {
        total += _priceForConfig(config, state) * state.qty;
      }
    }
    return total;
  }

  Map<String, dynamic> _buildMaterialsMap() {
    final map = <String, dynamic>{};
    for (final config in materialConfigs) {
      final state = _materials[config.id]!;
      if (config.shape == MaterialShape.toggleChoice) {
        if (state.selectedToggle != null) {
          final key = '${config.id}_${state.selectedToggle}';
          map[key] = {
            'price': _priceForConfig(config, state),
            'qty': 1,
          };
        }
      } else if (_isSelected(config, state)) {
        map[config.id] = {
          'price': _priceForConfig(config, state),
          'qty': state.qty,
        };
      }
    }
    return map;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_nameController.text.trim().isEmpty) return;
    if (_selectedCategory == null || _selectedCategory!.isEmpty) return;

    setState(() => _saving = true);

    try {
      final session = ref.read(appSessionProvider);
      final username = session.username ?? 'admin';
      final calcRepo = ref.read(costCalculationsRepositoryProvider);
      final itemRepo = ref.read(itemRepositoryProvider);
      final materials = _buildMaterialsMap();
      final total = _computeTotal();

      if (_existingRecord != null) {
        final updated = _existingRecord!.copyWith(
          itemName: _nameController.text.trim(),
          itemNumber: _selectedItemNumber,
          category: _selectedCategory ?? '',
          subCategory: _selectedSubCategory,
          materials: materials,
          totalCost: total,
          updatedBy: username,
          updatedAt: DateTime.now(),
        );
        await calcRepo.update(updated);
      } else {
        await calcRepo.create(CostCalculation(
          itemName: _nameController.text.trim(),
          itemNumber: _selectedItemNumber,
          category: _selectedCategory ?? '',
          subCategory: _selectedSubCategory,
          materials: materials,
          totalCost: total,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: username,
          updatedBy: username,
        ));
      }

      if (_selectedItemNumber != null && total > 0) {
        try {
          await itemRepo.updateRateItem(_selectedItemNumber!, {
            'cost_price': total,
          });
        } catch (_) {}
      }

      if (!mounted) return;
      ref.invalidate(costCalculationsProvider);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatQty(double val) {
    if (val == val.roundToDouble()) return val.toInt().toString();
    return val.toStringAsFixed(1);
  }

  List<_SelectedItem> _selectedItems() {
    final items = <_SelectedItem>[];
    for (final config in materialConfigs) {
      final state = _materials[config.id]!;
      if (!_isSelected(config, state)) continue;
      final price = _priceForConfig(config, state);
      final qty = state.qty;
      items.add(_SelectedItem(
        label: config.displayName,
        price: price,
        qty: qty,
        total: price * qty,
      ));
    }
    return items;
  }

  Widget _buildTile(MaterialConfig config, _MaterialState state) {
    final isSelected = _isSelected(config, state);

    switch (config.shape) {
      case MaterialShape.qtyCards:
        return QtyCardTile(
          config: config,
          price: state.price,
          qty: state.qty,
          selected: isSelected,
          onPriceChanged: (p) {
            state.price = p;
            setState(() {});
          },
          onQtyChanged: (q) {
            state.qty = q;
            setState(() {});
          },
        );

      case MaterialShape.qtySlider:
        final showPriceField = !config.hasFixedPrice;
        return QtySliderTile(
          config: config,
          price: _priceForConfig(config, state),
          qty: state.qty,
          selected: isSelected,
          showPriceField: showPriceField,
          onPriceChanged: (p) {
            state.price = p;
            setState(() {});
          },
          onQtyChanged: (q) {
            state.qty = q;
            setState(() {});
          },
          onToggle: config.hasFixedPrice
              ? () {
                  state.selected = !state.selected;
                  if (state.selected) {
                    state.qty = config.defaultQty;
                  }
                  setState(() {});
                }
              : null,
        );

      case MaterialShape.toggleChoice:
        return ToggleChoiceTile(
          config: config,
          settings: _currentSettings,
          selectedToggleId: state.selectedToggle,
          onToggleChanged: (id) {
            state.selectedToggle = state.selectedToggle == id ? null : id;
            setState(() {});
          },
        );

      case MaterialShape.presetChips:
        return PresetChipsTile(
          config: config,
          price: state.price,
          selected: isSelected,
          onPriceChanged: (p) {
            state.price = p;
            setState(() {});
          },
        );

      case MaterialShape.qtyPicker:
        return QtyPickerTile(
          config: config,
          price: state.price,
          qty: state.qty,
          selected: isSelected,
          onPriceChanged: (p) {
            state.price = p;
            setState(() {});
          },
          onQtyChanged: (q) {
            state.qty = q;
            setState(() {});
          },
        );

      case MaterialShape.manualQty:
        return ManualQtyTile(
          config: config,
          price: state.price,
          qty: state.qty,
          selected: isSelected,
          onPriceChanged: (p) {
            state.price = p;
            setState(() {});
          },
          onQtyChanged: (q) {
            state.qty = q;
            setState(() {});
          },
        );
    }
  }

  bool _canGoNext() {
    if (_currentStep == 0) {
      return _itemSelected &&
          _selectedCategory != null &&
          _selectedCategory!.isNotEmpty;
    }
    return true;
  }

  Widget _buildProgressBar() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Step ${_currentStep + 1} of ${_steps.length}',
            style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_steps.length, (i) {
              final isActive = i == _currentStep;
              final isDone = i < _currentStep;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isDone || isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  if (i < _steps.length - 1)
                    Container(
                      width: 16,
                      height: 2,
                      color: isDone
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final theme = Theme.of(context);
    final isFirst = _currentStep == 0;
    final isLast = _currentStep == _steps.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          if (!isFirst)
            OutlinedButton.icon(
              onPressed: () => setState(() => _currentStep--),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back'),
            ),
          if (!isFirst) const Spacer(),
          if (isLast)
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save, size: 18),
              label: Text(_saving ? 'Saving...' : 'Save'),
            )
          else
            FilledButton.icon(
              onPressed: _canGoNext()
                  ? () => setState(() => _currentStep++)
                  : null,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Next'),
            ),
        ],
      ),
    );
  }

  Widget _buildItemNameStep() {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(activeCategoriesProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        children: [
          Icon(Icons.edit_note, size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: 20),
          Text('Select an item from catalogue',
              style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Search by item number, category, or tag',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline)),
          const SizedBox(height: 28),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: _itemSelected ? 'Selected Item' : 'Search Items',
              hintText: _itemSelected
                  ? _selectedItemNumber ?? ''
                  : 'Type at least 2 characters...',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              filled: true,
              prefixIcon: _itemSelected
                  ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                  : const Icon(Icons.search),
              suffixIcon: _itemSelected
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _itemSelected = false;
                          _selectedItemNumber = null;
                          _selectedItemImageUrl = null;
                          _nameController.clear();
                          _selectedCategory = widget.initialCategory;
                          _selectedSubCategory = null;
                          _subCategoryOptions = [];
                        });
                      },
                    )
                  : null,
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.none,
            onChanged: (val) {
              if (!_itemSelected) _searchItems(val);
            },
          ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
          if (!_itemSelected && _searchResults.isNotEmpty)
            SizedBox(
              height: 240,
              child: ListView.separated(
                padding: const EdgeInsets.only(top: 12),
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _searchResults[index];
                  return ListTile(
                    dense: true,
                    leading: item.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              item.imageUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.inventory_2,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          )
                        : Icon(Icons.inventory_2,
                            color: theme.colorScheme.outline),
                    title: Text(item.itemNumber,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(
                      item.category.replaceAll('_', ' ') +
                          (item.subCategory != null
                              ? ' / ${item.subCategory!.replaceAll('_', ' ')}'
                              : ''),
                      style: TextStyle(
                          fontSize: 12, color: theme.colorScheme.outline),
                    ),
                    trailing: Text(
                      '\u20B9${item.costPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary),
                    ),
                    onTap: () => _selectItem(item),
                  );
                },
              ),
            ),
          if (!_itemSelected && !_isSearching &&
              _nameController.text.length >= 2 && _searchResults.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 48,
                      color: theme.colorScheme.outline),
                  const SizedBox(height: 8),
                  Text("No items found for '${_nameController.text}'",
                      style: TextStyle(color: theme.colorScheme.outline)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _quickCreateItem(),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: Text('Create "${_nameController.text}" in catalogue'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          if (_itemSelected) ...[
            categoriesAsync.when(
              data: (categories) {
                if (_selectedCategory != null && _subCategoryOptions.isEmpty) {
                  try {
                    final cat = categories.firstWhere(
                        (c) => c.name == _selectedCategory);
                    _subCategoryOptions = cat.subCategoryList;
                  } catch (_) {}
                }
                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                      ),
                      items: categories
                          .map((cat) => DropdownMenuItem(
                                value: cat.name,
                                child: Text(cat.name),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategory = val;
                          _selectedSubCategory = null;
                          final cat = categories.firstWhere(
                              (c) => c.name == val);
                          _subCategoryOptions = cat.subCategoryList;
                        });
                      },
                    ),
                    if (_subCategoryOptions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _subCategoryOptions.contains(_selectedSubCategory)
                            ? _selectedSubCategory
                            : null,
                        decoration: InputDecoration(
                          labelText: 'Sub Category',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          filled: true,
                        ),
                        items: _subCategoryOptions
                            .map((sc) => DropdownMenuItem(
                                  value: sc,
                                  child: Text(sc),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() => _selectedSubCategory = val);
                        },
                      ),
                    ],
                  ],
                );
              },
              loading: () => const SizedBox(
                height: 56,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text(
                'Failed to load categories',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSingleMaterialStep(String materialId) {
    final config = materialConfigs.firstWhere((c) => c.id == materialId);
    final state = _materials[materialId]!;
    final theme = Theme.of(context);

    return Padding(
      key: ValueKey('step_$materialId'),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Spacer(flex: 1),
          Icon(config.hasFixedPrice
              ? Icons.toggle_on_outlined
              : Icons.currency_rupee,
              size: 56, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(config.displayName, style: theme.textTheme.titleLarge),
          if (!config.hasFixedPrice)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Set price or leave at \u20B90 to skip',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline)),
            ),
          if (config.hasFixedPrice)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Tap to select / deselect',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline)),
            ),
          const SizedBox(height: 24),
          _buildTile(config, state),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildBoxBangdiStep() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      key: const ValueKey('step_box_bangdi'),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
      child: Column(
        children: [
          Icon(Icons.inventory_2, size: 56, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text('Box & Bangdi', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Configure packaging and bangles',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline)),
          const SizedBox(height: 24),
          _buildTile(
            materialConfigs.firstWhere((c) => c.id == 'box'),
            _materials['box']!,
          ),
          const SizedBox(height: 12),
          _buildTile(
            materialConfigs.firstWhere((c) => c.id == 'bangdi'),
            _materials['bangdi']!,
          ),
        ],
      ),
    );
  }

  Widget _buildMiscItemsStep() {
    final theme = Theme.of(context);

    return Column(
      key: const ValueKey('step_misc'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Column(
            children: [
              Icon(Icons.category, size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text('Include misc materials?',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('No')),
                  ButtonSegment(value: true, label: Text('Yes')),
                ],
                selected: {_includeMisc},
                onSelectionChanged: (v) {
                  setState(() {
                    if (!v.first) {
                      for (final config in materialConfigs) {
                        if (config.group != null) {
                          _materials[config.id]?.selected = false;
                        }
                      }
                    }
                    _includeMisc = v.first;
                  });
                },
              ),
            ],
          ),
        ),
        if (_includeMisc)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
              children: () {
                final tiles = <Widget>[];
                String? currentGroup;
                for (final config in materialConfigs) {
                  if (config.group == null) continue;
                  if (config.group != currentGroup) {
                    tiles.add(
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(config.group!,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.outline)),
                      ),
                    );
                    currentGroup = config.group;
                  }
                  tiles.add(_buildTile(config, _materials[config.id]!));
                }
                return tiles;
              }(),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryStep() {
    final theme = Theme.of(context);
    final items = _selectedItems();
    final total = _computeTotal();

    return Padding(
      key: const ValueKey('step_summary'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Column(
              children: [
                Icon(Icons.receipt_long, size: 48,
                    color: theme.colorScheme.primary),
                const SizedBox(height: 8),
                Text(_nameController.text.trim(),
                    style: theme.textTheme.titleLarge),
                if (_selectedItemNumber != null)
                  Text(_selectedItemNumber!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline)),
                const SizedBox(height: 4),
                Text(
                  (_selectedCategory ?? '') +
                      (_selectedSubCategory != null
                          ? ' / $_selectedSubCategory'
                          : ''),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text('No materials selected',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: theme.colorScheme.outline)),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(item.label,
                                  style: const TextStyle(fontSize: 15)),
                            ),
                            Text(
                              '${_formatQty(item.qty)} \u00D7 \u20B9${item.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.outline),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 72,
                              child: Text('\u20B9${item.total.toStringAsFixed(0)}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (items.isNotEmpty) ...[
            const Divider(thickness: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Total',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  Text('\u20B9${total.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: theme.colorScheme.primary)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildItemNameStep();
      case 1:
        return _buildSingleMaterialStep('kadda');
      case 2:
        return _buildSingleMaterialStep('chudi');
      case 3:
        return _buildSingleMaterialStep('nihar');
      case 4:
        return _buildSingleMaterialStep('patti');
      case 5:
        return _buildBoxBangdiStep();
      case 6:
        return _buildMiscItemsStep();
      case 7:
        return _buildSummaryStep();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(materialSettingsProvider);
    _currentSettings = settingsAsync.valueOrNull ?? {};
    final total = _computeTotal();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recordId != null ? 'Edit Calculation' : 'New Calculation'),
        actions: [
          if (_currentStep > 0 && _currentStep < _steps.length - 1)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text('\u20B9${total.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary)),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          const Divider(height: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                    opacity: animation, child: child);
              },
              child: KeyedSubtree(
                key: ValueKey('step_$_currentStep'),
                child: _buildStepContent(),
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }
}

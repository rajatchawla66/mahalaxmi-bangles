import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mahalaxmi_shared/constants/size_charts.dart';
import 'package:mahalaxmi_shared/models/category.dart';
import 'package:mahalaxmi_shared/models/cutmail.dart';
import 'package:mahalaxmi_shared/models/cutmail_size.dart';
import 'package:mahalaxmi_shared/models/item.dart';
import 'package:mahalaxmi_shared/providers/categories_provider.dart';
import 'package:mahalaxmi_shared/providers/items_provider.dart';
import 'package:mahalaxmi_shared/providers/repository_providers.dart';
import 'package:mahalaxmi_shared/providers/session_provider.dart';

class AddCutmailPage extends ConsumerStatefulWidget {
  const AddCutmailPage({super.key});

  @override
  ConsumerState<AddCutmailPage> createState() => _AddCutmailPageState();
}

class _AddCutmailPageState extends ConsumerState<AddCutmailPage> {
  String? _selectedCategory;
  RateItem? _selectedItem;
  final Map<String, TextEditingController> _qtyControllers = {};
  final TextEditingController _noteController = TextEditingController();
  bool _submitting = false;

  static const _defaultCategory = 'Metal_Bangles';

  @override
  void initState() {
    super.initState();
    _selectedCategory = _defaultCategory;
  }

  @override
  void dispose() {
    _noteController.dispose();
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onCategoryChanged(String? category) {
    if (category == _selectedCategory) return;
    setState(() {
      _selectedCategory = category;
      _selectedItem = null;
      _qtyControllers.clear();
    });
  }

  void _onItemSelected(RateItem? item) {
    setState(() {
      _selectedItem = item;
      _qtyControllers.clear();
    });
    if (item != null) {
      _initSizeControllers();
    }
  }

  void _initSizeControllers() {
    final catName = _selectedCategory ?? '';
    final sizes = normalizeAvailableSizes(catName, _selectedItem?.availableSizes);
    for (final size in sizes) {
      _qtyControllers[size] = TextEditingController(text: '0');
    }
  }

  List<String> _getSizes() {
    if (_selectedCategory == null) return [];
    return normalizeAvailableSizes(_selectedCategory!, _selectedItem?.availableSizes);
  }

  Future<void> _submit() async {
    if (_selectedCategory == null) {
      _showError('Please select a category');
      return;
    }
    if (_selectedItem == null) {
      _showError('Please select an item');
      return;
    }

    final sizes = _getSizes();
    if (sizes.isEmpty) {
      _showError('No sizes available for this category');
      return;
    }

    final sizeEntries = <CutmailSize>[];
    var hasAnyQty = false;
    for (final size in sizes) {
      final controller = _qtyControllers[size];
      final qtyText = controller?.text.trim() ?? '0';
      final qty = int.tryParse(qtyText) ?? 0;
      if (qty < 0) {
        _showError('Quantity for size $size cannot be negative');
        return;
      }
      if (qty > 0) hasAnyQty = true;
      sizeEntries.add(CutmailSize(
        size: size,
        availableQty: qty,
        isAvailable: qty > 0,
      ));
    }

    if (!hasAnyQty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('All quantities are 0'),
          content: const Text('All sizes have quantity 0. Submit anyway?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _submitting = true);

    try {
      final session = ref.read(appSessionProvider);
      final cutmail = Cutmail(
        categoryName: _selectedCategory!,
        itemId: _selectedItem!.itemNumber,
        itemNameSnapshot: _selectedItem!.itemNumber,
        itemNumberSnapshot: _selectedItem!.itemNumber,
        imageUrlSnapshot: _selectedItem!.imageUrl.isNotEmpty ? _selectedItem!.imageUrl : null,
        checkedByName: session.isLabour ? 'Labour' : null,
      );

      await ref.read(cutmailRepositoryProvider).createCutmail(cutmail, sizeEntries);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cutmail submitted successfully'), behavior: SnackBarBehavior.floating),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to submit: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final itemsAsync = _selectedCategory != null
        ? ref.watch(availableItemsByCategoryProvider(_selectedCategory!))
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Cutmail')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            categoriesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => Text('Error: $err'),
              data: (categories) => _buildCategorySelector(categories),
            ),
            const SizedBox(height: 20),
            if (_selectedCategory != null) ...[
              const Text('Item', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              itemsAsync!.when(
                loading: () => const LinearProgressIndicator(),
                error: (err, _) => Text('Error: $err'),
                data: (items) => _buildItemSelector(items),
              ),
            ],
            if (_selectedItem != null) ...[
              const SizedBox(height: 16),
              _buildItemPreview(),
              const SizedBox(height: 20),
              const Text('Size-wise Quantities', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              _buildSizeFields(),
              const SizedBox(height: 20),
              const Text('Note (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Add a note...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check),
                label: Text(_submitting ? 'Submitting...' : 'Submit Cutmail'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(List<Category> categories) {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      items: categories.map((cat) {
        return DropdownMenuItem(
          value: cat.name,
          child: Text(cat.name.replaceAll('_', ' ')),
        );
      }).toList(),
      onChanged: _onCategoryChanged,
    );
  }

  Widget _buildItemSelector(List<RateItem> items) {
    final filtered = items.where((i) => i.isAvailable).toList();
    if (filtered.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No available items in this category'),
        ),
      );
    }
    return DropdownButtonFormField<String>(
      value: _selectedItem?.itemNumber,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      hint: const Text('Select item'),
      items: filtered.map((item) {
        final label = item.itemNumber +
            (item.subCategory != null && item.subCategory!.isNotEmpty
                ? ' - ${item.subCategory}'
                : '');
        return DropdownMenuItem(
          value: item.itemNumber,
          child: Text(label, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (itemNumber) {
        final item = filtered.where((i) => i.itemNumber == itemNumber).firstOrNull;
        _onItemSelected(item);
      },
    );
  }

  Widget _buildItemPreview() {
    final item = _selectedItem;
    if (item == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (item.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 64,
                    height: 64,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
              )
            else
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image, color: Colors.grey),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.itemNumber,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  if (item.subCategory != null && item.subCategory!.isNotEmpty)
                    Text(item.subCategory!, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  Text(item.category.replaceAll('_', ' '),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeFields() {
    final sizes = _getSizes();
    if (sizes.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No sizes available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: sizes.map((size) {
            _qtyControllers.putIfAbsent(size, () => TextEditingController(text: '0'));
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(size,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                  const Text('×', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _qtyControllers[size],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: '0',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '${_qtyControllers[size]?.text == '' ? 0 : int.tryParse(_qtyControllers[size]?.text ?? '0') ?? 0} pcs',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

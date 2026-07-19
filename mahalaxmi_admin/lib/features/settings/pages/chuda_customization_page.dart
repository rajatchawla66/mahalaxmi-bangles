import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahalaxmi_shared/mahalaxmi_shared.dart';

final _allOptionsProvider =
    FutureProvider<List<ChudaCustomizationOption>>((ref) async {
  final repo = ref.read(chudaCustomizationRepositoryProvider);
  return await repo.getAllOptions();
});

const _groupLabels = {
  'patti': 'Patti Options',
  'color': 'Patti Color Options',
  'box': 'Box Options',
};

const _groupOrder = ['patti', 'color', 'box'];

String _priceLabel(double diff) {
  if (diff == 0) return 'Included';
  if (diff > 0) return '+₹${diff.toStringAsFixed(0)}';
  return '-₹${diff.abs().toStringAsFixed(0)}';
}

class ChudaCustomizationPage extends ConsumerStatefulWidget {
  const ChudaCustomizationPage({super.key});

  @override
  ConsumerState<ChudaCustomizationPage> createState() =>
      _ChudaCustomizationPageState();
}

class _ChudaCustomizationPageState
    extends ConsumerState<ChudaCustomizationPage> {
  @override
  Widget build(BuildContext context) {
    final optionsAsync = ref.watch(_allOptionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chuda Customisation')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOption(),
        icon: const Icon(Icons.add),
        label: const Text('Add Option'),
      ),
      body: optionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text('$e', textAlign: TextAlign.center),
            ],
          ),
        ),
        data: (options) {
          if (options.isEmpty) {
            return const Center(
              child: Text('No options yet. Tap + to add one.',
                  style: TextStyle(color: Colors.grey)),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(_allOptionsProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final group in _groupOrder)
                  _buildGroupSection(options, group),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupSection(
      List<ChudaCustomizationOption> options, String group) {
    final groupOptions =
        options.where((o) => o.groupType == group).toList();
    if (groupOptions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            _groupLabels[group] ?? group,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF800000),
            ),
          ),
        ),
        ...groupOptions.map((opt) => _OptionCard(
              option: opt,
              onEdit: () => _editOption(opt),
              onSetDefault: opt.isDefault
                  ? null
                  : () => _setDefault(opt.groupType, opt.id),
              onToggleActive: () => _toggleActive(opt),
            )),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _addOption() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final sortCtrl = TextEditingController();
    bool isDefault = false;
    bool isActive = true;
    String? selectedGroup;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Option'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedGroup,
                    decoration: const InputDecoration(labelText: 'Group Type'),
                    items: const [
                      DropdownMenuItem(value: 'patti', child: Text('Patti')),
                      DropdownMenuItem(
                          value: 'color', child: Text('Patti Color')),
                      DropdownMenuItem(value: 'box', child: Text('Box')),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => selectedGroup = v),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Price Difference',
                      hintText: '0, 20, -10',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true, signed: true),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: sortCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Sort Order',
                      hintText: '10, 20, 30...',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Is Default', style: TextStyle(fontSize: 14)),
                    value: isDefault,
                    onChanged: (v) => setDialogState(() => isDefault = v ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  if (isDefault)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Default option must have price difference ₹0',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                      ),
                    ),
                  CheckboxListTile(
                    title: const Text('Is Active', style: TextStyle(fontSize: 14)),
                    value: isActive,
                    onChanged: (v) => setDialogState(() => isActive = v ?? true),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (selectedGroup == null || nameCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text('Group and name are required'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.red),
                  );
                  return;
                }
                final price =
                    double.tryParse(priceCtrl.text.trim()) ?? 0;
                if (isDefault && price != 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Default option must have price difference ₹0'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.red),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
    final sort = int.tryParse(sortCtrl.text.trim()) ?? 0;

    try {
      final repo = ref.read(chudaCustomizationRepositoryProvider);
      if (isDefault) {
        await repo.setDefaultOption(selectedGroup!, 0);
      }
      await repo.createOption({
        'group_type': selectedGroup,
        'name': nameCtrl.text.trim(),
        'price_difference': price,
        'is_default': isDefault,
        'is_active': isActive,
        'sort_order': sort,
      });
      // ignore: unused_result
      ref.refresh(_allOptionsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Option created'),
            behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _editOption(ChudaCustomizationOption option) async {
    final nameCtrl = TextEditingController(text: option.name);
    final priceCtrl =
        TextEditingController(text: option.priceDifference.toStringAsFixed(0));
    final sortCtrl =
        TextEditingController(text: option.sortOrder.toString());
    bool isDefault = option.isDefault;
    bool isActive = option.isActive;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Option'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Group: ${_groupLabels[option.groupType] ?? option.groupType}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Price Difference',
                      hintText: '0, 20, -10',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true, signed: true),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: sortCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Sort Order',
                      hintText: '10, 20, 30...',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Is Default', style: TextStyle(fontSize: 14)),
                    value: isDefault,
                    onChanged: (v) =>
                        setDialogState(() => isDefault = v ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  if (isDefault)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Default option must have price difference ₹0',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                      ),
                    ),
                  CheckboxListTile(
                    title: const Text('Is Active', style: TextStyle(fontSize: 14)),
                    value: isActive,
                    onChanged: (v) =>
                        setDialogState(() => isActive = v ?? true),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text('Name is required'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.red),
                  );
                  return;
                }
                final price =
                    double.tryParse(priceCtrl.text.trim()) ?? 0;
                if (isDefault && price != 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Default option must have price difference ₹0'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.red),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    try {
      final repo = ref.read(chudaCustomizationRepositoryProvider);
      final updates = <String, dynamic>{
        'name': nameCtrl.text.trim(),
        'price_difference': double.tryParse(priceCtrl.text.trim()) ?? 0,
        'sort_order': int.tryParse(sortCtrl.text.trim()) ?? 0,
        'is_active': isActive,
      };

      if (isDefault && !option.isDefault) {
        await repo.setDefaultOption(option.groupType, option.id);
      } else if (!isDefault && option.isDefault) {
        updates['is_default'] = false;
        await repo.updateOption(option.id, updates);
      } else {
        updates['is_default'] = isDefault;
        await repo.updateOption(option.id, updates);
      }

      // ignore: unused_result
      ref.refresh(_allOptionsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Option updated'),
            behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _setDefault(String groupType, int optionId) async {
    try {
      final repo = ref.read(chudaCustomizationRepositoryProvider);
      await repo.setDefaultOption(groupType, optionId);
      // ignore: unused_result
      ref.refresh(_allOptionsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Default updated'),
            behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _toggleActive(ChudaCustomizationOption option) async {
    try {
      final repo = ref.read(chudaCustomizationRepositoryProvider);
      if (option.isActive) {
        await repo.deactivateOption(option.id);
      } else {
        await repo.reactivateOption(option.id);
      }
      // ignore: unused_result
      ref.refresh(_allOptionsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(option.isActive
                ? 'Option deactivated'
                : 'Option reactivated'),
            behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red),
      );
    }
  }
}

class _OptionCard extends StatelessWidget {
  final ChudaCustomizationOption option;
  final VoidCallback? onEdit;
  final VoidCallback? onSetDefault;
  final VoidCallback? onToggleActive;

  const _OptionCard({
    required this.option,
    this.onEdit,
    this.onSetDefault,
    this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        title: Row(
          children: [
            Text(option.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 14)),
            if (option.isDefault)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF800000).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Default',
                    style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF800000),
                        fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            Text(_priceLabel(option.priceDifference),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: option.priceDifference < 0
                        ? Colors.orange
                        : Colors.grey.shade700)),
            if (!option.isActive)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('Inactive',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade600)),
              ),
            Text('  Order: ${option.sortOrder}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            switch (action) {
              case 'edit':
                onEdit?.call();
              case 'set_default':
                onSetDefault?.call();
              case 'toggle_active':
                onToggleActive?.call();
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
                value: 'edit', child: Text('Edit')),
            if (onSetDefault != null)
              const PopupMenuItem(
                  value: 'set_default', child: Text('Set as Default')),
            PopupMenuItem(
                value: 'toggle_active',
                child: Text(option.isActive ? 'Deactivate' : 'Reactivate')),
          ],
        ),
      ),
    );
  }
}

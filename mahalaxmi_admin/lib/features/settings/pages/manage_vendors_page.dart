import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahalaxmi_shared/models/vendor_master.dart';
import 'package:mahalaxmi_shared/providers/repository_providers.dart';
import 'package:mahalaxmi_shared/providers/vendor_providers.dart';

class ManageVendorsPage extends ConsumerStatefulWidget {
  const ManageVendorsPage({super.key});

  @override
  ConsumerState<ManageVendorsPage> createState() => _ManageVendorsPageState();
}

class _ManageVendorsPageState extends ConsumerState<ManageVendorsPage> {
  @override
  Widget build(BuildContext context) {
    final vendorsAsync = ref.watch(allVendorsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Vendors')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addVendor,
        icon: const Icon(Icons.add),
        label: const Text('Add Vendor'),
      ),
      body: vendorsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (vendors) {
          if (vendors.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.business_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No vendors found', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(allVendorsProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
              itemCount: vendors.length,
              itemBuilder: (context, index) {
                final v = vendors[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: v.isActive
                        ? const Text('Active', style: TextStyle(color: Colors.green, fontSize: 12))
                        : const Text('Inactive', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'rename') _renameVendor(v);
                        if (action == 'toggle') _toggleActive(v.id!, !v.isActive);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'rename', child: Text('Rename')),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(v.isActive ? 'Deactivate' : 'Activate'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _addVendor() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Vendor'),
        content: Form(
          key: formKey,
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Vendor name'),
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
        ],
      ),
    );

    if (result != true) return;
    final name = controller.text.trim();
    if (name.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vendor name is required'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final repo = ref.read(vendorRepositoryProvider);
      await repo.addVendor({'name': name, 'is_active': true});
      ref.invalidate(allVendorsProvider);
      ref.invalidate(vendorNamesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vendor "$name" created'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _renameVendor(VendorMaster vendor) async {
    final controller = TextEditingController(text: vendor.name);

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Vendor'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Rename')),
        ],
      ),
    );

    if (newName == null || newName.isEmpty || newName == vendor.name) return;
    if (!mounted) return;

    try {
      final repo = ref.read(vendorRepositoryProvider);
      await repo.updateVendor(vendor.id!, {'name': newName});
      ref.invalidate(allVendorsProvider);
      ref.invalidate(vendorNamesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vendor renamed to "$newName"'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _toggleActive(int id, bool isActive) async {
    try {
      final repo = ref.read(vendorRepositoryProvider);
      await repo.toggleVendorActive(id, isActive);
      ref.invalidate(allVendorsProvider);
      ref.invalidate(vendorNamesProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
    }
  }
}

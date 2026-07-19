import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahalaxmi_shared/providers/repository_providers.dart';
import 'package:mahalaxmi_shared/models/material.dart' as models;

final adminMaterialsProvider = FutureProvider<List<models.Material>>((ref) async {
  final repo = ref.read(materialRepositoryProvider);
  return await repo.getMaterials();
});

class MaterialMasterPage extends ConsumerStatefulWidget {
  const MaterialMasterPage({super.key});

  @override
  ConsumerState<MaterialMasterPage> createState() => _MaterialMasterPageState();
}

class _MaterialMasterPageState extends ConsumerState<MaterialMasterPage> {
  final _nameController = TextEditingController();
  final _rateController = TextEditingController();
  bool _adding = false;

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _addMaterial() async {
    final name = _nameController.text.trim();
    final rate = double.tryParse(_rateController.text.trim());

    if (name.isEmpty || rate == null || rate < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid name and rate'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _adding = true);
    try {
      await ref.read(materialRepositoryProvider).addMaterial(name, rate);
      // ignore: unused_result
      ref.refresh(adminMaterialsProvider);
      _nameController.clear();
      _rateController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Material added'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _deleteMaterial(int? id, String name) async {
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Material?'),
        content: Text('Delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(materialRepositoryProvider).deleteMaterial(id);
      // ignore: unused_result
      ref.refresh(adminMaterialsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Material deleted'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final matsAsync = ref.watch(adminMaterialsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Material Master')),
      body: matsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (materials) => Column(
          children: [
            // Add form
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF1565C0).withValues(alpha: 0.05),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Material name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _rateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'Rate',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    child: FilledButton(
                      onPressed: _adding ? null : _addMaterial,
                      child: _adding
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Add'),
                    ),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: materials.isEmpty
                  ? const Center(child: Text('No materials added yet', style: TextStyle(color: Colors.grey)))
                  : RefreshIndicator(
                      onRefresh: () => ref.refresh(adminMaterialsProvider.future),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                        itemCount: materials.length,
                        itemBuilder: (context, index) {
                          final mat = materials[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: ListTile(
                              title: Text(mat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('₹${mat.rate.toStringAsFixed(2)} / ${mat.unit}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () => _deleteMaterial(mat.id, mat.name),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

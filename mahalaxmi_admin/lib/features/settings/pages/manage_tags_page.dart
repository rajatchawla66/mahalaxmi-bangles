import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahalaxmi_shared/providers/repository_providers.dart';
import 'package:mahalaxmi_shared/providers/tags_provider.dart';

final adminTagsWithCountProvider = FutureProvider<List<_TagWithCount>>((ref) async {
  final tagRepo = ref.read(tagRepositoryProvider);
  final itemRepo = ref.read(itemRepositoryProvider);
  final allItems = await itemRepo.getAllItems();
  final tagMasters = await tagRepo.getTagMaster();
  return tagMasters.map((tm) {
    final tagName = tm.name;
    final count = allItems.where((i) => i.tags.contains(tagName)).length;
    return _TagWithCount(tag: tagName, displayName: tm.displayName, count: count);
  }).toList();
});

class _TagWithCount {
  final String tag;
  final String displayName;
  final int count;
  const _TagWithCount({required this.tag, required this.displayName, required this.count});
}

class ManageTagsPage extends ConsumerStatefulWidget {
  const ManageTagsPage({super.key});

  @override
  ConsumerState<ManageTagsPage> createState() => _ManageTagsPageState();
}

class _ManageTagsPageState extends ConsumerState<ManageTagsPage> {
  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(adminTagsWithCountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Tags')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTag,
        icon: const Icon(Icons.add),
        label: const Text('Add Tag'),
      ),
      body: tagsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (tags) {
          if (tags.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.label_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No tags found', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(adminTagsWithCountProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
              itemCount: tags.length,
              itemBuilder: (context, index) {
                final t = tags[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      title: Text(t.displayName != t.tag ? '${t.displayName} (${t.tag})' : t.tag, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${t.count} item${t.count == 1 ? '' : 's'}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'rename') _renameTag(t.tag);
                        if (action == 'remove') _removeTag(t.tag);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'rename', child: Text('Rename')),
                        const PopupMenuItem(value: 'remove', child: Text('Remove from all items')),
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

  Future<void> _addTag() async {
    final nameController = TextEditingController();
    final displayNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Tag'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tag name',
                    helperText: 'Internal name used in items',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Display name (optional)',
                    helperText: 'If empty, tag name is used',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
        ],
      ),
    );

    if (result != true) return;
    final name = nameController.text.trim();
    if (name.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tag name is required'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final repo = ref.read(tagRepositoryProvider);
      await repo.insertTag({
        'name': name,
        'display_name': displayNameController.text.trim().isNotEmpty ? displayNameController.text.trim() : name,
        'is_active': true,
      });
      // ignore: unused_result
      ref.refresh(adminTagsWithCountProvider);
      ref.invalidate(activeTagMasterProvider);
      ref.invalidate(tagMasterProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tag "$name" created'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _renameTag(String oldTag) async {
    final newTag = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(text: oldTag);
        return AlertDialog(
          title: const Text('Rename Tag'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'New name'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Rename')),
          ],
        );
      },
    );

    if (newTag == null || newTag.isEmpty || newTag == oldTag) return;
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Tag?'),
        content: Text('Rename "$oldTag" to "$newTag" across all items?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Rename')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final tagRepo = ref.read(tagRepositoryProvider);
      final itemRepo = ref.read(itemRepositoryProvider);

      await itemRepo.renameTagInAllItems(oldTag, newTag);

      final allTags = await tagRepo.getTagMaster();
      final tagRecord = allTags.where((t) => t.name == oldTag);
      if (tagRecord.isNotEmpty && tagRecord.first.id != null) {
        await tagRepo.updateTag(tagRecord.first.id!, {
          'name': newTag,
        });
      }

      // ignore: unused_result
      ref.refresh(adminTagsWithCountProvider);
      ref.invalidate(activeTagMasterProvider);
      ref.invalidate(tagMasterProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tag renamed'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _removeTag(String tag) async {
    final tagMasters = ref.read(adminTagsWithCountProvider).asData?.value ?? [];
    final match = tagMasters.where((t) => t.tag == tag);
    final itemCount = match.isNotEmpty ? match.first.count : 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Tag?'),
        content: Text('Remove "$tag" from Tag Master and all $itemCount item(s)? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Remove')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final itemRepo = ref.read(itemRepositoryProvider);
      final tagRepo = ref.read(tagRepositoryProvider);

      await itemRepo.removeTagFromAllItems(tag);

      final allTags = await tagRepo.getTagMaster();
      final tagRecord = allTags.where((t) => t.name == tag);
      if (tagRecord.isNotEmpty && tagRecord.first.id != null) {
        await tagRepo.softDeleteTag(tagRecord.first.id!);
      }

      // ignore: unused_result
      ref.refresh(adminTagsWithCountProvider);
      ref.invalidate(activeTagMasterProvider);
      ref.invalidate(tagMasterProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tag removed from $itemCount item(s)'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
    }
  }
}

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mahalaxmi_shared/mahalaxmi_shared.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/crop_image_dialog.dart';

final adminCategoriesManageProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.read(categoryRepositoryProvider);
  return await repo.getCategories(activeOnly: false);
});

class ManageCategoriesPage extends ConsumerStatefulWidget {
  const ManageCategoriesPage({super.key});

  @override
  ConsumerState<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends ConsumerState<ManageCategoriesPage> {
  @override
  Widget build(BuildContext context) {
    final catsAsync = ref.watch(adminCategoriesManageProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCategory,
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
      body: catsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (cats) {
          if (cats.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.category_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No categories found', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(adminCategoriesManageProvider.future),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                itemCount: cats.length,
                itemBuilder: (context, index) {
                  final cat = cats[index];
                  final displayName = cat.name.replaceAll('_', ' ');
                  final isFirst = index == 0;
                  final isLast = index == cats.length - 1;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCover(cat.coverImageUrl),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(displayName,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                const SizedBox(height: 2),
                                Text(cat.name,
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 2,
                                  children: [
                                    if (cat.sizeChart != null && cat.sizeChart!.isNotEmpty)
                                      _FlagChip(
                                        label: '${cat.sizeChart!.length} size${cat.sizeChart!.length == 1 ? '' : 's'}',
                                        tooltip: cat.sizeChart!.join(', '),
                                        color: const Color(0xFF1565C0),
                                      ),
                                    if (cat.hasSubcategories)
                                      const _FlagChip(
                                        label: 'Has Subcategories',
                                        color: Color(0xFF6A1B9A),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _smallIconButton(
                                    Icons.keyboard_arrow_up,
                                    'Move up',
                                    !isFirst,
                                    () => _moveCategory(cat, index, -1),
                                  ),
                                  _smallIconButton(
                                    Icons.keyboard_arrow_down,
                                    'Move down',
                                    !isLast,
                                    () => _moveCategory(cat, index, 1),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: cat.isActive
                                      ? const Color(0xFF2E7D32).withValues(alpha: 0.15)
                                      : Colors.red.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  cat.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                      color: cat.isActive ? const Color(0xFF2E7D32) : Colors.red),
                                ),
                              ),
                              const SizedBox(height: 2),
                              PopupMenuButton<String>(
                                onSelected: (action) {
                                  if (action == 'edit') _editCategory(cat);
                                  if (action == 'toggle') _toggleActive(cat);
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(value: 'toggle',
                                      child: Text(cat.isActive ? 'Deactivate' : 'Activate')),
                                ],
                                icon: const Icon(Icons.more_vert, size: 18),
                              ),
                            ],
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

  Widget _buildCover(String? url) {
    return SizedBox(
      width: 48,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: url != null && url.isNotEmpty
              ? Image.network(url, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback())
              : _fallback(),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF1565C0).withValues(alpha: 0.1),
      ),
      child: const Icon(Icons.image_outlined, size: 24, color: Colors.grey),
    );
  }

  Widget _smallIconButton(IconData icon, String tooltip, bool enabled, VoidCallback onPressed) {
    return SizedBox(
      width: 32,
      height: 28,
      child: IconButton(
        icon: Icon(icon, size: 18),
        tooltip: tooltip,
        onPressed: enabled ? onPressed : null,
        color: enabled ? null : Colors.grey.shade300,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Future<void> _moveCategory(Category cat, int currentIndex, int direction) async {
    final catsAsync = ref.read(adminCategoriesManageProvider);
    final cats = catsAsync.asData?.value ?? [];
    final targetIndex = currentIndex + direction;
    if (targetIndex < 0 || targetIndex >= cats.length) return;

    final target = cats[targetIndex];
    if (cat.id == null || target.id == null) return;

    try {
      await ref.read(categoryRepositoryProvider).swapSortOrder(cat.id!, target.id!);
      // ignore: unused_result
      ref.refresh(adminCategoriesManageProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reorder: $e'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _addCategory() async {
    final nameController = TextEditingController();
    Uint8List? pickedCoverBytes;
    List<String> selectedSizes = [];
    bool hasSubcategories = false;

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Category'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Category name',
                        helperText: 'Use raw DB format (e.g. Metal_Bangles)',
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (pickedCoverBytes != null) ...[
                      AspectRatio(
                        aspectRatio: ImagePolicy.categoryAspectRatio,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(pickedCoverBytes!, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: () => setDialogState(() => pickedCoverBytes = null),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Remove image'),
                      ),
                    ] else ...[
                      OutlinedButton.icon(
                        onPressed: () async {
                          final image = await ImagePicker().pickImage(source: ImageSource.gallery);
                          if (image != null) {
                            final rawBytes = await image.readAsBytes();
                            if (!ctx.mounted) return;
                            final cropped = await showDialog<Uint8List>(
                              context: ctx,
                              builder: (_) => CropImageDialog(
                                imageBytes: rawBytes,
                                aspectRatio: ImagePolicy.categoryAspectRatio,
                                title: 'Crop Category Cover (3:4)',
                                instruction: 'Tip: Position the category design nicely within the 3:4 portrait frame.',
                              ),
                            );
                            if (cropped != null) {
                              final processed = ImageProcessor.processImage(
                                bytes: cropped,
                                targetWidth: ImagePolicy.categoryOutputWidth,
                                targetHeight: ImagePolicy.categoryOutputHeight,
                                jpegQuality: ImagePolicy.categoryJpegQuality,
                              );
                              if (processed != null) {
                                setDialogState(() {
                                  pickedCoverBytes = processed;
                                });
                              }
                            }
                          }
                        },
                        icon: const Icon(Icons.image_outlined, size: 18),
                        label: const Text('Select Cover Image'),
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Text('Category Sizes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('Select the sizes available in this category. Leave empty for no-size categories.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: getMasterSizeOptions().map((sz) {
                        final checked = selectedSizes.contains(sz);
                        return FilterChip(
                          label: Text(sz, style: TextStyle(fontSize: 13, color: checked ? Colors.white : Colors.grey.shade700)),
                          selected: checked,
                          selectedColor: const Color(0xFF800000),
                          checkmarkColor: Colors.white,
                          backgroundColor: Colors.grey.shade100,
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                selectedSizes.add(sz);
                              } else {
                                selectedSizes.remove(sz);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Has Subcategories'),
                      subtitle: const Text('Category shows subcategory grid before items'),
                      value: hasSubcategories,
                      onChanged: (v) => setDialogState(() => hasSubcategories = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Category name is required'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
                  );
                  return;
                }
                Navigator.pop(ctx, name);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (name == null) return;

    final existing = ref.read(adminCategoriesManageProvider).asData?.value ?? [];
    if (existing.any((c) => c.name == name)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category with this name already exists'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
      return;
    }

    try {
      String? coverUrl;
      if (pickedCoverBytes != null) {
        coverUrl = await StorageService.uploadCategoryCover(pickedCoverBytes!, name, 'jpg');
      }

      final repo = ref.read(categoryRepositoryProvider);
      final nextOrder = await repo.getNextSortOrder();
      await repo.insertCategory({
        'name': name,
        if (coverUrl != null) 'cover_image_url': coverUrl,
        'size_chart': selectedSizes.isEmpty ? null : selectedSizes,
        'has_subcategories': hasSubcategories,
        'sort_order': nextOrder,
      });
      // ignore: unused_result
      ref.refresh(adminCategoriesManageProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Category "$name" created'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _editCategory(Category cat) async {
    final nameController = TextEditingController(text: cat.name);
    Uint8List? pickedCoverBytes;
    List<String> selectedSizes = List.from(cat.sizeChart ?? []);
    bool hasSubcategories = cat.hasSubcategories;
    bool coverChanged = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Category'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        helperText: 'Warning: changing name affects DB queries',
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (pickedCoverBytes != null) ...[
                      AspectRatio(
                        aspectRatio: ImagePolicy.categoryAspectRatio,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(pickedCoverBytes!, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: () => setDialogState(() {
                          pickedCoverBytes = null;
                          coverChanged = false;
                        }),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Remove new image'),
                      ),
                    ] else ...[
                      if (cat.coverImageUrl != null && cat.coverImageUrl!.isNotEmpty) ...[
                        AspectRatio(
                          aspectRatio: ImagePolicy.categoryAspectRatio,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(cat.coverImageUrl!, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      OutlinedButton.icon(
                        onPressed: () async {
                          final image = await ImagePicker().pickImage(source: ImageSource.gallery);
                          if (image != null) {
                            final rawBytes = await image.readAsBytes();
                            if (!ctx.mounted) return;
                            final cropped = await showDialog<Uint8List>(
                              context: ctx,
                              builder: (_) => CropImageDialog(
                                imageBytes: rawBytes,
                                aspectRatio: ImagePolicy.categoryAspectRatio,
                                title: 'Crop Category Cover (3:4)',
                                instruction: 'Tip: Position the category design nicely within the 3:4 portrait frame.',
                              ),
                            );
                            if (cropped != null) {
                              final processed = ImageProcessor.processImage(
                                bytes: cropped,
                                targetWidth: ImagePolicy.categoryOutputWidth,
                                targetHeight: ImagePolicy.categoryOutputHeight,
                                jpegQuality: ImagePolicy.categoryJpegQuality,
                              );
                              if (processed != null) {
                                setDialogState(() {
                                  pickedCoverBytes = processed;
                                  coverChanged = true;
                                });
                              }
                            }
                          }
                        },
                        icon: const Icon(Icons.image_outlined, size: 18),
                        label: const Text('Change Cover Image'),
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Text('Category Sizes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('Select the sizes available in this category. Leave empty for no-size categories.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: getMasterSizeOptions().map((sz) {
                        final checked = selectedSizes.contains(sz);
                        return FilterChip(
                          label: Text(sz, style: TextStyle(fontSize: 13, color: checked ? Colors.white : Colors.grey.shade700)),
                          selected: checked,
                          selectedColor: const Color(0xFF800000),
                          checkmarkColor: Colors.white,
                          backgroundColor: Colors.grey.shade100,
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                selectedSizes.add(sz);
                              } else {
                                selectedSizes.remove(sz);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Has Subcategories'),
                      subtitle: const Text('Category shows subcategory grid before items'),
                      value: hasSubcategories,
                      onChanged: (v) => setDialogState(() => hasSubcategories = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (result != true) return;

    try {
      final repo = ref.read(categoryRepositoryProvider);
      final newName = nameController.text.trim();

      if (newName.isNotEmpty && newName != cat.name) {
        await repo.updateCategoryName(cat.id!, newName);
      }

      if (coverChanged && pickedCoverBytes != null) {
        final uploadedUrl = await StorageService.uploadCategoryCover(pickedCoverBytes!, newName.isNotEmpty ? newName : cat.name, 'jpg');
        await repo.updateCategoryCoverImage(cat.id!, uploadedUrl);
      }

      await repo.updateCategorySizeChart(cat.id!, selectedSizes.isEmpty ? null : selectedSizes);

      if (hasSubcategories != cat.hasSubcategories) {
        await repo.updateCategoryHasSubcategories(cat.id!, hasSubcategories);
      }

      // ignore: unused_result
      ref.refresh(adminCategoriesManageProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category updated'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _toggleActive(Category cat) async {
    final newActive = !cat.isActive;
    final action = newActive ? 'Activate' : 'Deactivate';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action Category?'),
        content: Text(newActive
            ? 'This category will appear in the customer app.'
            : 'This category will be hidden from the customer app.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(action)),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(categoryRepositoryProvider).toggleCategoryActive(cat.id!, newActive);
      // ignore: unused_result
      ref.refresh(adminCategoriesManageProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Category ${action}d'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
    }
  }
}

class _FlagChip extends StatelessWidget {
  final String label;
  final Color color;
  final String? tooltip;
  const _FlagChip({required this.label, required this.color, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: chip);
    }
    return chip;
  }
}

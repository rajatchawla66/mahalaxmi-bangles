import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mahalaxmi_shared/models/cutmail.dart';
import 'package:mahalaxmi_shared/models/cutmail_size.dart';
import 'package:mahalaxmi_shared/providers/repository_providers.dart';
import 'package:mahalaxmi_shared/providers/session_provider.dart';

import '../providers/admin_cutmail_provider.dart';

class CutmailDetailPage extends ConsumerStatefulWidget {
  final String cutmailId;
  const CutmailDetailPage({super.key, required this.cutmailId});

  @override
  ConsumerState<CutmailDetailPage> createState() => _CutmailDetailPageState();
}

class _CutmailDetailPageState extends ConsumerState<CutmailDetailPage> {
  final _noteController = TextEditingController();
  bool _isEditing = false;
  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _initEdit(Cutmail cutmail, List<CutmailSize> sizes) {
    if (_loaded) return;
    _loaded = true;
    _noteController.text = cutmail.note ?? '';
    for (final size in sizes) {
      _editControllers[size.size] = TextEditingController(
        text: size.availableQty.toString(),
      );
    }
  }

  final Map<String, TextEditingController> _editControllers = {};

  @override
  Widget build(BuildContext context) {
    final cutmailAsync = ref.watch(adminCutmailDetailProvider(widget.cutmailId));
    final sizesAsync = ref.watch(adminCutmailSizesProvider(widget.cutmailId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cutmail Detail'),
        actions: [
          if (_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _isEditing = false;
                _editControllers.clear();
              }),
              tooltip: 'Cancel',
            ),
          ],
        ],
      ),
      body: cutmailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (cutmail) {
          if (cutmail == null) {
            return const Center(child: Text('Cutmail not found'));
          }
          return sizesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (sizes) {
              if (!_loaded) _initEdit(cutmail, sizes);
              return _buildContent(cutmail, sizes);
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(Cutmail cutmail, List<CutmailSize> sizes) {
    final dateStr = cutmail.createdAt != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(cutmail.createdAt!)
        : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatusBadge(cutmail.status),
          const SizedBox(height: 16),

          if (cutmail.imageUrlSnapshot != null &&
              cutmail.imageUrlSnapshot!.isNotEmpty) ...[
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  cutmail.imageUrlSnapshot!,
                  height: 180,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 48, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cutmail.itemNumberSnapshot ?? cutmail.itemNameSnapshot,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(cutmail.categoryName.replaceAll('_', ' '),
                      style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  if (dateStr.isNotEmpty)
                    Text(dateStr,
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 12)),
                  if (cutmail.checkedByName != null)
                    Text('Checked by: ${cutmail.checkedByName}',
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Text('Size-wise Quantities',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          _buildSizesSection(cutmail, sizes),

          const SizedBox(height: 16),
          const Text('Note',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          _buildNoteSection(cutmail),

          const SizedBox(height: 24),
          _buildActionButtons(cutmail, sizes),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = const Color(0xFFF9A825);
      case 'reviewed':
        color = const Color(0xFF2E7D32);
      case 'archived':
        color = Colors.grey;
      default:
        color = Colors.grey;
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status[0].toUpperCase() + status.substring(1),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSizesSection(Cutmail cutmail, List<CutmailSize> sizes) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: sizes.map((size) {
            final isEditing = _isEditing;
            final controller = _editControllers[size.size];
            final qty = isEditing && controller != null
                ? (int.tryParse(controller.text) ?? 0)
                : size.availableQty;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(size.size,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: isEditing && controller != null
                        ? TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          )
                        : Text(
                            '$qty',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: qty > 0 ? Colors.black87 : Colors.grey,
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    qty > 0 ? 'Available' : 'Out of stock',
                    style: TextStyle(
                      fontSize: 12,
                      color: qty > 0 ? Colors.green : Colors.red[400],
                      fontWeight: FontWeight.w500,
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

  Widget _buildNoteSection(Cutmail cutmail) {
    if (_isEditing) {
      return TextField(
        controller: _noteController,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Add a note...',
          border: OutlineInputBorder(),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          cutmail.note?.isNotEmpty == true ? cutmail.note! : 'No note',
          style: TextStyle(
            color: cutmail.note?.isNotEmpty == true
                ? Colors.black87
                : Colors.grey,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(Cutmail cutmail, List<CutmailSize> sizes) {
    final status = cutmail.status;

    if (status == 'archived') {
      return const SizedBox.shrink();
    }

    if (!_isEditing) {
      return Column(
        children: [
          if (status == 'pending' || status == 'reviewed')
            OutlinedButton.icon(
              onPressed: () {
                setState(() => _isEditing = true);
                _loaded = false;
                _initEdit(cutmail, sizes);
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Quantities / Note'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          const SizedBox(height: 12),
          if (status == 'pending')
            FilledButton.icon(
              onPressed: () => _markReviewed(cutmail),
              icon: const Icon(Icons.check_circle),
              label: const Text('Mark Reviewed'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: const Color(0xFF2E7D32),
              ),
            ),
          if (status == 'reviewed' || status == 'pending')
            OutlinedButton.icon(
              onPressed: () => _archiveCutmail(cutmail),
              icon: const Icon(Icons.archive_outlined),
              label: const Text('Archive'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                foregroundColor: Colors.grey[700],
              ),
            ),
        ],
      );
    }

    // Editing mode
    return Column(
      children: [
        FilledButton.icon(
          onPressed: _saving ? null : () => _saveEdits(cutmail, sizes),
          icon: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save),
          label: Text(_saving ? 'Saving...' : 'Save Changes'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  Future<void> _saveEdits(Cutmail cutmail, List<CutmailSize> originalSizes) async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(cutmailRepositoryProvider);

      final updatedSizes = originalSizes.map((size) {
        final controller = _editControllers[size.size];
        final qty = controller != null ? (int.tryParse(controller.text) ?? 0) : size.availableQty;
        return size.copyWith(
          availableQty: qty,
          isAvailable: qty > 0,
        );
      }).toList();

      await repo.updateCutmailSizes(cutmail.id!, updatedSizes);
      await repo.updateCutmail(cutmail.id!, {'note': _noteController.text});

      // ignore: unused_result
      ref.refresh(adminCutmailDetailProvider(widget.cutmailId));
      // ignore: unused_result
      ref.refresh(adminCutmailSizesProvider(widget.cutmailId));

      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _editControllers.clear();
        _loaded = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cutmail updated'),
            behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to save: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _markReviewed(Cutmail cutmail) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Reviewed?'),
        content: const Text('This cutmail will be marked as reviewed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Mark Reviewed')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final session = ref.read(appSessionProvider);
      final reviewedBy = session.isLabour ? 'Labour' : 'Admin';
      await ref.read(cutmailRepositoryProvider).markReviewed(
            cutmail.id!,
            reviewedBy,
          );

      // ignore: unused_result
      ref.refresh(adminCutmailDetailProvider(widget.cutmailId));
      ref.invalidate(adminCutmailsByStatusProvider('all'));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cutmail marked as reviewed'),
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

  Future<void> _archiveCutmail(Cutmail cutmail) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Cutmail?'),
        content: const Text('This cutmail will be archived.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Archive')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(cutmailRepositoryProvider).archiveCutmail(cutmail.id!);

      // ignore: unused_result
      ref.refresh(adminCutmailDetailProvider(widget.cutmailId));
      ref.invalidate(adminCutmailsByStatusProvider('all'));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cutmail archived'),
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

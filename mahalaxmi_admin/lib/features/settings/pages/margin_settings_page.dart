import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahalaxmi_shared/providers/repository_providers.dart';

final adminDefaultMarginProvider = FutureProvider<double>((ref) async {
  final repo = ref.read(settingsRepositoryProvider);
  return await repo.getDefaultMargin();
});

class MarginSettingsPage extends ConsumerStatefulWidget {
  const MarginSettingsPage({super.key});

  @override
  ConsumerState<MarginSettingsPage> createState() => _MarginSettingsPageState();
}

class _MarginSettingsPageState extends ConsumerState<MarginSettingsPage> {
  final _controller = TextEditingController();
  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marginAsync = ref.watch(adminDefaultMarginProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Default Margin'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: marginAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (margin) {
          if (!_loaded) {
            _loaded = true;
            _controller.text = margin.toStringAsFixed(1);
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Default Profit Margin',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  'This margin is used when pricing new items. Existing items are not affected.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Margin %', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _controller,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            suffixText: '%',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    final value = double.tryParse(_controller.text.trim());
    if (value == null || value < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid margin percentage'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(settingsRepositoryProvider).saveDefaultMargin(value);
      // ignore: unused_result
      ref.refresh(adminDefaultMarginProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Default margin saved'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

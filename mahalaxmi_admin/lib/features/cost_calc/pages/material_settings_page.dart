import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mahalaxmi_shared/providers/session_provider.dart';

import '../providers/material_settings_provider.dart';

class MaterialSettingsPage extends ConsumerStatefulWidget {
  const MaterialSettingsPage({super.key});

  @override
  ConsumerState<MaterialSettingsPage> createState() =>
      _MaterialSettingsPageState();
}

class _MaterialSettingsPageState extends ConsumerState<MaterialSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  bool _saving = false;

  static const _fields = <(String, String)>[
    ('nihar', 'Nihar'),
    ('dot_plain', 'Dot Plain'),
    ('dot_stone', 'Dot Stone'),
    ('dot_kundan', 'Dot Kundan'),
    ('taj_stone', 'Taj Stone'),
    ('sunshine', 'Sunshine'),
    ('moti_103', 'Moti 103'),
    ('patti_gol', 'Patti GOL'),
    ('patti_without_gol', 'Patti Without GOL'),
  ];

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initControllers(Map<String, dynamic> settings) {
    for (final (key, _) in _fields) {
      final value = _getValue(key, settings);
      _controllers[key] = TextEditingController(
        text: value > 0 ? value.toStringAsFixed(0) : '',
      );
    }
    final boxPresets = settings['box_presets'] as List<dynamic>?;
    _controllers['boxPresets'] = TextEditingController(
      text: boxPresets
              ?.map((e) => (e as num).toStringAsFixed(0))
              .join(', ') ??
          '15, 30, 55, 70, 90, 100, 120',
    );
  }

  double _getValue(String key, Map<String, dynamic> settings) {
    final val = settings[key];
    if (val is num) return val.toDouble();
    return 0;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final parsedPresets = _controllers['boxPresets']!.text
          .split(',')
          .map((s) => double.tryParse(s.trim()))
          .where((v) => v != null && v > 0)
          .cast<double>()
          .toList();

      final session = ref.read(appSessionProvider);
      final username = session.username ?? 'admin';

      final settings = <String, dynamic>{
        'id': 1,
        'nihar': double.tryParse(_controllers['nihar']!.text) ?? 0,
        'dot_plain': double.tryParse(_controllers['dot_plain']!.text) ?? 0,
        'dot_stone': double.tryParse(_controllers['dot_stone']!.text) ?? 0,
        'dot_kundan': double.tryParse(_controllers['dot_kundan']!.text) ?? 0,
        'taj_stone': double.tryParse(_controllers['taj_stone']!.text) ?? 0,
        'sunshine': double.tryParse(_controllers['sunshine']!.text) ?? 0,
        'moti_103': double.tryParse(_controllers['moti_103']!.text) ?? 0,
        'patti_gol': double.tryParse(_controllers['patti_gol']!.text) ?? 0,
        'patti_without_gol':
            double.tryParse(_controllers['patti_without_gol']!.text) ?? 0,
        'box_presets':
            parsedPresets.isNotEmpty ? parsedPresets : [15, 30, 55, 70, 90, 100, 120],
        'updated_by': username,
      };

      await ref.read(materialSettingsRepositoryProvider).save(settings);

      if (!mounted) return;
      ref.invalidate(materialSettingsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
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

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(materialSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Material Prices')),
      body: settingsAsync.when(
        data: (settings) {
          final data = settings ?? <String, dynamic>{};
          if (_controllers.isEmpty) _initControllers(data);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final (key, label) in _fields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: _controllers[key],
                      decoration: InputDecoration(
                        labelText: label,
                        prefixText: '\u20B9 ',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
                      ],
                      validator: (v) {
                        if (v != null && v.trim().isNotEmpty) {
                          if (double.tryParse(v.trim()) == null) {
                            return 'Enter a valid number';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                const SizedBox(height: 8),
                Text('Box Presets',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _controllers['boxPresets'],
                  decoration: InputDecoration(
                    hintText: 'e.g. 15, 30, 55, 70, 90, 100, 120',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'At least one preset required';
                    }
                    final parts = v
                        .split(',')
                        .map((s) => double.tryParse(s.trim()))
                        .toList();
                    if (parts.any((p) => p == null || p <= 0)) {
                      return 'Enter comma-separated positive numbers';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Failed to load settings: $e')),
      ),
    );
  }
}

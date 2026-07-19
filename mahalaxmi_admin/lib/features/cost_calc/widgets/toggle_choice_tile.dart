import 'package:flutter/material.dart';
import 'package:mahalaxmi_shared/constants/material_config.dart';

class ToggleChoiceTile extends StatelessWidget {
  final MaterialConfig config;
  final Map<String, dynamic> settings;
  final String? selectedToggleId;
  final ValueChanged<String> onToggleChanged;

  const ToggleChoiceTile({
    super.key,
    required this.config,
    required this.settings,
    required this.selectedToggleId,
    required this.onToggleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(config.displayName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: config.toggleOptions!.map((opt) {
                final isSelected = selectedToggleId == opt.id;
                final optPrice = _priceForKey(opt.settingsKey);
                return FilterChip(
                  label: Text('${opt.label} (\u20B9${optPrice.toStringAsFixed(0)})'),
                  selected: isSelected,
                  onSelected: (_) => onToggleChanged(opt.id),
                );
              }).toList(),
            ),
            if (selectedToggleId == null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Select one',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.outline)),
              ),
          ],
        ),
      ),
    );
  }

  double _priceForKey(String key) {
    final val = settings[key];
    if (val is num) return val.toDouble();
    return 0;
  }
}

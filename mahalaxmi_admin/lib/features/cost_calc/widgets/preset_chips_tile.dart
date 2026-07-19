import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mahalaxmi_shared/constants/material_config.dart';

class PresetChipsTile extends StatefulWidget {
  final MaterialConfig config;
  final double price;
  final bool selected;
  final ValueChanged<double> onPriceChanged;

  const PresetChipsTile({
    super.key,
    required this.config,
    required this.price,
    required this.selected,
    required this.onPriceChanged,
  });

  @override
  State<PresetChipsTile> createState() => _PresetChipsTileState();
}

class _PresetChipsTileState extends State<PresetChipsTile> {
  late final TextEditingController _priceController;

  bool get _isManual => widget.config.presetOptions != null &&
      widget.price > 0 &&
      !widget.config.presetOptions!.contains(widget.price);

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: _isManual ? widget.price.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PresetChipsTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.price != oldWidget.price) {
      final newText = _isManual ? widget.price.toStringAsFixed(0) : '';
      if (_priceController.text != newText) {
        _priceController.text = newText;
      }
    }
  }

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
            Text(widget.config.displayName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...widget.config.presetOptions!.map((opt) {
                  final isSelected = widget.price == opt && !_isManual;
                  return ChoiceChip(
                    label: Text('\u20B9${opt.toInt()}'),
                    selected: isSelected,
                    onSelected: (_) => widget.onPriceChanged(opt),
                  );
                }),
                ActionChip(
                  label: const Text('Manual'),
                  onPressed: () {},
                  avatar: Icon(Icons.edit, size: 16,
                      color: _isManual ? theme.colorScheme.primary : theme.colorScheme.outline),
                  side: _isManual
                      ? BorderSide(color: theme.colorScheme.primary)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                isDense: true,
                labelText: 'Manual price',
                prefixText: '\u20B9 ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              controller: _priceController,
              onChanged: (v) {
                final p = double.tryParse(v);
                if (p != null && p > 0) {
                  widget.onPriceChanged(p);
                } else if (v.isEmpty && widget.price > 0 && _isManual) {
                  widget.onPriceChanged(0);
                }
              },
            ),
            if (!widget.selected && widget.price <= 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Tap a chip or enter manual price',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.outline)),
              ),
          ],
        ),
      ),
    );
  }
}

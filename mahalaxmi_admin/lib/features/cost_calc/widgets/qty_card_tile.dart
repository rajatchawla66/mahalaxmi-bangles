import 'package:flutter/material.dart';
import 'package:mahalaxmi_shared/constants/material_config.dart';

import 'price_spinner_sheet.dart';

class QtyCardTile extends StatefulWidget {
  final MaterialConfig config;
  final double price;
  final double qty;
  final bool selected;
  final ValueChanged<double> onPriceChanged;
  final ValueChanged<double> onQtyChanged;

  const QtyCardTile({
    super.key,
    required this.config,
    required this.price,
    required this.qty,
    required this.selected,
    required this.onPriceChanged,
    required this.onQtyChanged,
  });

  @override
  State<QtyCardTile> createState() => _QtyCardTileState();
}

class _QtyCardTileState extends State<QtyCardTile> {
  String _formatQty(double val) {
    if (val == val.roundToDouble()) return val.toInt().toString();
    return val.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPrice = widget.price > 0;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(widget.config.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    final result = await showPriceSpinnerSheet(
                      context,
                      initialValue: widget.price.toInt(),
                      title: widget.config.displayName,
                    );
                    if (result != null) {
                      widget.onPriceChanged(result.toDouble());
                    }
                  },
                  child: Container(
                    width: 90,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: hasPrice ? theme.colorScheme.primary : theme.colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '\u20B9 ${hasPrice ? widget.price.toStringAsFixed(0) : '--'}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: hasPrice ? theme.colorScheme.primary : theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.tune, size: 16,
                            color: hasPrice ? theme.colorScheme.primary : theme.colorScheme.outline),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ...widget.config.qtyOptions!.map((opt) {
                  final isSelected = widget.qty == opt;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_formatQty(opt)),
                      selected: isSelected,
                      onSelected: (_) => widget.onQtyChanged(opt),
                    ),
                  );
                }),
              ],
            ),
            if (!widget.selected && widget.price <= 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Tap \u20B9 to set price',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.outline)),
              ),
          ],
        ),
      ),
    );
  }
}

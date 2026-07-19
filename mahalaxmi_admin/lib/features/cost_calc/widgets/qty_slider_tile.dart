import 'package:flutter/material.dart';
import 'package:mahalaxmi_shared/constants/material_config.dart';

import 'price_spinner_sheet.dart';

class QtySliderTile extends StatefulWidget {
  final MaterialConfig config;
  final double price;
  final double qty;
  final bool selected;
  final bool showPriceField;
  final ValueChanged<double> onPriceChanged;
  final ValueChanged<double> onQtyChanged;
  final VoidCallback? onToggle;

  const QtySliderTile({
    super.key,
    required this.config,
    required this.price,
    required this.qty,
    required this.selected,
    required this.showPriceField,
    required this.onPriceChanged,
    required this.onQtyChanged,
    this.onToggle,
  });

  @override
  State<QtySliderTile> createState() => _QtySliderTileState();
}

class _QtySliderTileState extends State<QtySliderTile> {
  String _formatQty(double val) {
    if (val == val.roundToDouble()) return val.toInt().toString();
    return val.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFixed = widget.config.hasFixedPrice;
    final hasPrice = widget.price > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isFixed ? widget.onToggle : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isFixed)
                    Icon(
                      widget.selected ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 20,
                      color: widget.selected ? theme.colorScheme.primary : theme.colorScheme.outline,
                    ),
                  if (isFixed) const SizedBox(width: 8),
                  Text(widget.config.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const Spacer(),
                  if (widget.showPriceField)
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
                    )
                  else
                    Text('\u20B9${widget.price.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              if (widget.selected) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Qty: ${_formatQty(widget.qty)}',
                        style: TextStyle(color: theme.colorScheme.outline, fontSize: 13)),
                    const Spacer(),
                    SizedBox(
                      width: 200,
                      child: Slider(
                        value: widget.qty,
                        min: widget.config.minQty!,
                        max: widget.config.maxQty!,
                        divisions: ((widget.config.maxQty! - widget.config.minQty!) / widget.config.stepQty!).round(),
                        label: _formatQty(widget.qty),
                        onChanged: widget.onQtyChanged,
                      ),
                    ),
                  ],
                ),
              ],
              if (isFixed && !widget.selected)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Tap to select',
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.outline)),
                ),
              if (!isFixed && !widget.selected && widget.price <= 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Tap \u20B9 to set price',
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.outline)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

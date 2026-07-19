import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mahalaxmi_shared/constants/material_config.dart';

import 'price_spinner_sheet.dart';

class QtyPickerTile extends StatefulWidget {
  final MaterialConfig config;
  final double price;
  final double qty;
  final bool selected;
  final ValueChanged<double> onPriceChanged;
  final ValueChanged<double> onQtyChanged;

  const QtyPickerTile({
    super.key,
    required this.config,
    required this.price,
    required this.qty,
    required this.selected,
    required this.onPriceChanged,
    required this.onQtyChanged,
  });

  @override
  State<QtyPickerTile> createState() => _QtyPickerTileState();
}

class _QtyPickerTileState extends State<QtyPickerTile> {
  late List<double> _options;
  late FixedExtentScrollController _qtyController;
  late int _qtyIndex;

  @override
  void initState() {
    super.initState();
    _options = widget.config.qtyOptions ??
        [1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5];
    _qtyIndex = _findIndex(widget.qty);
    _qtyController = FixedExtentScrollController(initialItem: _qtyIndex);
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(QtyPickerTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.qty != oldWidget.qty) {
      final newIndex = _findIndex(widget.qty);
      if (newIndex != _qtyIndex) {
        _qtyIndex = newIndex;
        _qtyController.jumpToItem(_qtyIndex);
      }
    }
  }

  int _findIndex(double qty) {
    int best = 0;
    double bestDist = double.infinity;
    for (int i = 0; i < _options.length; i++) {
      final dist = (qty - _options[i]).abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = i;
      }
    }
    return best;
  }

  String _formatOpt(double val) {
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
                Text('Qty: ',
                    style: TextStyle(fontSize: 14, color: theme.colorScheme.outline)),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CupertinoPicker(
                    scrollController: _qtyController,
                    itemExtent: 24,
                    looping: false,
                    onSelectedItemChanged: (i) {
                      _qtyIndex = i;
                      widget.onQtyChanged(_options[i]);
                    },
                    children: _options.map((v) => Center(
                      child: Text(_formatOpt(v),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    )).toList(),
                  ),
                ),
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mahalaxmi_shared/constants/material_config.dart';

class ManualQtyTile extends StatefulWidget {
  final MaterialConfig config;
  final double price;
  final double qty;
  final bool selected;
  final ValueChanged<double> onPriceChanged;
  final ValueChanged<double> onQtyChanged;

  const ManualQtyTile({
    super.key,
    required this.config,
    required this.price,
    required this.qty,
    required this.selected,
    required this.onPriceChanged,
    required this.onQtyChanged,
  });

  @override
  State<ManualQtyTile> createState() => _ManualQtyTileState();
}

class _ManualQtyTileState extends State<ManualQtyTile> {
  late final TextEditingController _priceController;
  late final TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.price > 0 ? widget.price.toStringAsFixed(0) : '',
    );
    _qtyController = TextEditingController(
      text: widget.qty > 0 ? widget.qty.toString() : '',
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ManualQtyTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.price != oldWidget.price) {
      final newText = widget.price > 0 ? widget.price.toStringAsFixed(0) : '';
      if (_priceController.text != newText) {
        _priceController.text = newText;
      }
    }
    if (widget.qty != oldWidget.qty) {
      final newText = widget.qty > 0 ? widget.qty.toString() : '';
      if (_qtyController.text != newText) {
        _qtyController.text = newText;
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Price',
                      prefixText: '\u20B9 ',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                    controller: _priceController,
                    onChanged: (v) {
                      final p = double.tryParse(v) ?? 0;
                      widget.onPriceChanged(p);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Qty',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                    controller: _qtyController,
                    onChanged: (v) {
                      final q = double.tryParse(v) ?? 0;
                      widget.onQtyChanged(q);
                    },
                  ),
                ),
              ],
            ),
            if (!widget.selected && widget.price <= 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Enter price to select',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.outline)),
              ),
          ],
        ),
      ),
    );
  }
}

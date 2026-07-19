import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<int?> showPriceSpinnerSheet(
  BuildContext context, {
  int initialValue = 0,
  String title = 'Set Price',
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return _PriceSpinnerSheet(
        initialValue: initialValue.clamp(0, 999),
        title: title,
      );
    },
  );
}

class _PriceSpinnerSheet extends StatefulWidget {
  final int initialValue;
  final String title;
  const _PriceSpinnerSheet({
    required this.initialValue,
    required this.title,
  });

  @override
  State<_PriceSpinnerSheet> createState() => _PriceSpinnerSheetState();
}

class _PriceSpinnerSheetState extends State<_PriceSpinnerSheet> {
  late int _hundreds;
  late int _tens;
  late int _ones;
  late FixedExtentScrollController _hundredsCtrl;
  late FixedExtentScrollController _tensCtrl;
  late FixedExtentScrollController _onesCtrl;

  int get _value => _hundreds * 100 + _tens * 10 + _ones;

  @override
  void initState() {
    super.initState();
    _hundreds = widget.initialValue ~/ 100;
    _tens = (widget.initialValue % 100) ~/ 10;
    _ones = widget.initialValue % 10;
    _hundredsCtrl = FixedExtentScrollController(initialItem: _hundreds);
    _tensCtrl = FixedExtentScrollController(initialItem: _tens);
    _onesCtrl = FixedExtentScrollController(initialItem: _ones);
  }

  @override
  void dispose() {
    _hundredsCtrl.dispose();
    _tensCtrl.dispose();
    _onesCtrl.dispose();
    super.dispose();
  }

  Widget _buildWheel(String label, FixedExtentScrollController ctrl, ValueChanged<int> onChanged) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 64,
          height: 130,
          child: CupertinoPicker(
            scrollController: ctrl,
            itemExtent: 26,
            looping: false,
            onSelectedItemChanged: (i) {
              onChanged(i);
              setState(() {});
            },
            children: List.generate(10, (i) => Center(
              child: Text('$i', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            )),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text('Set Price', style: TextStyle(fontSize: 14, color: theme.colorScheme.outline)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '\u20B9 $_value',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildWheel('H', _hundredsCtrl, (i) => _hundreds = i),
                const SizedBox(width: 8),
                _buildWheel('T', _tensCtrl, (i) => _tens = i),
                const SizedBox(width: 8),
                _buildWheel('O', _onesCtrl, (i) => _ones = i),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_value),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Done', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

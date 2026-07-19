import 'package:flutter/material.dart';

class CostingMethod {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const CostingMethod({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

const costingMethods = [
  CostingMethod(
    id: 'trading',
    title: 'Trading Item',
    subtitle: 'Direct buy & sell — cost price only',
    icon: Icons.swap_horiz,
    color: Color(0xFF2196F3),
  ),
  CostingMethod(
    id: 'manufacturing',
    title: 'Manufactured Item',
    subtitle: 'Material cost breakdown',
    icon: Icons.build,
    color: Color(0xFFE91E63),
  ),
];

Future<String?> showCostingMethodDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Select Costing Type'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: costingMethods.map((m) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: m.color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(ctx).pop(m.id),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: m.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(m.icon, color: m.color, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                            const SizedBox(height: 2),
                            Text(m.subtitle,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: Colors.grey[400], size: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}

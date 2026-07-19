import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mahalaxmi_shared/models/order.dart';

import '../providers/labour_orders_provider.dart';

class OrderDetailPage extends ConsumerStatefulWidget {
  final int orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  Color _statusColor(String status) {
    return switch (status) {
      'pending' => const Color(0xFFF9A825),
      'confirmed' => const Color(0xFF1565C0),
      'completed' => const Color(0xFF2E7D32),
      'cancelled' => const Color(0xFFC62828),
      _ => Colors.grey,
    };
  }

  String _statusLabel(String status) {
    return switch (status) {
      'pending' => 'Pending',
      'confirmed' => 'Confirmed',
      'completed' => 'Completed',
      'cancelled' => 'Cancelled',
      _ => status,
    };
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(labourOrderDetailProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(title: Text('Order #${widget.orderId}')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text('Could not load order',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      ref.refresh(labourOrderDetailProvider(widget.orderId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }
          return _buildContent(order);
        },
      ),
    );
  }

  Widget _buildContent(Order order) {
    final statusColor = _statusColor(order.status);

    return RefreshIndicator(
      onRefresh: () =>
          ref.refresh(labourOrderDetailProvider(widget.orderId).future),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Order header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Order #${order.orderId}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _statusLabel(order.status).toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _infoRow(Icons.calendar_today, _formatDate(order.orderDate)),
                  if (order.customerName.isNotEmpty)
                    _infoRow(Icons.person_outline, order.customerName),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Items section
          Text('Items (${order.orderItems.length})',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),

          if (order.orderItems.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('No items in this order',
                      style: TextStyle(color: Colors.grey)),
                ),
              ),
            )
          else
            ...order.orderItems.map((item) => _OrderItemCard(item: item)),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, h:mm a').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}

class _OrderItemCard extends StatelessWidget {
  final OrderItem item;

  const _OrderItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.itemNumber,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (item.color != null && item.color!.isNotEmpty)
              _detailChip(item.color!),
            if (item.totalSizeQty > 0) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 2,
                children: [
                  if (item.qty22 > 0) _sizeChip('2.2', item.qty22),
                  if (item.qty24 > 0) _sizeChip('2.4', item.qty24),
                  if (item.qty26 > 0) _sizeChip('2.6', item.qty26),
                  if (item.qty28 > 0) _sizeChip('2.8', item.qty28),
                  if (item.qty210 > 0) _sizeChip('2.10', item.qty210),
                  if (item.qty212 > 0) _sizeChip('2.12', item.qty212),
                ],
              ),
            ] else ...[
              const SizedBox(height: 4),
              _detailChip('Qty: ${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 2)}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailChip(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, color: Colors.black87),
    );
  }

  Widget _sizeChip(String size, int qty) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$size: $qty',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}

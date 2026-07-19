import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mahalaxmi_shared/models/order.dart';
import 'package:mahalaxmi_shared/providers/repository_providers.dart';
import 'package:mahalaxmi_shared/services/order_pdf_service.dart';
import 'package:printing/printing.dart';
import 'package:mahalaxmi_admin/features/dashboard/providers/dashboard_provider.dart';
import '../providers/admin_orders_provider.dart';

class OrderDetailPage extends ConsumerStatefulWidget {
  final int orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  bool _statusUpdating = false;
  bool _deleting = false;

  Future<void> _confirmDelete(Order order) async {
    if (order.status == 'completed') {
      await _showDeleteCompletedDialog(order);
    } else {
      await _showDeleteCancelledDialog(order);
    }
  }

  Future<void> _showDeleteCancelledDialog(Order order) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Order?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This order will be removed from admin lists. '
              'Use this only for duplicate, test, or wrongly created orders.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _performDelete(order, reasonController.text.trim());
  }

  Future<void> _showDeleteCompletedDialog(Order order) async {
    final reasonController = TextEditingController();
    bool typedCorrectly = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Delete Completed Order?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This is a completed business order. Deleting it will hide it '
                'from order lists and reports. Continue only if this order was '
                'created by mistake.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Type DELETE below to confirm:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                onChanged: (v) => setDialogState(() {
                  typedCorrectly = v == 'DELETE';
                }),
                decoration: const InputDecoration(
                  hintText: 'DELETE',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              onPressed: typedCorrectly ? () => Navigator.pop(ctx, true) : null,
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    await _performDelete(order, reasonController.text.trim());
  }

  Future<void> _performDelete(Order order, String reason) async {
    setState(() => _deleting = true);
    try {
      await ref.read(orderRepositoryProvider).softDeleteOrder(
            widget.orderId,
            reason: reason.isNotEmpty ? reason : null,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // ignore: unused_result
      ref.refresh(adminArchivedOrdersProvider);
      // ignore: unused_result
      ref.refresh(adminAllOrdersProvider);
      // ignore: unused_result
      ref.refresh(dashboardStatsProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not delete order. Please try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

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

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _statusUpdating = true);
    try {
      await ref
          .read(orderRepositoryProvider)
          .updateOrderStatus(widget.orderId, newStatus);
      // ignore: unused_result
      ref.refresh(adminOrderDetailProvider(widget.orderId));
      // ignore: unused_result
      ref.refresh(adminAllOrdersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to ${_statusLabel(newStatus)}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _statusUpdating = false);
    }
  }

  void _showShareOptions(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Share Order PDF',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Customer Confirmation Slip'),
              subtitle: const Text('Includes prices as INR'),
              onTap: () {
                Navigator.pop(ctx);
                _generateAndSharePdf(order, 'customer');
              },
            ),
            ListTile(
              leading: const Icon(Icons.engineering_outlined),
              title: const Text('Karigar Slip (Labour)'),
              subtitle: const Text('No prices, English-only'),
              onTap: () {
                Navigator.pop(ctx);
                _generateAndSharePdf(order, 'labour');
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Admin Internal Slip'),
              subtitle: const Text('Includes prices and customer contact info'),
              onTap: () {
                Navigator.pop(ctx);
                _generateAndSharePdf(order, 'admin');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndSharePdf(Order order, String variant) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Generating PDF...'),
          ],
        ),
        duration: Duration(days: 1),
      ),
    );

    try {
      final imageLookup =
          await ref.read(itemRepositoryProvider).getImageLookup();
      Uint8List pdfBytes;
      String filename;
      switch (variant) {
        case 'customer':
          pdfBytes = await OrderPdfService.generateCustomerPdf(order,
              imageLookup: imageLookup);
          filename = 'order_${order.orderId}_customer.pdf';
          break;
        case 'labour':
          pdfBytes = await OrderPdfService.generateLabourPdf(order,
              imageLookup: imageLookup);
          filename = 'order_${order.orderId}_karigar.pdf';
          break;
        case 'admin':
        default:
          pdfBytes = await OrderPdfService.generateAdminPdf(order,
              imageLookup: imageLookup);
          filename = 'order_${order.orderId}_admin.pdf';
          break;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: filename,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share PDF: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(adminOrderDetailProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.orderId}'),
        actions: orderAsync.whenOrNull(
          data: (order) => order != null
              ? [
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () => _showShareOptions(context, order),
                  ),
                ]
              : null,
        ),
      ),
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
                      ref.refresh(adminOrderDetailProvider(widget.orderId)),
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
    final dateStr = _formatDate(order.orderDate);

    return RefreshIndicator(
      onRefresh: () =>
          ref.refresh(adminOrderDetailProvider(widget.orderId).future),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Customer info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(order.customerName,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
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
                              color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (order.customerMobile != null &&
                      order.customerMobile!.isNotEmpty)
                    _infoRow(Icons.phone_outlined, order.customerMobile!),
                  _infoRow(Icons.calendar_today, dateStr),
                  if (order.orderId != null)
                    _infoRow(Icons.receipt, 'Order #${order.orderId}'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Status actions
          _StatusActions(
            currentStatus: order.status,
            updating: _statusUpdating,
            onUpdateStatus: _updateStatus,
          ),

          const SizedBox(height: 16),

          // Items section
          Text('Items (${order.orderItems.length})',
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),

          if (order.orderItems.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                    child: Text('No items in this order',
                        style: TextStyle(color: Colors.grey))),
              ),
            )
          else
            ...order.orderItems.map((item) => _OrderItemCard(item: item)),

          const SizedBox(height: 12),

          // Grand total
          Card(
            color: const Color(0xFF1565C0).withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Text('Grand Total',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text(
                    '₹${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1565C0)),
                  ),
                ],
              ),
            ),
          ),

          // Danger Zone — soft delete for archived orders
          if (order.status == 'completed' || order.status == 'cancelled')
            if (order.deletedAt == null) ...[
              const SizedBox(height: 24),
              Card(
                color: Colors.red.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Danger Zone',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'This action will remove the order from all lists. '
                        'Order data is preserved in the database.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed:
                              _deleting ? null : () => _confirmDelete(order),
                          icon: _deleting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.delete_outline, size: 18),
                          label:
                              Text(_deleting ? 'Deleting...' : 'Delete Order'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

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
          Text(text,
              style: const TextStyle(fontSize: 13, color: Colors.black87)),
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

class _StatusActions extends StatelessWidget {
  final String currentStatus;
  final bool updating;
  final void Function(String newStatus) onUpdateStatus;

  const _StatusActions({
    required this.currentStatus,
    required this.updating,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (currentStatus == 'completed' || currentStatus == 'cancelled') {
      return const SizedBox.shrink();
    }

    final actions = <Widget>[];

    if (currentStatus == 'pending') {
      actions.addAll([
        Expanded(
          child: _StatusButton(
            label: 'Confirm',
            icon: Icons.check_circle_outline,
            color: const Color(0xFF1565C0),
            loading: updating,
            onPressed: () => onUpdateStatus('confirmed'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatusButton(
            label: 'Cancel',
            icon: Icons.cancel_outlined,
            color: const Color(0xFFC62828),
            loading: updating,
            onPressed: () => onUpdateStatus('cancelled'),
          ),
        ),
      ]);
    } else if (currentStatus == 'confirmed') {
      actions.addAll([
        Expanded(
          child: _StatusButton(
            label: 'Complete',
            icon: Icons.verified_outlined,
            color: const Color(0xFF2E7D32),
            loading: updating,
            onPressed: () => onUpdateStatus('completed'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatusButton(
            label: 'Cancel',
            icon: Icons.cancel_outlined,
            color: const Color(0xFFC62828),
            loading: updating,
            onPressed: () => onUpdateStatus('cancelled'),
          ),
        ),
      ]);
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: actions),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback? onPressed;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 13)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
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
                Text(
                  '₹${item.unitPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (item.color != null && item.color!.isNotEmpty)
              _detailChip('Color', item.color!),
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
              _detailChip(
                  'Qty',
                  item.quantity.toStringAsFixed(
                      item.quantity == item.quantity.roundToDouble() ? 0 : 2)),
            ],
            if (item.customization != null) ...[
              const SizedBox(height: 8),
              _buildCustomisationSection(item.customization!),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                const Spacer(),
                Text(
                  'Line Total: ₹${item.lineTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1565C0)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailChip(String label, String value) {
    return Text(
      '$label: $value',
      style: const TextStyle(fontSize: 12, color: Colors.black87),
    );
  }

  Widget _sizeChip(String size, int qty) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$size: $qty',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildCustomisationSection(Map<String, dynamic> c) {
    final pattiName = c['pattiName'] as String? ?? '';
    final pattiDiff = (c['pattiPriceDiff'] as num?)?.toDouble() ?? 0;
    final colorName = c['colorName'] as String? ?? '';
    final colorDiff = (c['colorPriceDiff'] as num?)?.toDouble() ?? 0;
    final customColorText = c['customColorText'] as String?;
    final boxName = c['boxName'] as String? ?? '';
    final boxDiff = (c['boxPriceDiff'] as num?)?.toDouble() ?? 0;
    final totalDiff = (c['totalDifference'] as num?)?.toDouble() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chooda Customisation',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB8860B))),
        const SizedBox(height: 4),
        _customChip('Patti', pattiName, pattiDiff),
        _customChip(
            'Patti Color',
            customColorText != null ? 'Custom - "$customColorText"' : colorName,
            colorDiff),
        _customChip('Box', boxName, boxDiff),
        if (totalDiff > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('Customisation: +₹${totalDiff.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32))),
          ),
      ],
    );
  }

  Widget _customChip(String label, String value, double priceDiff) {
    final diffText = priceDiff > 0
        ? ' (+₹${priceDiff.toStringAsFixed(0)})'
        : priceDiff < 0
            ? ' (-₹${priceDiff.abs().toStringAsFixed(0)})'
            : ' (Included)';
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text('$label: $value$diffText',
          style: const TextStyle(fontSize: 11, color: Colors.black87)),
    );
  }
}

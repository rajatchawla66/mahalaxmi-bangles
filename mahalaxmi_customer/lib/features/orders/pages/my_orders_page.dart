import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mahalaxmi_shared/models/cart_state.dart';
import 'package:mahalaxmi_shared/models/order.dart';
import 'package:mahalaxmi_shared/providers/cart_provider.dart';
import 'package:mahalaxmi_shared/providers/repository_providers.dart';
import 'package:mahalaxmi_shared/services/order_pdf_service.dart';
import 'package:mahalaxmi_shared/services/repeat_order_item.dart';
import 'package:printing/printing.dart';
import '../providers/orders_provider.dart';
import '../../../app/theme.dart';
import '../../../core/error_messages.dart';

Color _statusColor(String status) {
  switch (status) {
    case 'confirmed':
      return const Color(0xFF1565C0);
    case 'completed':
      return const Color(0xFF2E7D32);
    case 'cancelled':
      return Colors.red;
    case 'pending':
    default:
      return kGold;
  }
}

String _statusLabel(String status) {
  return status[0].toUpperCase() + status.substring(1);
}

class MyOrdersPage extends ConsumerWidget {
  const MyOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(customerOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: kMuted),
                const SizedBox(height: 16),
                const Text('Could not load orders', style: TextStyle(fontSize: 16, color: kMuted)),
                const SizedBox(height: 4),
                Text(CustomerErrorMessages.fromError(err), style: const TextStyle(fontSize: 13, color: kMuted), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(customerOrdersProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 64, color: kGold),
                    const SizedBox(height: 16),
                    const Text('No orders yet', style: TextStyle(fontSize: 16, color: kDark)),
                    const SizedBox(height: 8),
                    const Text('Your orders will appear here once you place one', style: TextStyle(fontSize: 13, color: kMuted)),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/dashboard'),
                      icon: const Icon(Icons.store, size: 18),
                      label: const Text('Browse Catalogue'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(220, 48)),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(customerOrdersProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _OrderCard(order: orders[index]),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends ConsumerStatefulWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  ConsumerState<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<_OrderCard> {
  bool _expanded = false;

  Future<void> _shareOrderPdf(BuildContext context, Order order) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Generating PDF...'),
          ],
        ),
        duration: Duration(days: 1),
      ),
    );

    try {
      final imageLookup = await ref.read(itemRepositoryProvider).getImageLookup();
      final pdfBytes = await OrderPdfService.generateCustomerPdf(order, imageLookup: imageLookup);
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'order_${order.orderId}_confirmation.pdf',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to share PDF'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _showAddAgainSheet(OrderItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0D5C0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Add Again — ${item.itemNumber}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kDark)),
            const SizedBox(height: 4),
            Text('Repeat this item from your past order',
                style: const TextStyle(fontSize: 13, color: kMuted)),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _handleRepeatSame(item);
                },
                icon: const Icon(Icons.replay, size: 18),
                label: const Text('Repeat Same'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMaroon,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _handleRepeatWithChange(item);
                },
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Repeat with Change'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kMaroon,
                  side: const BorderSide(color: kMaroon),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel', style: TextStyle(color: kMuted)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRepeatSame(OrderItem orderItem) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    messenger.clearSnackBars();

    try {
      final repo = ref.read(itemRepositoryProvider);
      final rateItem = await repo.getItemByNumber(orderItem.itemNumber);
      final error = validateRepeatableItem(rateItem);
      if (error != null) {
        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(error),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }

      final cartItem = orderItemToCartItem(orderItem, rateItem!);
      final result = ref.read(cartProvider.notifier).addItem(cartItem, rateItem.category);

      if (!context.mounted) return;
      if (result is CartAddSuccess) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('${orderItem.itemNumber} — added to cart'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'View Cart',
              onPressed: () => router.push('/cart'),
            ),
          ),
        );
      } else if (result is CartValidationError) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(result.message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
          ),
        );
      } else if (result is CartMutationError) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(result.message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Failed to add item'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _handleRepeatWithChange(OrderItem orderItem) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    try {
      final repo = ref.read(itemRepositoryProvider);
      final rateItem = await repo.getItemByNumber(orderItem.itemNumber);
      final error = validateRepeatableItem(rateItem);
      if (error != null) {
        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(error),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }

      if (!mounted) return;
      context.push('/item/${Uri.encodeComponent(orderItem.itemNumber)}');
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Failed to load item'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final items = order.orderItems;
    final totalQty = items.fold<int>(0, (sum, item) => sum + (item.totalSizeQty > 0 ? item.totalSizeQty : item.quantity.toInt()));

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('#${order.orderId ?? '—'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kDark)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(order.status).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _statusLabel(order.status),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(order.status)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 12, color: kMuted),
                      const SizedBox(width: 4),
                      Text(order.orderDate, style: const TextStyle(fontSize: 12, color: kMuted)),
                      const Spacer(),
                      Text('${items.length} items · $totalQty sets', style: const TextStyle(fontSize: 12, color: kMuted)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Spacer(),
                      Text('₹${order.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
                      const SizedBox(width: 4),
                      Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 20, color: kMuted),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded && items.isNotEmpty)
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF0EBE0))),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                    child: Row(
                      children: [
                        const Text('Items', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted)),
                        const Spacer(),
                        const Text('Qty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted)),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 64,
                          child: Text('Total', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted)),
                        ),
                      ],
                    ),
                  ),
                  ...items.map((item) => _OrderItemRow(
                    item: item,
                    onAddAgain: () => _showAddAgainSheet(item),
                  )),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Order Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kDark)),
                        Text('₹${order.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _shareOrderPdf(context, order),
                          icon: const Icon(Icons.share, size: 14),
                          label: const Text('Share PDF Confirmation', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kMaroon,
                            side: const BorderSide(color: kMaroon),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final OrderItem item;
  final VoidCallback onAddAgain;

  const _OrderItemRow({required this.item, required this.onAddAgain});

  @override
  Widget build(BuildContext context) {
    final hasSizeQtys = item.totalSizeQty > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.itemNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kDark)),
                    if (item.color != null && item.color!.isNotEmpty)
                      Text(item.color!, style: const TextStyle(fontSize: 11, color: kMuted)),
                    if (item.customization != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _buildCustomisationChips(item.customization!),
                      ),
                  ],
                ),
              ),
              Text(
                hasSizeQtys ? '${item.totalSizeQty}' : '${item.quantity.toInt()}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kDark),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 64,
                child: Text(
                  '₹${item.lineTotal.toStringAsFixed(0)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
                ),
              ),
            ],
          ),
          if (hasSizeQtys)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Wrap(
                spacing: 4,
                runSpacing: 2,
                children: [
                  if (item.qty22 > 0) _chip('2.2: ${item.qty22}'),
                  if (item.qty24 > 0) _chip('2.4: ${item.qty24}'),
                  if (item.qty26 > 0) _chip('2.6: ${item.qty26}'),
                  if (item.qty28 > 0) _chip('2.8: ${item.qty28}'),
                  if (item.qty210 > 0) _chip('2.10: ${item.qty210}'),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onAddAgain,
              icon: const Icon(Icons.add_circle_outline, size: 14),
              label: const Text('Add Again', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: kMaroon,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE0D5C0)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10, color: kDark)),
    );
  }

  Widget _buildCustomisationChips(Map<String, dynamic> c) {
    final pattiName = c['pattiName'] as String? ?? '';
    final pattiDiff = (c['pattiPriceDiff'] as num?)?.toDouble() ?? 0;
    final colorName = c['colorName'] as String? ?? '';
    final customColorText = c['customColorText'] as String?;
    final boxName = c['boxName'] as String? ?? '';
    final boxDiff = (c['boxPriceDiff'] as num?)?.toDouble() ?? 0;
    final totalDiff = (c['totalDifference'] as num?)?.toDouble() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chooda Customisation',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kGold)),
        const SizedBox(height: 2),
        Wrap(
          spacing: 4,
          runSpacing: 2,
          children: [
            _chip('Patti: $pattiName${_diffSuffix(pattiDiff)}'),
            _chip('Color: ${customColorText ?? colorName}${_diffSuffix(0)}'),
            _chip('Box: $boxName${_diffSuffix(boxDiff)}'),
            if (totalDiff > 0) _chip('+₹${totalDiff.toStringAsFixed(0)}'),
          ],
        ),
      ],
    );
  }

  String _diffSuffix(double diff) {
    if (diff == 0) return '';
    if (diff > 0) return ' (+₹${diff.toStringAsFixed(0)})';
    return ' (-₹${diff.abs().toStringAsFixed(0)})';
  }
}

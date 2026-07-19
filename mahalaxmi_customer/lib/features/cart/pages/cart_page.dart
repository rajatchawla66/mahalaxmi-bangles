import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mahalaxmi_shared/models/cart_state.dart';
import 'package:mahalaxmi_shared/models/chuda_customization_snapshot.dart';
import 'package:mahalaxmi_shared/providers/cart_provider.dart';
import 'package:mahalaxmi_shared/providers/order_builder_provider.dart';
import 'package:mahalaxmi_shared/providers/repository_providers.dart';
import 'package:mahalaxmi_shared/providers/session_provider.dart';
import 'package:mahalaxmi_shared/services/calculation.dart';
import 'package:mahalaxmi_shared/services/customer_order_service.dart';
import 'package:mahalaxmi_shared/services/order_pdf_service.dart';
import 'package:printing/printing.dart';
import '../../../app/theme.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  bool _placing = false;

  void _showConfirmation() {
    final cart = ref.read(cartProvider);
    final session = ref.read(appSessionProvider);
    final totalQty = cart.items.fold<int>(
      0,
      (sum, item) => sum + (item.hasSizes ? item.totalSizeQty : item.quantity.toInt()),
    );
    final lineTotals = cart.items
        .map((item) => calculateLineTotal(item, item.category, item.unitPrice))
        .toList();
    final grandTotal = lineTotals.fold(0.0, (a, b) => a + b);

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
            const Text('Confirm Order', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kDark)),
            const SizedBox(height: 20),
            _confRow('Shop', session.customerShopName ?? '—'),
            _confRow('Items', '${cart.lines.length} items · $totalQty sets'),
            _confRow('Total', '₹${grandTotal.toStringAsFixed(0)}'),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _placeOrder();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMaroon,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                child: const Text('Confirm Order'),
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

  Widget _confRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: kMuted)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kDark)),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    setState(() => _placing = true);

    final result = await ref.read(orderBuilderProvider).placeCustomerOrder();

    if (!mounted) return;
    setState(() => _placing = false);

    if (result is CustomerOrderSuccess) {
      ref.read(cartProvider.notifier).clear();
      _showSuccess(result.orderId);
    } else if (result is NotLoggedIn) {
      _showError('Please login again');
    } else if (result is EmptyCart) {
      _showError('Your cart is empty');
    } else if (result is InvalidCartItems) {
      _showError(result.message);
    } else if (result is OrderSaveFailed) {
      _showError('Order could not be saved. Please try again.');
    } else if (result is AccountDisabled) {
      _showError('Your account has been disabled. Please contact Mahalaxmi Bangles.');
    } else if (result is RollbackFailed) {
      _showError('Order failed safely. Please contact admin if issue continues.');
    }
  }

  Future<void> _shareOrderReceipt(BuildContext context, int orderId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Fetching order details & generating PDF...'),
          ],
        ),
        duration: Duration(days: 1),
      ),
    );

    try {
      final order = await ref.read(orderRepositoryProvider).getOrderById(orderId);
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();

      if (order == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order details could not be found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final imageLookup = await ref.read(itemRepositoryProvider).getImageLookup();
      final pdfBytes = await OrderPdfService.generateCustomerPdf(order, imageLookup: imageLookup);
      
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

  void _showSuccess(int orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 56, color: Color(0xFF2E7D32)),
            const SizedBox(height: 16),
            const Text('Order Placed!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kDark)),
            const SizedBox(height: 8),
            Text('Order #$orderId', style: const TextStyle(fontSize: 14, color: kMuted)),
            const SizedBox(height: 4),
            const Text('Your order has been placed successfully.', style: TextStyle(fontSize: 13, color: kMuted)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => _shareOrderReceipt(context, orderId),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share PDF Receipt'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kMaroon,
                  side: const BorderSide(color: kMaroon),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go('/dashboard');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMaroon,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Continue Shopping'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    if (cart.lines.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_cart_outlined, size: 72, color: kGold),
                const SizedBox(height: 20),
                const Text('Your cart is empty', style: TextStyle(fontSize: 18, color: kDark)),
                const SizedBox(height: 8),
                const Text('Browse our catalogue and add items you like', style: TextStyle(fontSize: 13, color: kMuted)),
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
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Cart (${cart.lines.length})'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
              itemCount: cart.lines.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _CartLineCard(line: cart.lines[index]),
            ),
          ),
          _buildSummaryBar(cart),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(CartState cart) {
    final totalQty = cart.items.fold<int>(
      0,
      (sum, item) => sum + (item.hasSizes ? item.totalSizeQty : item.quantity.toInt()),
    );

    final lineTotals = cart.items
        .map((item) => calculateLineTotal(item, item.category, item.unitPrice))
        .toList();
    final grandTotal = lineTotals.fold(0.0, (a, b) => a + b);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: const Color(0xFFE0D5C0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${cart.lines.length} items · $totalQty sets', style: const TextStyle(fontSize: 13, color: kMuted)),
                Text('₹${grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _placing ? null : _showConfirmation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMaroon,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                child: _placing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Place Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartLineCard extends ConsumerWidget {
  final CartLine line;

  const _CartLineCard({required this.line});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = line.item;
    final lineTotal = calculateLineTotal(item, item.category, item.unitPrice);
    final totalQty = item.hasSizes ? item.totalSizeQty : item.quantity.toInt();
    final hasSizeQtys = item.hasSizes && item.totalSizeQty > 0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                      Text(item.itemNumber, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kDark)),
                      const SizedBox(height: 2),
                      Text(item.category.replaceAll('_', ' '), style: const TextStyle(fontSize: 11, color: kMuted)),
                      if (item.color != null && item.color!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.palette, size: 12, color: kMuted),
                            const SizedBox(width: 4),
                            Text(item.color!, style: const TextStyle(fontSize: 11, color: kMuted)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${lineTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
                    Text('₹${item.unitPrice.toStringAsFixed(0)}/set', style: const TextStyle(fontSize: 10, color: kMuted)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (hasSizeQtys) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (item.qty22 > 0) _sizeChip('2.2', item.qty22),
                  if (item.qty24 > 0) _sizeChip('2.4', item.qty24),
                  if (item.qty26 > 0) _sizeChip('2.6', item.qty26),
                  if (item.qty28 > 0) _sizeChip('2.8', item.qty28),
                  if (item.qty210 > 0) _sizeChip('2.10', item.qty210),
                  if (item.qty212 > 0) _sizeChip('2.12', item.qty212),
                ],
              ),
              const SizedBox(height: 6),
            ] else ...[
              Row(
                children: [
                  const Text('Qty: ', style: TextStyle(fontSize: 12, color: kMuted)),
                  Text('${item.quantity.toInt()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kDark)),
                ],
              ),
              const SizedBox(height: 6),
            ],
            if (item.customization != null) ...[
              const SizedBox(height: 4),
              _buildCustomizationChips(item.customization!),
              const SizedBox(height: 6),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$totalQty sets', style: const TextStyle(fontSize: 11, color: kMuted)),
                SizedBox(
                  height: 32,
                  child: TextButton.icon(
                    onPressed: () => ref.read(cartProvider.notifier).removeItem(line.id),
                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                    label: const Text('Remove', style: TextStyle(fontSize: 12, color: Colors.red)),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sizeChip(String label, int qty) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE0D5C0)),
      ),
      child: Text('$label: $qty', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: kDark)),
    );
  }

  Widget _buildCustomizationChips(ChudaCustomizationSnapshot c) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _chip('Patti: ${c.pattiName}'),
        _chip('Color: ${c.customColorText ?? c.colorName}'),
        _chip('Box: ${c.boxName}'),
        if (c.totalDifference > 0)
          _chip('+₹${c.totalDifference.toStringAsFixed(0)}', Colors.orange.shade700),
      ],
    );
  }

  Widget _chip(String text, [Color? textColor]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE0D5C0)),
      ),
      child: Text(text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor ?? kDark,
        ),
      ),
    );
  }
}

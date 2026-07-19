import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mahalaxmi_shared/models/order.dart';
import 'package:mahalaxmi_shared/models/cutmail.dart';
import 'package:mahalaxmi_shared/providers/repository_providers.dart';

import '../../../providers/labour_auth_provider.dart';
import '../../orders/providers/labour_orders_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(labourOrdersProvider);
    final cutmailsAsync = ref.watch(_labourCutmailsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mahalaxmi Labour'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await ref.read(labourAuthControllerProvider).logout();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // ignore: unused_result
          ref.refresh(labourOrdersProvider);
          // ignore: unused_result
          ref.refresh(_labourCutmailsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- Orders Section ---
            Row(
              children: [
                const Icon(Icons.receipt_long, size: 20),
                const SizedBox(width: 8),
                const Text('Orders',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => context.push('/orders/create'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Order'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ordersAsync.when(
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (err, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_off, size: 40, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text('Could not load orders',
                            style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          onPressed: () => ref.refresh(labourOrdersProvider),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (orders) => _buildOrdersList(context, ref, orders),
            ),

            const SizedBox(height: 24),

            // --- Cutmails Section ---
            Row(
              children: [
                const Icon(Icons.checklist, size: 20),
                const SizedBox(width: 8),
                const Text('Stock Check (Cutmails)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => context.push('/cutmail/add'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            cutmailsAsync.when(
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (err, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text('Could not load cutmails',
                        style: TextStyle(color: Colors.grey.shade600)),
                  ),
                ),
              ),
              data: (cutmails) => _buildCutmailsList(context, cutmails),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context, WidgetRef ref, List<Order> orders) {
    if (orders.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined, size: 40, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text('No orders yet', style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          ),
        ),
      );
    }

    final active = orders.where((o) =>
        o.status == 'pending' || o.status == 'confirmed').toList();
    final display = active.isNotEmpty ? active : orders;

    return Column(
      children: display.take(10).map((order) => Card(
        margin: const EdgeInsets.only(bottom: 6),
        child: ListTile(
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: _statusColor(order.status).withValues(alpha: 0.15),
            child: Text(
              '${order.orderId}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: _statusColor(order.status),
              ),
            ),
          ),
          title: Text(
            'Order #${order.orderId}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Row(
            children: [
              Text(_formatDate(order.orderDate),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: _statusColor(order.status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _statusLabel(order.status),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(order.status),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${order.orderItems.length} item${order.orderItems.length == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: () => context.push('/orders/${order.orderId}'),
        ),
      )).toList(),
    );
  }

  Widget _buildCutmailsList(BuildContext context, List<Cutmail> cutmails) {
    if (cutmails.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.checklist_outlined, size: 40, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text('No stock checks yet',
                    style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: cutmails.take(5).map((c) => Card(
        margin: const EdgeInsets.only(bottom: 6),
        child: ListTile(
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: _cutmailStatusColor(c.status).withValues(alpha: 0.15),
            child: Icon(
              Icons.checklist,
              size: 16,
              color: _cutmailStatusColor(c.status),
            ),
          ),
          title: Text(
            c.itemNumberSnapshot ?? c.itemNameSnapshot,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Row(
            children: [
              if (c.createdAt != null)
                Text(_formatDate(c.createdAt!.toIso8601String()),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: _cutmailStatusColor(c.status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  c.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _cutmailStatusColor(c.status),
                  ),
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
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

  Color _cutmailStatusColor(String status) {
    return switch (status) {
      'pending' => const Color(0xFFF9A825),
      'reviewed' => const Color(0xFF2E7D32),
      'archived' => Colors.grey,
      _ => Colors.grey,
    };
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM, h:mm a').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}

final _labourCutmailsProvider = FutureProvider<List<Cutmail>>((ref) async {
  final repo = ref.read(cutmailRepositoryProvider);
  return await repo.getCutmails(limit: 20);
});

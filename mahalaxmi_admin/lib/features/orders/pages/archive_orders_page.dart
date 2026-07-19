import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mahalaxmi_shared/models/order.dart';
import '../providers/admin_orders_provider.dart';

final class _OrderStatusTab {
  final String label;
  final String? statusFilter;

  const _OrderStatusTab(this.label, this.statusFilter);
}

const _tabs = [
  _OrderStatusTab('All', null),
  _OrderStatusTab('Completed', 'completed'),
  _OrderStatusTab('Cancelled', 'cancelled'),
];

class ArchiveOrdersPage extends ConsumerStatefulWidget {
  const ArchiveOrdersPage({super.key});

  @override
  ConsumerState<ArchiveOrdersPage> createState() => _ArchiveOrdersPageState();
}

class _ArchiveOrdersPageState extends ConsumerState<ArchiveOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(adminArchivedOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archive Orders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
        ),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text('Could not load archived orders',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('$err', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.refresh(adminArchivedOrdersProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (orders) => _ArchiveOrdersTabView(
          orders: orders,
          tabController: _tabController,
          onRefresh: () => ref.refresh(adminArchivedOrdersProvider.future),
        ),
      ),
    );
  }
}

class _ArchiveOrdersTabView extends StatelessWidget {
  final List<Order> orders;
  final TabController tabController;
  final Future<void> Function() onRefresh;

  const _ArchiveOrdersTabView({
    required this.orders,
    required this.tabController,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: tabController,
      children: _tabs.map((tab) {
        final filtered = tab.statusFilter == null
            ? orders
            : orders.where((o) => o.status == tab.statusFilter).toList();
        return _ArchiveOrderList(
          orders: filtered,
          onRefresh: onRefresh,
        );
      }).toList(),
    );
  }
}

class _ArchiveOrderList extends StatelessWidget {
  final List<Order> orders;
  final Future<void> Function() onRefresh;

  const _ArchiveOrderList({required this.orders, required this.onRefresh});

  Color _statusColor(String status) {
    return switch (status) {
      'pending' => const Color(0xFFF9A825),
      'confirmed' => const Color(0xFF1565C0),
      'completed' => const Color(0xFF2E7D32),
      'cancelled' => const Color(0xFFC62828),
      _ => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.archive_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('No archived orders found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final statusColor = _statusColor(order.status);
          final dateStr = _formatDate(order.orderDate);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push('/orders/${order.orderId}'),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Order #${order.orderId}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  order.status.toUpperCase(),
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.customerName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateStr,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${order.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${order.orderItems.length} items',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        },
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

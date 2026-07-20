import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mahalaxmi_shared/models/order.dart';
import 'package:mahalaxmi_shared/models/cutmail.dart';

import '../providers/admin_dashboard_data_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(adminDashboardDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshDashboard(ref),
          ),
        ],
      ),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text('Could not load dashboard',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('Something went wrong',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _refreshDashboard(ref),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () => _refreshDashboardFuture(ref),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              _QuickActions(),
              const SizedBox(height: 20),
              _MainSummaryCards(data: data),
              const SizedBox(height: 20),
              if (data.missingPriceItems.isNotEmpty ||
                  data.categoriesMissingCover > 0 ||
                  data.pendingCutmailCount > 0 ||
                  data.unavailableItems > 0)
                _NeedsAttention(data: data),
              const SizedBox(height: 20),
              _RecentOrdersSection(data: data),
              const SizedBox(height: 20),
              _LatestCutmailSection(data: data),
              const SizedBox(height: 20),
              _CatalogueHealth(data: data),
            ],
          ),
        ),
      ),
    );
  }

  void _refreshDashboard(WidgetRef ref) {
    ref.invalidate(adminDashboardDataProvider);
  }

  Future<void> _refreshDashboardFuture(WidgetRef ref) async {
    ref.invalidate(adminDashboardDataProvider);
    await ref.read(adminDashboardDataProvider.future);
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text('Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _ActionCard(
                icon: Icons.add_shopping_cart,
                label: 'Create Order',
                color: const Color(0xFF1565C0),
                onTap: () => context.push('/orders/create'),
              ),
              const SizedBox(width: 10),
              _ActionCard(
                icon: Icons.add_box_outlined,
                label: 'Add Item',
                color: const Color(0xFF2E7D32),
                onTap: () => context.push('/catalogue/add'),
              ),
              const SizedBox(width: 10),
              _ActionCard(
                icon: Icons.person_add_outlined,
                label: 'Add Customer',
                color: const Color(0xFFE65100),
                onTap: () => context.push('/customers/create'),
              ),
              const SizedBox(width: 10),
              _ActionCard(
                icon: Icons.checklist_outlined,
                label: 'View Cutmail',
                color: const Color(0xFF6A1B9A),
                onTap: () => context.push('/cutmail'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({required this.title, required this.value, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color, height: 1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MainSummaryCards extends StatelessWidget {
  final AdminDashboardData data;

  const _MainSummaryCards({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text('Orders',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Pending',
                value: '${data.pendingOrders}',
                color: const Color(0xFFF9A825),
                onTap: () => context.push('/orders?status=pending'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                title: 'Confirmed',
                value: '${data.confirmedOrders}',
                color: const Color(0xFF1565C0),
                onTap: () => context.push('/orders?status=confirmed'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Completed',
                value: '${data.completedOrders}',
                color: const Color(0xFF2E7D32),
                onTap: () => context.push('/orders?status=completed'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                title: 'Cancelled',
                value: '${data.cancelledOrders}',
                color: const Color(0xFFC62828),
                onTap: () => context.push('/orders?status=cancelled'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Pending Cutmail',
                value: '${data.pendingCutmailCount}',
                color: const Color(0xFF6A1B9A),
                onTap: () => context.push('/cutmail'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                title: 'Active Customers',
                value: '${data.activeCustomers}',
                color: const Color(0xFF2E7D32),
                onTap: () => context.push('/customers'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NeedsAttention extends StatelessWidget {
  final AdminDashboardData data;

  const _NeedsAttention({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFE65100)),
              const SizedBox(width: 6),
              Text('Needs Attention',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        if (data.missingPriceItems.isNotEmpty)
          _AlertTile(
            icon: Icons.money_off,
            label: 'Items without price',
            count: data.missingPriceItems.length,
            subtitle: 'Hidden from customer catalogue',
            onTap: () => context.push('/catalogue/missing-price'),
          ),
        if (data.categoriesMissingCover > 0)
          _AlertTile(
            icon: Icons.image_not_supported_outlined,
            label: 'Categories missing cover',
            count: data.categoriesMissingCover,
            subtitle: 'No cover image set',
            onTap: () => context.push('/settings/categories'),
          ),
        if (data.pendingCutmailCount > 0)
          _AlertTile(
            icon: Icons.rate_review_outlined,
            label: 'Cutmails pending review',
            count: data.pendingCutmailCount,
            onTap: () => context.push('/cutmail'),
          ),
        if (data.unavailableItems > 0)
          _AlertTile(
            icon: Icons.visibility_off_outlined,
            label: 'Unavailable items',
            count: data.unavailableItems,
            subtitle: 'Not visible to customers',
            onTap: () => context.go('/catalogue'),
          ),
      ],
    );
  }
}

class _AlertTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final String? subtitle;
  final VoidCallback onTap;

  const _AlertTile({
    required this.icon,
    required this.label,
    required this.count,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFFDE8E8),
          child: Icon(icon, color: const Color(0xFFC62828), size: 18),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 11)) : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFC62828).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('$count', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFC62828))),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _RecentOrdersSection extends StatelessWidget {
  final AdminDashboardData data;

  const _RecentOrdersSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => context.push('/orders'),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text('Recent Orders',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('View All', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                Icon(Icons.chevron_right, size: 16, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
        ),
        if (data.recentOrders.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('No orders yet', style: TextStyle(color: Colors.grey, fontSize: 13))),
          )
        else
          ...data.recentOrders.map((order) => _OrderListItem(order: order)),
      ],
    );
  }
}

class _OrderListItem extends StatelessWidget {
  final Order order;

  const _OrderListItem({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    final dateStr = _formatDate(order.orderDate);
    final amount = order.totalAmount > 0 ? '₹${NumberFormat('#,##0').format(order.totalAmount)}' : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        onTap: () => context.push('/orders/${order.orderId}'),
        title: Text('Order #${order.orderId ?? '?'}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          '${order.customerName} · $dateStr${amount.isNotEmpty ? ' · $amount' : ''}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            order.status.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF9A825);
      case 'confirmed':
        return const Color(0xFF1565C0);
      case 'completed':
        return const Color(0xFF2E7D32);
      case 'cancelled':
        return const Color(0xFFC62828);
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}

class _LatestCutmailSection extends StatelessWidget {
  final AdminDashboardData data;

  const _LatestCutmailSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('Latest Cutmail',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ),
        if (data.latestCutmails.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('No cutmail reports yet', style: TextStyle(color: Colors.grey, fontSize: 13))),
          )
        else
          ...data.latestCutmails.map((cutmail) => _CutmailListItem(cutmail: cutmail)),
      ],
    );
  }
}

class _CutmailListItem extends StatelessWidget {
  final Cutmail cutmail;

  const _CutmailListItem({required this.cutmail});

  @override
  Widget build(BuildContext context) {
    final statusColor = _cutmailStatusColor(cutmail.status);
    final dateStr = cutmail.createdAt != null
        ? DateFormat('dd MMM yyyy').format(cutmail.createdAt!)
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        onTap: () => context.push('/cutmail/${cutmail.id}'),
        title: Text(
          cutmail.itemNameSnapshot,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${cutmail.categoryName}${cutmail.checkedByName != null ? ' · ${cutmail.checkedByName}' : ''}${dateStr.isNotEmpty ? ' · $dateStr' : ''}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            cutmail.status.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
          ),
        ),
      ),
    );
  }

  Color _cutmailStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF9A825);
      case 'reviewed':
        return const Color(0xFF2E7D32);
      case 'archived':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

class _CatalogueHealth extends StatelessWidget {
  final AdminDashboardData data;

  const _CatalogueHealth({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text('Catalogue Health',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ),
        Row(
          children: [
            Expanded(child: _HealthStat(label: 'Total Items', value: '${data.totalItems}', color: const Color(0xFF1565C0))),
            const SizedBox(width: 8),
            Expanded(child: _HealthStat(label: 'Available', value: '${data.availableItems}', color: const Color(0xFF2E7D32))),
            const SizedBox(width: 8),
            Expanded(child: _HealthStat(label: 'Unavailable', value: '${data.unavailableItems}', color: data.unavailableItems > 0 ? const Color(0xFFE65100) : Colors.grey)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _HealthStat(label: 'Categories', value: '${data.totalCategories}', color: const Color(0xFF6A1B9A))),
            const SizedBox(width: 8),
            Expanded(child: _HealthStat(label: 'Customers', value: '${data.totalCustomers}', color: const Color(0xFF1565C0))),
            const SizedBox(width: 8),
            Expanded(child: _HealthStat(label: 'Active Cust.', value: '${data.activeCustomers}', color: const Color(0xFF2E7D32))),
          ],
        ),
      ],
    );
  }
}

class _HealthStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HealthStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color, height: 1)),
          ],
        ),
      ),
    );
  }
}

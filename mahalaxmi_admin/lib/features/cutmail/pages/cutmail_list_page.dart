import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mahalaxmi_shared/models/cutmail.dart';
import 'package:mahalaxmi_shared/providers/categories_provider.dart';

import '../providers/admin_cutmail_provider.dart';

final class _StatusTab {
  final String label;
  final String? filter;
  const _StatusTab(this.label, this.filter);
}

const _tabs = [
  _StatusTab('Pending', 'pending'),
  _StatusTab('Reviewed', 'reviewed'),
  _StatusTab('Archived', 'archived'),
  _StatusTab('All', 'all'),
];

class CutmailListPage extends ConsumerStatefulWidget {
  const CutmailListPage({super.key});

  @override
  ConsumerState<CutmailListPage> createState() => _CutmailListPageState();
}

class _CutmailListPageState extends ConsumerState<CutmailListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _categoryFilter;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String? get _currentStatusFilter => _tabs[_tabController.index].filter;

  @override
  Widget build(BuildContext context) {
    final cutmailsAsync = ref.watch(
      adminCutmailsByStatusProvider(_currentStatusFilter),
    );
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cutmail'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by item name/number...',
                      isDense: true,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                categoriesAsync.when(
                  data: (cats) => PopupMenuButton<String?>(
                    icon: Icon(
                      Icons.filter_list,
                      color: _categoryFilter != null
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    tooltip: 'Filter by category',
                    onSelected: (val) => setState(() => _categoryFilter = val),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      ...cats.map((cat) => PopupMenuItem(
                            value: cat.name,
                            child: Text(cat.name.replaceAll('_', ' ')),
                          )),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Expanded(
            child: cutmailsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text('Could not load cutmails',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('$err',
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () {
                          // ignore: unused_result
                          ref.refresh(
                            adminCutmailsByStatusProvider(_currentStatusFilter),
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (cutmails) {
                var filtered = cutmails;

                if (_categoryFilter != null) {
                  filtered = filtered
                      .where((c) => c.categoryName == _categoryFilter)
                      .toList();
                }

                final search = _searchController.text.trim().toLowerCase();
                if (search.isNotEmpty) {
                  filtered = filtered.where((c) {
                    return c.itemNameSnapshot.toLowerCase().contains(search) ||
                        (c.itemNumberSnapshot?.toLowerCase().contains(search) ?? false);
                  }).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.checklist, size: 48,
                            color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          cutmails.isEmpty
                              ? 'No cutmails found'
                              : 'No matching cutmails',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.refresh(
                    adminCutmailsByStatusProvider(_currentStatusFilter).future,
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final cutmail = filtered[index];
                      return _CutmailCard(
                        cutmail: cutmail,
                        onTap: () => context.push('/cutmail/${cutmail.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CutmailCard extends StatelessWidget {
  final Cutmail cutmail;
  final VoidCallback onTap;

  const _CutmailCard({required this.cutmail, required this.onTap});

  Color _statusColor(String status) {
    switch (status) {
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

  @override
  Widget build(BuildContext context) {
    final dateStr = cutmail.createdAt != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(cutmail.createdAt!)
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: cutmail.imageUrlSnapshot != null &&
                        cutmail.imageUrlSnapshot!.isNotEmpty
                    ? Image.network(
                        cutmail.imageUrlSnapshot!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderImage(),
                      )
                    : _placeholderImage(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cutmail.itemNumberSnapshot ?? cutmail.itemNameSnapshot,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _statusColor(cutmail.status).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            cutmail.status[0].toUpperCase() +
                                cutmail.status.substring(1),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _statusColor(cutmail.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cutmail.categoryName.replaceAll('_', ' '),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    if (dateStr.isNotEmpty)
                      Text(dateStr,
                          style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                    if (cutmail.checkedByName != null)
                      Text('by ${cutmail.checkedByName}',
                          style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 56,
      height: 56,
      color: Colors.grey[200],
      child: const Icon(Icons.image, color: Colors.grey, size: 28),
    );
  }
}

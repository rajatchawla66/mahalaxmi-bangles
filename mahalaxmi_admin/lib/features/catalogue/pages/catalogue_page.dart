import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_catalogue_provider.dart';

class CataloguePage extends ConsumerWidget {
  const CataloguePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(adminCategoriesWithStatsProvider);
    final missingPriceAsync = ref.watch(adminMissingPriceItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalogue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // ignore: unused_result
              ref.refresh(adminCategoriesWithStatsProvider);
              // ignore: unused_result
              ref.refresh(adminMissingPriceItemsProvider);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'catalogue_add',
        onPressed: () => context.push('/catalogue/add'),
        child: const Icon(Icons.add),
      ),
      body: catsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text('Could not load catalogue',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('$err', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.refresh(adminCategoriesWithStatsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (cats) {
          final missingPriceCount = missingPriceAsync.whenOrNull(data: (items) => items.length) ?? 0;
          final hasMissingPrice = missingPriceCount > 0;

          if (cats.isEmpty && !hasMissingPrice) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.category_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No categories found', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final itemCount = cats.length + (hasMissingPrice ? 1 : 0);

          return RefreshIndicator(
            onRefresh: () async {
              // ignore: unused_result
              ref.refresh(adminCategoriesWithStatsProvider.future);
              // ignore: unused_result
              ref.refresh(adminMissingPriceItemsProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (hasMissingPrice) {
                  if (index == 0) {
                    return _MissingPriceWarningCard(count: missingPriceCount);
                  }
                  final c = cats[index - 1];
                  return _CategoryCard(cat: c);
                } else {
                  final c = cats[index];
                  return _CategoryCard(cat: c);
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _MissingPriceWarningCard extends StatelessWidget {
  final int count;

  const _MissingPriceWarningCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.orange.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/catalogue/missing-price'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded, color: Colors.orange.shade900, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price Not Available ($count)',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.orange.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Selling price not set. Tap to update pricing details.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.orange.shade900),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryWithStats cat;

  const _CategoryCard({required this.cat});

  @override
  Widget build(BuildContext context) {
    final displayName = cat.category.name.replaceAll('_', ' ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/catalogue/${Uri.encodeComponent(cat.category.name)}'),
        child: Row(
          children: [
            _buildImage(cat.category.coverImageUrl),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(displayName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        ),
                        if (!cat.category.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Inactive',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.orange)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _countChip('Total', '${cat.totalItems}', Colors.grey),
                        _countChip('Available', '${cat.availableItems}', const Color(0xFF2E7D32)),
                        if (cat.costedItems > 0)
                          _countChip('Costed', '${cat.costedItems}', const Color(0xFF1565C0)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.chevron_right, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String? url) {
    if (url != null && url.isNotEmpty) {
      return Container(
        width: 54, height: 72,
        decoration: BoxDecoration(color: Colors.grey.shade100),
        child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback()),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: 54, height: 72,
      color: const Color(0xFF1565C0).withValues(alpha: 0.1),
      child: const Icon(Icons.image_outlined, color: Colors.grey, size: 24),
    );
  }

  Widget _countChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$label: $value',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
    );
  }
}

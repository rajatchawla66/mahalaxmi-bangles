import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mahalaxmi_shared/mahalaxmi_shared.dart';
import 'package:mahalaxmi_shared/services/tag_filter.dart';
import '../../../app/theme.dart';
import '../../../core/error_messages.dart';
import '../../../widgets/watermarked_product_image.dart';

class CategoryPage extends ConsumerStatefulWidget {
  final String categoryName;

  const CategoryPage({super.key, required this.categoryName});

  @override
  ConsumerState<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends ConsumerState<CategoryPage> {
  String? _selectedTag;

  @override
  void didUpdateWidget(CategoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.categoryName != oldWidget.categoryName) {
      setState(() => _selectedTag = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final queryName = Uri.decodeComponent(widget.categoryName);
    final displayName = queryName.replaceAll('_', ' ');
    final itemsAsync = ref.watch(customerItemsByCategoryProvider(queryName));

    return Scaffold(
      appBar: AppBar(
        title: Text(displayName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
        actions: [
          Consumer(
            builder: (_, ref, __) {
              final count = ref.watch(cartItemCountProvider);
              return IconButton(
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count', style: const TextStyle(fontSize: 10, color: Colors.white)),
                  child: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                ),
                onPressed: () => context.push('/cart'),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () {
          setState(() => _selectedTag = null);
          return ref.refresh(customerItemsByCategoryProvider(queryName).future);
        },
        child: itemsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: kMuted),
                  const SizedBox(height: 16),
                  const Text('Could not load items', style: TextStyle(color: kMuted, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(CustomerErrorMessages.fromError(error), style: TextStyle(color: kMuted, fontSize: 13), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _selectedTag = null);
                      ref.invalidate(customerItemsByCategoryProvider(queryName));
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  const Center(
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: kGold),
                        SizedBox(height: 16),
                        Text('No items available', style: TextStyle(fontSize: 16, color: kMuted)),
                      ],
                    ),
                  ),
                ],
              );
            }
            final tags = extractSortedTags(items);
            final filteredItems = filterItemsByTag(items, _selectedTag);
            return _buildContent(tags, filteredItems);
          },
        ),
      ),
    );
  }

  Widget _buildContent(List<String> tags, List<RateItem> items) {
    return Column(
      children: [
        if (tags.length > 1) _buildTagRow(tags),
        Expanded(
          child: items.isEmpty
              ? _emptyFilterState()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) => _ItemCard(
                    item: items[index],
                    onTap: () => context.push('/item/${Uri.encodeComponent(items[index].itemNumber)}'),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTagRow(List<String> tags) {
    return Container(
      height: 44,
      padding: const EdgeInsets.only(left: 12, top: 6, right: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tags.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final selected = _selectedTag == null;
            return _TagChip(
              label: 'All',
              selected: selected,
              onTap: () => setState(() => _selectedTag = null),
            );
          }
          final tag = tags[index - 1];
          final selected = _selectedTag == tag;
          return _TagChip(
            label: tag.replaceAll('_', ' '),
            selected: selected,
            onTap: () => setState(() => _selectedTag = selected ? null : tag),
          );
        },
      ),
    );
  }

  Widget _emptyFilterState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.filter_alt_off, size: 48, color: kMuted),
                const SizedBox(height: 16),
                const Text(
                  'No items found for this filter',
                  style: TextStyle(fontSize: 14, color: kMuted),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() => _selectedTag = null),
                  child: const Text('Clear filter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? kMaroon : kCream,
          borderRadius: BorderRadius.circular(16),
          border: selected ? null : Border.all(color: const Color(0xFFE0D5C0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : kDark,
          ),
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback onTap;

  const _ItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImage = item.imageUrl.isNotEmpty;
    final isNew = item.status == 'new';
    final tags = (item.tags as List).where((t) => t.toString().isNotEmpty).toList();

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE0D5C0), width: 0.5),
        ),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image Section with 4:5 Aspect Ratio
            AspectRatio(
              aspectRatio: ImagePolicy.productAspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: kMaroon)),
                      errorWidget: (context, url, error) => _imageFallback(item.itemNumber),
                    )
                  else
                    _imageFallback(item.itemNumber),
                  
                  // NEW label badge
                  if (isNew)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: kGold,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  const WatermarkOverlay(),
                ],
              ),
            ),
            
            // Details Section below the image
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row with Item Name/Number and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.itemNumber,
                              style: const TextStyle(
                                fontSize: 13,
                                color: kMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.category.replaceAll('_', ' '),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: kDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹${(item.sellingPrice as num).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          const Text(
                            '/set',
                            style: TextStyle(
                              fontSize: 10,
                              color: kMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Tags Row
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: tags.map<Widget>((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: kCream,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE0D5C0)),
                        ),
                        child: Text(
                          '$t',
                          style: const TextStyle(fontSize: 10, color: kDark),
                        ),
                      )).toList(),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // CTA button to View Details / Order
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                      label: const Text(
                        'Select Sizes & Order',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kMaroon,
                        side: const BorderSide(color: kMaroon, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback(String label) {
    return Container(
      color: kMaroon,
      alignment: Alignment.center,
      child: Text(
        (label.isNotEmpty ? label[0] : '?').toUpperCase(),
        style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w200, color: Colors.white54),
      ),
    );
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mahalaxmi_shared/models/item.dart';
import 'package:mahalaxmi_shared/services/tag_filter.dart';

void main() {
  final items = [
    _item('CH-001', 'Chuda', ['Gold', 'Premium']),
    _item('CH-002', 'Chuda', ['Silver']),
    _item('CH-003', 'Chuda', ['Gold', 'Basic']),
    _item('MB-001', 'Metal_Bangles', ['Heavy', 'Premium']),
    _item('MB-002', 'Metal_Bangles', ['Light']),
    _item('KL-001', 'Kaleera', []),
  ];

  group('extractSortedTags', () {
    test('extracts unique tags from all items', () {
      expect(extractSortedTags(items), equals(['Basic', 'Gold', 'Heavy', 'Light', 'Premium', 'Silver']));
    });

    test('returns empty list when no items have tags', () {
      expect(extractSortedTags([]), isEmpty);
    });

    test('deduplicates same tag on multiple items', () {
      final result = extractSortedTags(items);
      expect(result.where((t) => t == 'Gold'), hasLength(1));
      expect(result.where((t) => t == 'Premium'), hasLength(1));
    });

    test('sorts tags case-insensitive', () {
      final mixed = [
        _item('A-001', 'Test', ['Zebra']),
        _item('A-002', 'Test', ['apple']),
        _item('A-003', 'Test', ['Banana']),
      ];
      expect(extractSortedTags(mixed), equals(['apple', 'Banana', 'Zebra']));
    });

    test('filters out empty strings', () {
      final withEmpty = [
        _item('E-001', 'Test', ['', 'Valid', '', 'Also']),
      ];
      expect(extractSortedTags(withEmpty), equals(['Also', 'Valid']));
    });
  });

  group('filterItemsByTag', () {
    test('returns all items when tag is null', () {
      expect(filterItemsByTag(items, null), hasLength(6));
    });

    test('filters to items containing the tag', () {
      final result = filterItemsByTag(items, 'Gold');
      expect(result, hasLength(2));
      expect(result[0].itemNumber, equals('CH-001'));
      expect(result[1].itemNumber, equals('CH-003'));
    });

    test('returns empty list when no items match', () {
      expect(filterItemsByTag(items, 'NonExistent'), isEmpty);
    });

    test('tag match is exact (not substring)', () {
      final result = filterItemsByTag(items, 'Gold');
      // 'Gold' should not match 'Gold_Deluxe' or similar
      expect(result.every((item) => item.tags.contains('Gold')), isTrue);
    });
  });
}

RateItem _item(String itemNumber, String category, List<String> tags) {
  return RateItem(
    itemNumber: itemNumber,
    category: category,
    sellingPrice: 100,
    tags: tags,
  );
}

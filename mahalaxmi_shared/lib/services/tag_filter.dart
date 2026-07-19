import '../models/item.dart';

List<String> extractSortedTags(List<RateItem> items) {
  final tagSet = <String>{};
  for (final item in items) {
    for (final tag in item.tags) {
      if (tag.isNotEmpty) {
        tagSet.add(tag);
      }
    }
  }
  final result = tagSet.toList();
  result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return result;
}

List<RateItem> filterItemsByTag(List<RateItem> items, String? tag) {
  if (tag == null) return items;
  return items.where((item) => item.tags.contains(tag)).toList();
}
